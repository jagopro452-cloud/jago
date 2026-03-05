import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'booking_screen.dart';

class _LangOption {
  final String name;
  final String localeId;
  final String ttsLang;
  final String flag;
  final String welcomeText;
  const _LangOption(this.name, this.localeId, this.ttsLang, this.flag, this.welcomeText);
}

const _supportedLangs = [
  _LangOption('English',   'en_IN', 'en-IN', '🇮🇳', 'Say: Book a bike from JNTU to Hitech City'),
  _LangOption('Telugu',   'te_IN', 'te-IN', '🇮🇳', 'చెప్పండి: బైక్ JNTU నుండి Hitech City కి'),
  _LangOption('Hindi',    'hi_IN', 'hi-IN', '🇮🇳', 'बोलें: JNTU से Hitech City के लिए बाइक'),
  _LangOption('Tamil',    'ta_IN', 'ta-IN', '🇮🇳', 'சொல்லுங்கள்: JNTU இலிருந்து Hitech City க்கு'),
  _LangOption('Kannada',  'kn_IN', 'kn-IN', '🇮🇳', 'ಹೇಳಿ: JNTU ನಿಂದ Hitech City ವರೆಗೆ'),
  _LangOption('Malayalam','ml_IN', 'ml-IN', '🇮🇳', 'പറയൂ: JNTU മുതൽ Hitech City വരെ'),
  _LangOption('Marathi',  'mr_IN', 'mr-IN', '🇮🇳', 'सांगा: JNTU वरून Hitech City ला'),
  _LangOption('Bengali',  'bn_IN', 'bn-IN', '🇮🇳', 'বলুন: JNTU থেকে Hitech City পর্যন্ত'),
  _LangOption('Urdu',     'ur_IN', 'ur-IN', '🇮🇳', 'کہیں: JNTU سے Hitech City تک'),
];

class VoiceBookingScreen extends StatefulWidget {
  const VoiceBookingScreen({super.key});
  @override
  State<VoiceBookingScreen> createState() => _VoiceBookingScreenState();
}

