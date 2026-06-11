import 'package:flutter/material.dart';
import '../../../../../../core/services/export_import_service.dart';
import '../../../../notes/data/models/note_model.dart';

class ShareNoteBottomSheet extends StatefulWidget {
  final NoteModel note;
  final String? folderName;

  const ShareNoteBottomSheet({
    super.key,
    required this.note,
    this.folderName,
  });

  @override
  State<ShareNoteBottomSheet> createState() => _ShareNoteBottomSheetState();
}

class _ShareNoteBottomSheetState extends State<ShareNoteBottomSheet> {
  bool _showPdfOptions = false;
  bool _includeImages = true;
  bool _includePdfs = true;
  bool _includeAudio = true;
  bool _isProcessing = false;

  void _shareAsGentleNote() async {
    setState(() => _isProcessing = true);
    try {
      await ExportImportService().shareNote(widget.note, folderName: widget.folderName, asMarkdown: false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _shareAsMarkdown() async {
    setState(() => _isProcessing = true);
    try {
      await ExportImportService().shareNote(widget.note, folderName: widget.folderName, asMarkdown: true);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _shareAsPdf() async {
    setState(() => _isProcessing = true);
    try {
      await ExportImportService().shareNoteAsPdf(
        widget.note,
        includeImages: _includeImages,
        includePdfs: _includePdfs,
        includeAudio: _includeAudio,
      );
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      debugPrint('Export PDF Error: $e\n$st');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export PDF failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isProcessing) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Share "${widget.note.title}"', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          ListTile(
            leading: const Icon(Icons.archive_outlined, color: Colors.blue),
            title: const Text('Share as GentleNote (.gentlenote)'),
            subtitle: const Text('Includes all media, layout, and settings. Best for sharing with other Gentle Notes users.'),
            onTap: _shareAsGentleNote,
          ),
          
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
            title: const Text('Share as PDF Document'),
            subtitle: const Text('Export a standard PDF with layout.'),
            onTap: () {
              setState(() {
                _showPdfOptions = !_showPdfOptions;
              });
            },
            trailing: Icon(_showPdfOptions ? Icons.expand_less : Icons.expand_more),
          ),
          
          if (_showPdfOptions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Include Images'),
                      value: _includeImages,
                      onChanged: (val) => setState(() => _includeImages = val ?? true),
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text('Include Embedded PDFs'),
                      value: _includePdfs,
                      onChanged: (val) => setState(() => _includePdfs = val ?? true),
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text('Include Voice Notes (Placeholder)'),
                      value: _includeAudio,
                      onChanged: (val) => setState(() => _includeAudio = val ?? true),
                      dense: true,
                    ),
                    ElevatedButton.icon(
                      onPressed: _shareAsPdf,
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Export PDF'),
                    ),
                  ],
                ),
              ),
            ),
            
          ListTile(
            leading: const Icon(Icons.text_snippet_outlined, color: Colors.grey),
            title: const Text('Share as Markdown (.md)'),
            subtitle: const Text('Plain text formatting. Best for external editors.'),
            onTap: _shareAsMarkdown,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
