import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import '../../../../../models/models.dart';
import '../../../../../core/services/pdf_export_service.dart';
import '../../../../folders/data/folders_repository.dart';

class PdfExportDialog extends ConsumerStatefulWidget {
  final NoteModel note;

  const PdfExportDialog({
    super.key,
    required this.note,
  });

  static Future<void> show(BuildContext context, NoteModel note) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PdfExportDialog(note: note),
    );
  }

  @override
  ConsumerState<PdfExportDialog> createState() => _PdfExportDialogState();
}

class _PdfExportDialogState extends ConsumerState<PdfExportDialog> {
  String _selectedSize = 'A4';
  bool _isLandscape = false;
  bool _inclMetadata = true;
  bool _inclTags = true;

  final Map<String, PdfPageFormat> _sizeMap = {
    'A4': PdfPageFormat.a4,
    'Letter': PdfPageFormat.letter,
    'Legal': PdfPageFormat.legal,
    'A3': PdfPageFormat.a3,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Export PDF',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'Paper Size',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _sizeMap.keys.map((size) {
              final selected = _selectedSize == size;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSize = size),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                      ),
                    ),
                    child: Text(
                      size,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Text(
            'Orientation',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _pdfOptionPill(
                context,
                'Portrait',
                !_isLandscape,
                Icons.crop_portrait_rounded,
                () => setState(() => _isLandscape = false),
              ),
              const SizedBox(width: 8),
              _pdfOptionPill(
                context,
                'Landscape',
                _isLandscape,
                Icons.crop_landscape_rounded,
                () => setState(() => _isLandscape = true),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Include',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _pdfTogglePill(
                context,
                'Metadata',
                _inclMetadata,
                () => setState(() => _inclMetadata = !_inclMetadata),
              ),
              const SizedBox(width: 8),
              _pdfTogglePill(
                context,
                'Tags',
                _inclTags,
                () => setState(() => _inclTags = !_inclTags),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                var fmt = _sizeMap[_selectedSize] ?? PdfPageFormat.a4;
                if (_isLandscape) fmt = fmt.landscape;

                final folders = ref.read(foldersProvider);
                final folder = folders.cast<FolderModel?>().firstWhere(
                      (f) => f?.id == widget.note.folderId,
                      orElse: () => null,
                    );

                try {
                  await PdfExportService().printOrExportNote(
                    widget.note,
                    folderName: folder?.name,
                    pageFormat: fmt,
                    includeMetadata: _inclMetadata,
                    includeTags: _inclTags,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('PDF Error: $e'),
                        backgroundColor: Colors.red.shade700,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Generate PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pdfOptionPill(
    BuildContext context,
    String label,
    bool selected,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdfTogglePill(
    BuildContext context,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
