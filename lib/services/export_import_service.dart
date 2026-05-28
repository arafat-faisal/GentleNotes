import 'dart:convert';
import 'dart:io';
import '../core/utils/quill_markdown_converter.dart';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../data/local/local_storage.dart';
import 'package:uuid/uuid.dart';

class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  factory ExportImportService() => _instance;
  ExportImportService._internal();

  final LocalStorage _storage = LocalStorage();

  // --- EXPORT TO STRING (JSON) ---

  String exportNoteAsJson(NoteModel note) {
    final payload = {
      'appName': 'Gentle Notes',
      'exportVersion': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'exportType': 'note',
      'data': note.toMap(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String exportFolderAsJson(FolderModel folder, List<NoteModel> notes) {
    final payload = {
      'appName': 'Gentle Notes',
      'exportVersion': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'exportType': 'folder',
      'folder': folder.toMap(),
      'data': notes.map((n) => n.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String exportTemplateAsJson(NoteTemplateModel template) {
    final payload = {
      'appName': 'Gentle Notes',
      'exportVersion': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'exportType': 'template',
      'data': template.toMap(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String exportBackupAsJson() {
    final folders = _storage.getFolders();
    final notes = _storage.getNotes();
    final templates = _storage.getTemplates().where((t) => !t.isBuiltIn).toList();

    final payload = {
      'appName': 'Gentle Notes',
      'exportVersion': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'exportType': 'backup',
      'folders': folders.map((f) => f.toMap()).toList(),
      'notes': notes.map((n) => n.toMap()).toList(),
      'templates': templates.map((t) => t.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  // --- EXPORT TO MARKDOWN ---

  String exportNoteAsMarkdown(NoteModel note, {String? folderName}) {
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('title: ${note.title}');
    buffer.writeln('type: ${note.noteType.name}');
    buffer.writeln('tags: ${note.tags.join(', ')}');
    if (folderName != null) {
      buffer.writeln('folder: $folderName');
    }
    buffer.writeln('created: ${note.createdAt.toIso8601String()}');
    buffer.writeln('updated: ${note.updatedAt.toIso8601String()}');
    buffer.writeln('isPinned: ${note.isPinned}');
    buffer.writeln('isFavorite: ${note.isFavorite}');
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln(QuillMarkdownConverter.deltaToMarkdown(note.content));
    return buffer.toString();
  }

  // --- SHARE ACTIONS ---

  Future<void> shareNote(NoteModel note, {String? folderName}) async {
    final title = note.title.replaceAll(RegExp(r'[^\w\s]+'), '_');
    final filename = '${title.isEmpty ? "note" : title}.md';
    final content = exportNoteAsMarkdown(note, folderName: folderName);

    if (kIsWeb) {
      // On web we share via copy text or download
      await Share.share(content, subject: 'Gentle Notes Export: ${note.title}');
    } else {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$filename');
        await file.writeAsString(content);

        final xFile = XFile(file.path);
        await Share.shareXFiles([xFile], text: 'Sharing note: ${note.title}');
      } catch (e) {
        // Fallback to text sharing
        await Share.share(content, subject: 'Gentle Notes: ${note.title}');
      }
    }
  }

  Future<void> shareTemplate(NoteTemplateModel template) async {
    final jsonStr = exportTemplateAsJson(template);
    await Share.share(jsonStr, subject: 'Gentle Notes Template: ${template.name}');
  }

  // --- IMPORT ACTIONS ---

  Future<bool> importFromJsonString(String jsonStr) async {
    try {
      final Map<String, dynamic> payload = jsonDecode(jsonStr);
      if (payload['appName'] != 'Gentle Notes') return false;

      final type = payload['exportType'];
      if (type == 'note') {
        final noteMap = Map<String, dynamic>.from(payload['data']);
        final note = NoteModel.fromMap(noteMap);
        await _storage.saveNote(note);
        return true;
      } else if (type == 'folder') {
        final folderMap = Map<String, dynamic>.from(payload['folder']);
        final folder = FolderModel.fromMap(folderMap);
        await _storage.saveFolder(folder);

        final notesList = payload['data'] as List;
        for (var nMap in notesList) {
          final note = NoteModel.fromMap(Map<String, dynamic>.from(nMap));
          await _storage.saveNote(note);
        }
        return true;
      } else if (type == 'template') {
        final templateMap = Map<String, dynamic>.from(payload['data']);
        final template = NoteTemplateModel.fromMap(templateMap);
        await _storage.saveTemplate(template);
        return true;
      } else if (type == 'backup') {
        final foldersList = payload['folders'] as List? ?? [];
        for (var fMap in foldersList) {
          final folder = FolderModel.fromMap(Map<String, dynamic>.from(fMap));
          await _storage.saveFolder(folder);
        }

        final notesList = payload['notes'] as List? ?? [];
        for (var nMap in notesList) {
          final note = NoteModel.fromMap(Map<String, dynamic>.from(nMap));
          await _storage.saveNote(note);
        }

        final templatesList = payload['templates'] as List? ?? [];
        for (var tMap in templatesList) {
          final template = NoteTemplateModel.fromMap(Map<String, dynamic>.from(tMap));
          await _storage.saveTemplate(template);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pickAndImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'md', 'txt'],
      );

      if (result == null || result.files.single.path == null) return false;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      if (result.files.single.extension == 'json') {
        return await importFromJsonString(content);
      } else {
        // Import raw text/markdown file as a new note
        final filename = result.files.single.name;
        final title = filename.replaceAll(RegExp(r'\.\w+$'), '');
        final id = const Uuid().v4();

        final note = NoteModel(
          id: id,
          title: title,
          content: QuillMarkdownConverter.markdownToDeltaJson(content),
          noteType: NoteType.markdown,
          tags: ['imported'],
          attachments: [],
          isPinned: false,
          isFavorite: false,
          colorHex: '#FFFFFF',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _storage.saveNote(note);
        return true;
      }
    } catch (_) {
      return false;
    }
  }
}
