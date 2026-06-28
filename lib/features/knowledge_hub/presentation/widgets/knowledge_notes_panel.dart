// Notes companion panel for the Knowledge Hub.
// Uses the same QuillEditor as the main notes editor — no plain TextField.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/models.dart';
import '../../data/models/knowledge_article.dart';

class KnowledgeNotesPanel extends StatefulWidget {
  final List<NoteModel> notes;
  final NoteModel? selectedNote;
  final bool isSaving;
  final VoidCallback onCreateNote;
  final ValueChanged<NoteModel?> onSelectNote;
  final void Function(String title, String body) onNoteChanged;
  final KnowledgeArticle? activeArticle;
  final ValueChanged<String> onOpenSourceUrl;

  const KnowledgeNotesPanel({
    super.key,
    required this.notes,
    required this.selectedNote,
    required this.isSaving,
    required this.onCreateNote,
    required this.onSelectNote,
    required this.onNoteChanged,
    this.activeArticle,
    required this.onOpenSourceUrl,
  });

  @override
  State<KnowledgeNotesPanel> createState() => _KnowledgeNotesPanelState();
}

class _KnowledgeNotesPanelState extends State<KnowledgeNotesPanel> {
  late QuillController _quillCtrl;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _ignoreChanges = false;

  @override
  void initState() {
    super.initState();
    _quillCtrl = _controllerFromNote(widget.selectedNote);
    _quillCtrl.addListener(_onQuillChanged);
  }

  @override
  void didUpdateWidget(KnowledgeNotesPanel old) {
    super.didUpdateWidget(old);
    if (widget.selectedNote?.id != old.selectedNote?.id) {
      _rebuildController();
    }
  }

