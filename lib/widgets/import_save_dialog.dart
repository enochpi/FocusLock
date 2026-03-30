import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/save_data_service.dart';

class ImportSaveDialog extends StatefulWidget {
  const ImportSaveDialog({super.key});

  @override
  State<ImportSaveDialog> createState() => _ImportSaveDialogState();
}

class _ImportSaveDialogState extends State<ImportSaveDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!;
      setState(() => _error = null);
    }
  }

  Future<void> _import() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Paste your save data first.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    final success = await SaveDataService().importSave(text, context);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save data imported! Restart the app to see changes.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _error = 'Invalid save data. Make sure you pasted the full JSON.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Import Save Data', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Paste your exported save JSON below.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 6,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: '{ "version": 1, ... }',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              errorText: _error,
              errorStyle: const TextStyle(color: Colors.redAccent),
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pasteFromClipboard,
            icon: const Icon(Icons.paste, color: Color(0xFF00d4ff)),
            label: const Text('Paste from clipboard',
                style: TextStyle(color: Color(0xFF00d4ff))),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _import,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00d4ff)),
          child: _isLoading
              ? const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Text('Import', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}