import 'package:flutter/material.dart';
import '../../services/trip_service.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  List<dynamic> _places = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _places = await TripService.getSavedPlaces();
    if (mounted) setState(() => _loading = false);
  }

  void _addPlace() {
    final addrCtrl = TextEditingController();
    String label = 'Home';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Saved Place'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: label,
              items: ['Home', 'Work', 'Other'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setS(() => label = v!),
              decoration: const InputDecoration(labelText: 'Label', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addrCtrl,
              decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder(), hintText: 'Enter full address'),
              maxLines: 2,
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                if (addrCtrl.text.isEmpty) return;
                await TripService.addSavedPlace(label: label, address: addrCtrl.text, lat: 0, lng: 0);
                _load();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Saved Places', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B0B0B))),
        actions: [IconButton(icon: const Icon(Icons.add, color: Color(0xFF2563EB)), onPressed: _addPlace)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _places.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.bookmark_outline, size: 64, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 16),
                  const Text('No saved places', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addPlace,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Place'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _places.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final p = _places[i];
                    final label = p['label'] ?? '';
                    final icon = label == 'Home' ? Icons.home : label == 'Work' ? Icons.work : Icons.bookmark;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Row(children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF2563EB), size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B0B0B))),
                          Text(p['address'] ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ])),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                          onPressed: () async {
                            await TripService.deleteSavedPlace(p['id']?.toString() ?? '');
                            _load();
                          },
                        ),
                      ]),
                    );
                  },
                ),
    );
  }
}
