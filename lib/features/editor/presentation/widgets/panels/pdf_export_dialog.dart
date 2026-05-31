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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5),
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
                color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
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
              color: const Color(0xFF8B5CF6),
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
                          ? const Color(0xFF8B5CF6)
                          : (isDark ? const Color(0xFF1C1829) : const Color(0xFFF3F0FF)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF8B5CF6)
                            : (isDark ? const Color(0xFF2E2845) : const Color(0xFFD4C8F5)),
                      ),
                    ),
                    child: Text(
                      size,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: selected
                            ? Colors.white
                            : (isDark ? const Color(0xFFAA9ECC) : const Color(0xFF7C3AED)),
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
              color: const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _pdfOptionPill(
                'Portrait',
                !_isLandscape,
                Icons.crop_portrait_rounded,
                isDark,
                () => setState(() => _isLandscape = false),
              ),
              const SizedBox(width: 8),
              _pdfOptionPill(
                'Landscape',
                _isLandscape,
                Icons.crop_landscape_rounded,
                isDark,
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
              color: const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _pdfTogglePill(
                'Metadata',
                _inclMetadata,
                isDark,
                () => setState(() => _inclMetadata = !_inclMetadata),
              ),
              const SizedBox(width: 8),
              _pdfTogglePill(
                'Tags',
                _inclTags,
                isDark,
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
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
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
    String label,
    bool selected,
    IconData icon,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF8B5CF6)
              : (isDark ? const Color(0xFF1C1829) : const Color(0xFFF3F0FF)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFF8B5CF6)
                : (isDark ? const Color(0xFF2E2845) : const Color(0xFFD4C8F5)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : (isDark ? const Color(0xFFAA9ECC) : const Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: selected
                    ? Colors.white
                    : (isDark ? const Color(0xFFAA9ECC) : const Color(0xFF7C3AED)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdfTogglePill(
    String label,
    bool active,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF8B5CF6).withOpacity(0.1)
              : (isDark ? const Color(0xFF1C1829) : const Color(0xFFF3F0FF)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? const Color(0xFF8B5CF6)
                : (isDark ? const Color(0xFF2E2845) : const Color(0xFFD4C8F5)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: active
                  ? const Color(0xFF8B5CF6)
                  : (isDark ? const Color(0xFFAA9ECC) : const Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: active
                    ? (isDark ? Colors.white : const Color(0xFF4C1D95))
                    : (isDark ? const Color(0xFFAA9ECC) : const Color(0xFF7C3AED)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