class _VoiceBookingScreenState extends State<VoiceBookingScreen>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _speechAvailable = false;
  bool _loading = false;
  bool _awaitingConfirmation = false;
  String _recognizedText = '';
  String _statusText = 'Tap the mic to start';
  Map<String, dynamic>? _parsedIntent;

  // All fares returned from server, plus the selected index
  List<Map<String, dynamic>> _allFares = [];
  int _selectedFareIndex = 0;
  double _distanceKm = 0;

  _LangOption _selectedLang = _supportedLangs[0];
  List<LocaleName> _availableLocales = [];

  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;

  static const Color _bg      = Color(0xFF060D1E);
  static const Color _surface = Color(0xFF0D1B3E);
  static const Color _blue    = Color(0xFF1B4DCC);
  static const Color _yellow  = Color(0xFFFBBC04);
  static const Color _primary  = Color(0xFF1E6DE5);
  static const Color _green   = Color(0xFF16A34A);

  // ─── Life-cycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _initSpeech();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  // ─── Speech init ─────────────────────────────────────────────────────────

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (e) => setState(() => _statusText = 'Mic error: ${e.errorMsg}'),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _isListening = false);
          if (_recognizedText.isNotEmpty) {
            if (_awaitingConfirmation) {
              _processVoiceConfirmation(_recognizedText);
            } else {
              _parseIntent(_recognizedText);
            }
          }
        }
      },
    );
    if (available) {
      final locales = await _speech.locales();
      if (mounted) {
        setState(() {
          _speechAvailable = true;
          _availableLocales = locales;
        });
        _autoDetectLanguage();
      }
    } else {
      if (mounted) setState(() => _speechAvailable = false);
    }
    _speakWelcome();
  }

  // Auto-detect language from device locale
  void _autoDetectLanguage() {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final langCode = deviceLocale.languageCode;
    final match = _supportedLangs.where((l) => l.localeId.startsWith(langCode)).toList();
    if (match.isNotEmpty) setState(() => _selectedLang = match.first);
  }

  // Heuristic language detection from the recognized text's Unicode script
  _LangOption _detectLangFromText(String text) {
    // Telugu: U+0C00–U+0C7F
    if (text.runes.any((r) => r >= 0x0C00 && r <= 0x0C7F)) {
      return _supportedLangs.firstWhere((l) => l.localeId.startsWith('te'), orElse: () => _selectedLang);
    }
    // Devanagari (Hindi/Marathi): U+0900–U+097F
    if (text.runes.any((r) => r >= 0x0900 && r <= 0x097F)) {
      return _supportedLangs.firstWhere((l) => l.localeId.startsWith('hi'), orElse: () => _selectedLang);
    }
    // Tamil: U+0B80–U+0BFF
    if (text.runes.any((r) => r >= 0x0B80 && r <= 0x0BFF)) {
      return _supportedLangs.firstWhere((l) => l.localeId.startsWith('ta'), orElse: () => _selectedLang);
    }
    // Kannada: U+0C80–U+0CFF
    if (text.runes.any((r) => r >= 0x0C80 && r <= 0x0CFF)) {
      return _supportedLangs.firstWhere((l) => l.localeId.startsWith('kn'), orElse: () => _selectedLang);
    }
    // Malayalam: U+0D00–U+0D7F
    if (text.runes.any((r) => r >= 0x0D00 && r <= 0x0D7F)) {
      return _supportedLangs.firstWhere((l) => l.localeId.startsWith('ml'), orElse: () => _selectedLang);
    }
    // Bengali: U+0980–U+09FF
    if (text.runes.any((r) => r >= 0x0980 && r <= 0x09FF)) {
      return _supportedLangs.firstWhere((l) => l.localeId.startsWith('bn'), orElse: () => _selectedLang);
    }
    // Arabic (Urdu): U+0600–U+06FF
    if (text.runes.any((r) => r >= 0x0600 && r <= 0x06FF)) {
      return _supportedLangs.firstWhere((l) => l.localeId.startsWith('ur'), orElse: () => _selectedLang);
    }
    return _selectedLang;
  }

  // ─── TTS ─────────────────────────────────────────────────────────────────

  Future<void> _speak(String text, {_LangOption? lang}) async {
    final l = lang ?? _selectedLang;
    await _tts.setLanguage(l.ttsLang);
    await _tts.setSpeechRate(0.88);
    await _tts.speak(text);
  }

  Future<void> _speakWelcome() async {
    await Future.delayed(const Duration(milliseconds: 800));
    await _speak(_selectedLang.welcomeText);
  }

  // ─── Language picker ─────────────────────────────────────────────────────

  Future<void> _selectLanguage() async {
    final chosen = await showModalBottomSheet<_LangOption>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Choose Language',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ..._supportedLangs.map((lang) {
            final available = _availableLocales.any(
                (l) => l.localeId.startsWith(lang.localeId.substring(0, 2)));
            return ListTile(
              leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
              title: Text(lang.name,
                  style: TextStyle(
                      color: available ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.w600)),
              trailing: available
                  ? lang == _selectedLang
                      ? const Icon(Icons.check_circle, color: _primary)
                      : null
                  : const Text('Not supported',
                      style: TextStyle(color: Colors.white24, fontSize: 10)),
              onTap: available ? () => Navigator.pop(context, lang) : null,
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _selectedLang = chosen);
      _speakWelcome();
    }
  }

  // ─── Listening (first cycle — intent capture) ────────────────────────────

  Future<void> _startListening() async {
    if (!_speechAvailable) { _showSnack('Microphone not available'); return; }
    await _tts.stop();
    setState(() {
      _isListening = true;
      _awaitingConfirmation = false;
      _recognizedText = '';
      _parsedIntent = null;
      _allFares = [];
      _statusText = 'Listening… speak now';
    });
    final localeAvailable = _availableLocales
        .any((l) => l.localeId.startsWith(_selectedLang.localeId.substring(0, 2)));
    final localeToUse = localeAvailable ? _selectedLang.localeId : 'en_IN';
    await _speech.listen(
      onResult: (r) {
        if (mounted) setState(() {
          _recognizedText = r.recognizedWords;
          _statusText = 'Heard: "$_recognizedText"';
        });
      },
      localeId: localeToUse,
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (_recognizedText.isNotEmpty) {
      if (_awaitingConfirmation) {
        _processVoiceConfirmation(_recognizedText);
      } else {
        _parseIntent(_recognizedText);
      }
    }
  }

  // ─── Listening (second cycle — confirmation) ─────────────────────────────

  Future<void> _listenForConfirmation() async {
    if (!_speechAvailable || !mounted) return;
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isListening = true;
      _awaitingConfirmation = true;
      _recognizedText = '';
      _statusText = 'Listening for confirmation…';
    });
    final localeAvailable = _availableLocales
        .any((l) => l.localeId.startsWith(_selectedLang.localeId.substring(0, 2)));
    final localeToUse = localeAvailable ? _selectedLang.localeId : 'en_IN';
    await _speech.listen(
      onResult: (r) {
        if (mounted) setState(() {
          _recognizedText = r.recognizedWords;
          _statusText = 'Heard: "$_recognizedText"';
        });
      },
      localeId: localeToUse,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  // ─── Process voice confirmation ───────────────────────────────────────────

  void _processVoiceConfirmation(String text) {
    setState(() {
      _isListening = false;
      _awaitingConfirmation = false;
    });
    final lower = text.toLowerCase().trim();

    // Check for vehicle switch first (e.g. "auto", "car", "bike")
    final vehicleSwitched = _tryVehicleSwitch(lower);
    if (vehicleSwitched) return;

    // Confirmation words in all supported languages
    const confirmWords = [
      'yes', 'confirm', 'book', 'okay', 'ok', 'sure', 'proceed',
      'go', 'accept', 'done', 'correct', 'right', 'ha', 'haan',
      // Telugu
      'అవును', 'బుక్',
      // Hindi
      'हाँ', 'बुक', 'हां',
      // Tamil
      'ஆம்', 'சரி',
      // Kannada
      'ಹೌದು', 'ಸರಿ',
      // Malayalam
      'ശരി', 'അതെ',
      // Bengali
      'হ্যাঁ', 'ঠিক',
      // Marathi
      'हो', 'बुक',
    ];

    // Cancel words
    const cancelWords = ['no', 'cancel', 'stop', 'nahi', 'nope', 'back',
      'illa', 'vendam', 'வேண்டாம்', 'వద్దు', 'नहीं'];

    final isConfirm = confirmWords.any((w) => lower.contains(w));
    final isCancel = cancelWords.any((w) => lower.contains(w));

    if (isCancel) {
      setState(() => _statusText = 'Booking cancelled. Tap mic to try again.');
      _speak('Booking cancelled.');
      return;
    }

    if (isConfirm) {
      _speak('Perfect! Booking your ride now.').then((_) => _confirmBooking());
      return;
    }

    // Didn't understand
    setState(() => _statusText = 'Say "yes" to confirm or "no" to cancel.');
    _speak('Say yes to confirm or no to cancel.').then((_) => _listenForConfirmation());
  }

  // Try to switch vehicle by voice
  bool _tryVehicleSwitch(String lower) {
    if (_allFares.isEmpty) return false;
    const vehicleMap = {
      'bike': ['bike', 'bicycle', 'motor'],
      'auto': ['auto', 'autorickshaw', 'rickshaw', 'temo'],
      'car': ['car', 'cab', 'sedan'],
      'suv': ['suv', 'innova', 'xylo'],
    };
    for (final entry in vehicleMap.entries) {
      if (entry.value.any((k) => lower.contains(k))) {
        final idx = _allFares.indexWhere((f) {
          final name = (f['vehicleCategoryName'] ?? f['name'] ?? '').toString().toLowerCase();
          return name.contains(entry.key);
        });
        if (idx >= 0 && idx != _selectedFareIndex) {
          setState(() {
            _selectedFareIndex = idx;
            _statusText = 'Switched to ${_allFares[idx]['vehicleCategoryName'] ?? 'vehicle'}. Say yes to confirm.';
          });
          final name = _allFares[idx]['vehicleCategoryName'] ?? 'vehicle';
          final fare = (_allFares[idx]['estimatedFare'] ?? 0).toStringAsFixed(0);
          _speak('Switched to $name for ₹$fare. Say yes to confirm or no to cancel.')
              .then((_) => _listenForConfirmation());
          return true;
        }
      }
    }
    return false;
  }

  // ─── Parse intent from server ─────────────────────────────────────────────

  Future<void> _parseIntent(String text) async {
    // Detect language from script of recognized text and update TTS lang
    final detectedLang = _detectLangFromText(text);
    if (detectedLang != _selectedLang && mounted) {
      setState(() => _selectedLang = detectedLang);
    }

    setState(() {
      _loading = true;
      _statusText = 'Understanding your request…';
    });
    try {
      final headers = await AuthService.getHeaders();
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/voice-booking/parse'),
        headers: headers,
        body: jsonEncode({'text': text}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _parsedIntent = data);
        if (data['pickup'] != null && data['destination'] != null) {
          await _getAllFares(data);
        } else {
          setState(() => _statusText = 'Could not understand. Try: "Bike from JNTU to Hitech City"');
          await _speak('Sorry, I could not understand. Please say the pickup and destination clearly.');
        }
      }
    } catch (_) {
      setState(() => _statusText = 'Error parsing. Try again.');
    }
    setState(() => _loading = false);
  }

  // ─── Get ALL vehicle fares ────────────────────────────────────────────────

  Future<void> _getAllFares(Map<String, dynamic> intent) async {
    if (intent['pickupLat'] == null || intent['destLat'] == null) {
      setState(() => _statusText = 'Could not find location on map. Try a more specific address.');
      await _speak('Sorry, I could not find that location. Please try again with a more specific address.');
      return;
    }
    setState(() => _statusText = 'Getting vehicle fares…');
    try {
      final headers = await AuthService.getHeaders();
      // Do NOT send vehicleCategoryId so server returns ALL vehicle options
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/customer/estimate-fare'),
        headers: headers,
        body: jsonEncode({
          'pickupLat': intent['pickupLat'],
          'pickupLng': intent['pickupLng'],
          'destinationLat': intent['destLat'],
          'destinationLng': intent['destLng'],
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final fares = (data['fares'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _distanceKm = (data['distanceKm'] as num?)?.toDouble() ?? 0;

        // Filter out parcel/cargo for voice — keep passenger vehicles only
        final rideVehicles = fares.where((f) {
          final name = (f['vehicleCategoryName'] ?? f['name'] ?? '').toString().toLowerCase();
          return !name.contains('parcel') && !name.contains('cargo') && !name.contains('delivery');
        }).toList();

        if (rideVehicles.isEmpty) {
          setState(() => _statusText = 'No vehicles available right now.');
          await _speak('Sorry, no vehicles are available right now. Please try again later.');
          return;
        }

        // Pre-select the vehicle that was mentioned in the voice command (if any)
        int preferredIndex = 0;
        final intentVehicleId = intent['vehicleCategoryId']?.toString();
        if (intentVehicleId != null) {
          final idx = rideVehicles.indexWhere((f) =>
            f['vehicleCategoryId']?.toString() == intentVehicleId ||
            f['id']?.toString() == intentVehicleId);
          if (idx >= 0) preferredIndex = idx;
        }

        setState(() {
          _allFares = rideVehicles;
          _selectedFareIndex = preferredIndex;
          _statusText = 'Ready! Tap "Book Now" or say YES to confirm.';
        });

        await _announceAllFaresAndConfirm(intent);
      }
    } catch (_) {
      setState(() => _statusText = 'Error fetching fares. Try again.');
    }
  }

  // ─── TTS: Announce all fares then start confirmation listener ────────────

  Future<void> _announceAllFaresAndConfirm(Map<String, dynamic> intent) async {
    if (_allFares.isEmpty || !mounted) return;

    final pickup = intent['pickup'] ?? 'your pickup';
    final dest = intent['destination'] ?? 'your destination';
    final dist = _distanceKm > 0 ? '${_distanceKm.toStringAsFixed(1)} kilometres' : '';

    // Build TTS string listing all vehicles
    final StringBuffer sb = StringBuffer();
    sb.write('I found ${_allFares.length} vehicle option${_allFares.length > 1 ? "s" : ""} '
        'from $pickup to $dest');
    if (dist.isNotEmpty) sb.write(', $dist away');
    sb.write('. ');

    for (int i = 0; i < _allFares.length; i++) {
      final f = _allFares[i];
      final name = f['vehicleCategoryName'] ?? f['name'] ?? 'Vehicle';
      final fare = (f['estimatedFare'] as num?)?.toStringAsFixed(0) ?? '?';
      if (i == _allFares.length - 1 && _allFares.length > 1) sb.write('and ');
      sb.write('$name ₹$fare');
      if (i < _allFares.length - 1) sb.write(', ');
    }
    sb.write('. ');

    // Tell user which is selected
    final selectedFare = _allFares[_selectedFareIndex];
    final selectedName = selectedFare['vehicleCategoryName'] ?? selectedFare['name'] ?? 'Bike';
    sb.write('$selectedName is selected. ');
    sb.write('Say yes to confirm, or say the vehicle name to switch. Say no to cancel.');

    final ttsMsg = sb.toString();
    setState(() => _statusText = '🔊 $ttsMsg');

    // Set up a completion handler so we start listening right after TTS finishes
    _tts.setCompletionHandler(() {
      if (mounted && !_isListening && !_loading) {
        _listenForConfirmation();
      }
    });

    await _speak(ttsMsg);
  }

  // ─── Confirm booking ──────────────────────────────────────────────────────

  Future<void> _confirmBooking() async {
    if (_parsedIntent == null || _allFares.isEmpty) return;
    setState(() => _loading = true);
    try {
      final fare = _allFares[_selectedFareIndex];
      final vcId = fare['vehicleCategoryId']?.toString() ?? fare['id']?.toString()
          ?? _parsedIntent!['vehicleCategoryId']?.toString();
      final headers = await AuthService.getHeaders();
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/app/customer/book-ride'),
        headers: headers,
        body: jsonEncode({
          'pickupLat': _parsedIntent!['pickupLat'],
          'pickupLng': _parsedIntent!['pickupLng'],
          'destinationLat': _parsedIntent!['destLat'],
          'destinationLng': _parsedIntent!['destLng'],
          'pickupAddress': _parsedIntent!['pickup'],
          'destinationAddress': _parsedIntent!['destination'],
          if (vcId != null && vcId.isNotEmpty) 'vehicleCategoryId': vcId,
          'paymentMethod': 'cash',
          'tripType': 'normal',
        }),
      );
      if (res.statusCode == 200) {
        await _speak('Your ride is booked! A driver is being assigned. Have a safe trip!');
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final err = jsonDecode(res.body);
        final msg = err['message'] ?? 'Booking failed';
        _showSnack(msg);
        await _speak('Booking failed. $msg Please try again.');
      }
    } catch (_) {
      _showSnack('Connection error');
      await _speak('Connection error. Please check your internet and try again.');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: Colors.white,
        title: const Text('Voice Booking',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 12),

          // Title + language selector
          Text('JAGO Voice Assistant',
              style: TextStyle(color: _yellow, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_selectedLang.welcomeText,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),

          GestureDetector(
            onTap: _selectLanguage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _primary.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_selectedLang.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(_selectedLang.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(width: 6),
                const Icon(Icons.expand_more, color: Colors.white54, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          // Mic button
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final micColor = _awaitingConfirmation
                    ? Color.lerp(Colors.green.shade700, Colors.green.shade400, _pulseCtrl.value)!
                    : _isListening
                        ? Color.lerp(Colors.red.shade700, Colors.red.shade400, _pulseCtrl.value)!
                        : _blue;
                return Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: micColor,
                    boxShadow: [
                      BoxShadow(
                        color: micColor.withOpacity(_isListening ? 0.4 + 0.3 * _pulseCtrl.value : 0.3),
                        blurRadius: _isListening ? 30 + 20 * _pulseCtrl.value : 20,
                        spreadRadius: _isListening ? 5 + 5 * _pulseCtrl.value : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white, size: 56,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _awaitingConfirmation
                ? 'Say YES to confirm or NO to cancel'
                : _isListening ? 'Tap to stop' : 'Tap to speak',
            style: TextStyle(
              color: _awaitingConfirmation ? Colors.green.shade300 : Colors.white60,
              fontSize: 13, fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),

          // Status card
          _infoCard(
            icon: Icons.info_outline,
            iconColor: _yellow,
            label: _awaitingConfirmation ? 'Awaiting Confirmation' : 'Status',
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),

          // Recognized text
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 14),
            _infoCard(
              icon: Icons.record_voice_over,
              iconColor: _blue,
              label: 'You said:',
              child: Text('"$_recognizedText"',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic)),
            ),
          ],

          // Parsed intent
          if (_parsedIntent != null) ...[
            const SizedBox(height: 14),
            _infoCard(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              label: 'Understood:',
              child: Column(children: [
                _intentRow(Icons.my_location, 'From', _parsedIntent!['pickup'] ?? '—'),
                _intentRow(Icons.location_on, 'To', _parsedIntent!['destination'] ?? '—'),
              ]),
            ),
          ],

          // All fares grid
          if (_allFares.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(children: [
              Container(width: 3, height: 14,
                  decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Choose Vehicle',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            ..._allFares.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value;
              final isSelected = i == _selectedFareIndex;
              final name = f['vehicleCategoryName'] ?? f['name'] ?? 'Vehicle';
              final fareVal = (f['estimatedFare'] as num?)?.toStringAsFixed(0) ?? '?';
              final time = f['estimatedTime']?.toString() ?? '~5 min';
              return GestureDetector(
                onTap: () => setState(() => _selectedFareIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _primary.withOpacity(0.1) : _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isSelected ? _primary : Colors.white12,
                        width: isSelected ? 2 : 1),
                    boxShadow: isSelected
                        ? [BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: isSelected ? _primary.withOpacity(0.15) : Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_iconForVehicle(name),
                          color: isSelected ? _primary : Colors.white54, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name,
                          style: TextStyle(
                              color: isSelected ? _primary : Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(time, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ])),
                    Text('₹$fareVal',
                        style: TextStyle(
                            color: isSelected ? _primary : Colors.white,
                            fontSize: 22, fontWeight: FontWeight.w900)),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 22, height: 22,
                        decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                      ),
                    ] else
                      const SizedBox(width: 30),
                  ]),
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            // Action row
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _startListening,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : () {
                    _speak('Booking now.').then((_) => _confirmBooking());
                  },
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    _awaitingConfirmation ? 'CONFIRM BOOKING' : 'BOOK NOW',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _awaitingConfirmation ? Colors.green.shade600 : _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ]),

            if (_awaitingConfirmation) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade900.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade700.withOpacity(0.5)),
                ),
                child: Row(children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade400,
                        boxShadow: [BoxShadow(
                          color: Colors.green.withOpacity(0.5 + _pulseCtrl.value * 0.3),
                          blurRadius: 6 + _pulseCtrl.value * 4,
                        )],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text(
                    'Listening for voice confirmation…',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  )),
                ]),
              ),
            ],
          ],

          const SizedBox(height: 32),
          Text(
            'Voice commands: "yes" · "confirm" · "book" · "auto" · "car" · "bike"',
            style: const TextStyle(color: Colors.white24, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Optimised for elderly and visually impaired users',
            style: TextStyle(color: Colors.white24, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  // ─── Helper widgets ───────────────────────────────────────────────────────

  static IconData _iconForVehicle(String name) {
    final n = name.toLowerCase();
    if (n.contains('bike')) return Icons.electric_bike;
    if (n.contains('auto') || n.contains('temo')) return Icons.electric_rickshaw;
    if (n.contains('suv')) return Icons.directions_car_filled;
    if (n.contains('car')) return Icons.directions_car;
    return Icons.directions_car;
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 15),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }

  Widget _intentRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Expanded(child: Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
