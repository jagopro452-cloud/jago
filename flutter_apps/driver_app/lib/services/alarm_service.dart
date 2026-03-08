import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Persistent alarm service that generates and loops a WAV siren tone.
/// Uses the Android ALARM audio stream so it plays loud even during DnD.
/// Works fully without any audio asset file — WAV is built in memory at runtime.
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  AudioPlayer? _player;
  bool _playing = false;

  // Build once on first use
  static final Uint8List _alarmWav = _buildAlarmWav();

  bool get isPlaying => _playing;

  /// Start the looping alarm. Safe to call multiple times (idempotent).
  Future<void> startAlarm() async {
    if (_playing) return;
    _playing = true;
    try {
      await _player?.dispose();
      _player = AudioPlayer();

      // Use ALARM usage type so Android routes through alarm volume channel
      // and keeps playing even when screen is off.
      await _player!.setAudioContext(const AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientExclusive,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.duckOthers,
          },
        ),
      ));

      await _player!.setVolume(1.0);
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.play(BytesSource(_alarmWav));
    } catch (_) {
      // Fallback: silently fail — SystemSound bursts in IncomingTripSheet
      // will still run as a secondary alert
      _playing = false;
    }
  }

  /// Stop and release the player. Safe to call even when not playing.
  Future<void> stopAlarm() async {
    _playing = false;
    try {
      await _player?.stop();
      await _player?.dispose();
      _player = null;
    } catch (_) {}
  }

  // ── WAV Generator ──────────────────────────────────────────────────────────
  // Generates an 8-bit unsigned mono PCM WAV in memory.
  // Pattern: 400ms rising-pitch siren (700→1200 Hz) + 250ms silence = 650ms loop.
  // When ReleaseMode.loop is set, this repeats continuously.
  static Uint8List _buildAlarmWav() {
    const sr = 8000; // 8 kHz — small file, works on all Android versions
    const toneMs = 400;
    const silenceMs = 250;
    const totalMs = toneMs + silenceMs;
    final nTone = sr * toneMs ~/ 1000;
    final nTotal = sr * totalMs ~/ 1000;

    final buf = ByteData(44 + nTotal);

    void ws(int off, String s) {
      for (int i = 0; i < s.length; i++) {
        buf.setUint8(off + i, s.codeUnitAt(i));
      }
    }

    // RIFF / WAV header
    ws(0, 'RIFF');
    buf.setUint32(4, 36 + nTotal, Endian.little); // ChunkSize
    ws(8, 'WAVE');
    ws(12, 'fmt ');
    buf.setUint32(16, 16, Endian.little); // Subchunk1Size (PCM = 16)
    buf.setUint16(20, 1, Endian.little);  // AudioFormat = 1 (PCM)
    buf.setUint16(22, 1, Endian.little);  // NumChannels = 1 (Mono)
    buf.setUint32(24, sr, Endian.little); // SampleRate
    buf.setUint32(28, sr, Endian.little); // ByteRate = sr * 1 * 1
    buf.setUint16(32, 1, Endian.little);  // BlockAlign = 1
    buf.setUint16(34, 8, Endian.little);  // BitsPerSample = 8
    ws(36, 'data');
    buf.setUint32(40, nTotal, Endian.little);

    // Audio samples: rising-pitch tone + silence
    for (int i = 0; i < nTotal; i++) {
      if (i >= nTone) {
        buf.setUint8(44 + i, 128); // Unsigned 8-bit silence = 128 (midpoint)
      } else {
        final t = i / sr;
        final progress = i / nTone;
        // Sweep from 700 Hz → 1200 Hz (siren effect)
        final freq = 700.0 + progress * 500.0;
        // Amplitude crescendo from 60% to 100%
        final amplitude = (0.6 + 0.4 * progress) * 110.0;
        final raw = math.sin(2 * math.pi * freq * t) * amplitude + 128.0;
        buf.setUint8(44 + i, raw.clamp(0, 255).toInt());
      }
    }

    return buf.buffer.asUint8List();
  }
}