  @override
  void dispose() {
    _quillCtrl.removeListener(_onQuillChanged);
    _quillCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Controller helpers ───────────────────────────────────────────────────

  QuillController _controllerFromNote(NoteModel? note) {
    if (note == null) return QuillController.basic();
    try {
      final raw = note.content.trim();
      if (raw.startsWith('{') && raw.contains('"ops"')) {
        final Map<String, dynamic> json = jsonDecode(raw);
        final doc = Document.fromJson(json['ops'] as List);
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (_) {}
    // Fallback: treat as plain text
    final doc = Document()..insert(0, note.plainText.isEmpty ? '' : note.plainText);
    return QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void _rebuildController() {
    _ignoreChanges = true;
    _quillCtrl.removeListener(_onQuillChanged);
    _quillCtrl.dispose();
    _quillCtrl = _controllerFromNote(widget.selectedNote);
    _quillCtrl.addListener(_onQuillChanged);
    setState(() {});
    // Re-enable change listener after next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ignoreChanges = false;
    });
  }

  void _onQuillChanged() {
    if (_ignoreChanges) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _save);
  }

  void _save() {
    final note = widget.selectedNote;
    if (note == null) return;
    final ops = _quillCtrl.document.toDelta().toJson();
    final content = jsonEncode({'ops': ops});
    widget.onNoteChanged(note.title, content);
  }

  // ── Article link insertion (as a proper Quill hyperlink) ─────────────────

  void _insertArticleLink() {
    final article = widget.activeArticle;
    if (article == null) return;
    final url = article.url ?? '';
    final title = article.title;

    final doc = _quillCtrl.document;
    final int pos = _quillCtrl.selection.baseOffset.clamp(0, doc.length - 1);

    // Insert a newline before if not at start of line
    _quillCtrl.replaceText(pos, 0, '\n', null);
    final linkPos = pos + 1;

    // Insert the title text with a 'link' attribute (proper Quill hyperlink)
    _quillCtrl.replaceText(linkPos, 0, title, null);
    _quillCtrl.formatText(linkPos, title.length, LinkAttribute(url));

    // Move cursor after the link
    _quillCtrl.updateSelection(
      TextSelection.collapsed(offset: linkPos + title.length),
      ChangeSource.local,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source linked as hyperlink ✓'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    _save();
  }

  void _copyNote() {
    final text = _quillCtrl.document.toPlainText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied ✓'), duration: Duration(seconds: 1)),
    );
  }

  void _showNotePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NotePickerSheet(
        notes: widget.notes,
        selectedId: widget.selectedNote?.id,
        onSelect: (n) {
          Navigator.of(context).pop();
          widget.onSelectNote(n);
        },
        onCreateNew: () {
          Navigator.of(context).pop();
          widget.onCreateNote();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final hasNote = widget.selectedNote != null;

    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        children: [
          // ── Top bar: note title + picker ────────────────────────────────
          _buildTopBar(theme, accent, hasNote),
          Divider(height: 1, color: theme.dividerColor),

          // ── Editor or empty state ────────────────────────────────────────
          Expanded(
            child: hasNote ? _buildQuillEditor(theme) : _buildEmptyState(theme, accent),
          ),

          // ── Toolbar ─────────────────────────────────────────────────────
          if (hasNote) _buildToolbar(theme, accent),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, Color accent, bool hasNote) {
    final note = widget.selectedNote;
    return InkWell(
      onTap: _showNotePicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 18, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasNote
                    ? (note!.title.isEmpty ? 'Untitled note' : note.title)
                    : 'Tap to select a note…',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hasNote ? null : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: hasNote
                  ? (widget.isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : Icon(Icons.check_circle_rounded,
                          size: 14, color: Colors.green.shade400))
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.note_add_rounded, size: 48,
                color: accent.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No note selected',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Select an existing note or create a new one.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _showNotePicker,
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: const Text('Select'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: widget.onCreateNote,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('New Note'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuillEditor(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: QuillEditor.basic(
        controller: _quillCtrl,
        focusNode: _focusNode,
        config: const QuillEditorConfig(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
          placeholder: 'Write your notes here… Tip: tap "Link Article" to add a source.',
          autoFocus: false,
          scrollPhysics: ClampingScrollPhysics(),
        ),
      ),
    );

  }

  Widget _buildToolbar(ThemeData theme, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quill format toolbar
          QuillSimpleToolbar(
            controller: _quillCtrl,
            config: QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showAlignmentButtons: false,
              showBackgroundColorButton: false,
              showColorButton: false,
              showSubscript: false,
              showSuperscript: false,
              showClearFormat: false,
              showSmallButton: false,
              showInlineCode: true,
              showCodeBlock: false,
              showListNumbers: true,
              showListBullets: true,
              showListCheck: false,
              showQuote: true,
              showIndent: false,
              showLink: true,
              showSearchButton: false,
              showUndo: false,
              showRedo: false,
              showHeaderStyle: true,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: false,
              showDividers: true,
              toolbarIconAlignment: WrapAlignment.start,
              buttonOptions: QuillSimpleToolbarButtonOptions(
                base: QuillToolbarBaseButtonOptions(
                  iconSize: 16,
                  iconButtonFactor: 1.2,
                ),
              ),
            ),
          ),
          // Extra actions row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Row(
              children: [
                if (widget.activeArticle != null)
                  _actionBtn(theme, accent,
                      icon: Icons.add_link_rounded,
                      label: 'Link Article',
                      onTap: _insertArticleLink),
                _actionBtn(theme, accent,
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: _copyNote),
                _actionBtn(theme, accent,
                    icon: Icons.open_in_new_rounded,
                    label: 'Full Editor',
                    onTap: () => context.push('/notes/edit/${widget.selectedNote!.id}')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(ThemeData theme, Color accent, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Note picker bottom sheet ────────────────────────────────────────────────

class _NotePickerSheet extends StatelessWidget {
  final List<NoteModel> notes;
  final String? selectedId;
  final ValueChanged<NoteModel?> onSelect;
  final VoidCallback onCreateNew;

  const _NotePickerSheet({
    required this.notes,
    required this.selectedId,
    required this.onSelect,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 14, 8),
            child: Row(
              children: [
                Text('Select Note',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onCreateNew,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('New', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.note_outlined,
                            size: 40,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 10),
                        const Text('No notes yet'),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: notes.length,
                    itemBuilder: (_, i) {
                      final note = notes[i];
                      final isSelected = note.id == selectedId;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: accent
                              .withValues(alpha: isSelected ? 0.2 : 0.07),
                          child: Icon(
                            isSelected
                                ? Icons.check_rounded
                                : Icons.note_rounded,
                            size: 16,
                            color: accent,
                          ),
                        ),
                        title: Text(
                          note.title.isEmpty ? 'Untitled' : note.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: note.plainText.isNotEmpty
                            ? Text(
                                note.plainText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              )
                            : null,
                        selected: isSelected,
                        selectedTileColor:
                            accent.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        onTap: () => onSelect(note),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
