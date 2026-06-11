import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../utils/file_saver.dart';
import '../utils/quill_markdown_converter.dart';
import '../utils/archive_helper.dart';
import 'pdf_export_service.dart';
import 'storage/hive_local_storage.dart';

class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  factory ExportImportService() => _instance;
  ExportImportService._internal();

  final HiveLocalStorage _storage = HiveLocalStorage();

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

  // --- ASSET EXTRACTION ---

  // --- ASSET EXTRACTION ---

  Future<List<AssetData>> _extractAssets(List<NoteModel> notes) async {
    final assets = <AssetData>[];
    final addedPaths = <String>{};

    for (final note in notes) {
      // 1. Extract from note.attachments
      for (final attachment in note.attachments) {
        final path = attachment.pathOrUrl;
        if (path.isEmpty || addedPaths.contains(path)) continue;
        
        final filename = attachment.name;
        final bytes = await _readAssetBytes(path);
        if (bytes != null) {
          assets.add(AssetData(originalPathOrUrl: path, filename: filename, bytes: bytes));
          addedPaths.add(path);
        }
      }

      // 2. Extract from note.content (quill delta)
      try {
        final List<dynamic> delta = jsonDecode(note.content);
        for (final op in delta) {
          if (op is Map<String, dynamic> && op['insert'] is Map<String, dynamic>) {
            final insert = op['insert'] as Map<String, dynamic>;
            
            // Image
            if (insert.containsKey('image')) {
              final path = insert['image'].toString();
              if (path.isNotEmpty && !addedPaths.contains(path)) {
                if (path.startsWith('/') || path.contains(r':\') || path.startsWith('file://') || path.startsWith('data:')) {
                  final filename = _suggestFilename(path, 'image', assets.length);
                  final bytes = await _readAssetBytes(path);
                  if (bytes != null) {
                    assets.add(AssetData(originalPathOrUrl: path, filename: filename, bytes: bytes));
                    addedPaths.add(path);
                  }
                }
              }
            }

            // Audio
            if (insert.containsKey('audio')) {
              final audioVal = insert['audio'];
              String? path;
              if (audioVal is Map<String, dynamic>) {
                path = audioVal['path']?.toString();
              } else if (audioVal is String) {
                try {
                  final parsed = jsonDecode(audioVal);
                  if (parsed is Map<String, dynamic>) {
                    path = parsed['path']?.toString();
                  } else {
                    path = audioVal;
                  }
                } catch (_) {
                  path = audioVal;
                }
              }
              if (path != null && path.isNotEmpty && !addedPaths.contains(path)) {
                if (path.startsWith('/') || path.contains(r':\') || path.startsWith('file://') || path.startsWith('data:')) {
                  final filename = _suggestFilename(path, 'audio', assets.length);
                  final bytes = await _readAssetBytes(path);
                  if (bytes != null) {
                    assets.add(AssetData(originalPathOrUrl: path, filename: filename, bytes: bytes));
                    addedPaths.add(path);
                  }
                }
              }
            }

            // PDF
            if (insert.containsKey('pdf')) {
              final pdfVal = insert['pdf'];
              String? path;
              String? name;
              if (pdfVal is Map<String, dynamic>) {
                path = pdfVal['path']?.toString();
                name = pdfVal['name']?.toString();
              } else if (pdfVal is String) {
                try {
                  final parsed = jsonDecode(pdfVal);
                  if (parsed is Map<String, dynamic>) {
                    path = parsed['path']?.toString();
                    name = parsed['name']?.toString();
                  }
                } catch (_) {}
              }
              if (path != null && path.isNotEmpty && !addedPaths.contains(path)) {
                if (path.startsWith('/') || path.contains(r':\') || path.startsWith('file://') || path.startsWith('data:')) {
                  final filename = name ?? _suggestFilename(path, 'pdf', assets.length);
                  final bytes = await _readAssetBytes(path);
                  if (bytes != null) {
                    assets.add(AssetData(originalPathOrUrl: path, filename: filename, bytes: bytes));
                    addedPaths.add(path);
                  }
                }
              }
            }

            // Photo Frame
            for (final key in ['photo-frame', 'photo_frame']) {
              if (insert.containsKey(key)) {
                final frameVal = insert[key];
                List<String> paths = [];
                if (frameVal is Map<String, dynamic>) {
                  final images = frameVal['images'] as List<dynamic>?;
                  if (images != null) paths = images.map((e) => e.toString()).toList();
                } else if (frameVal is String) {
                  try {
                    final parsed = jsonDecode(frameVal);
                    if (parsed is Map<String, dynamic>) {
                      final images = parsed['images'] as List<dynamic>?;
                      if (images != null) paths = images.map((e) => e.toString()).toList();
                    }
                  } catch (_) {}
                }
                for (final path in paths) {
                  if (path.isNotEmpty && !addedPaths.contains(path)) {
                    if (path.startsWith('/') || path.contains(r':\') || path.startsWith('file://') || path.startsWith('data:')) {
                      final filename = _suggestFilename(path, 'image', assets.length);
                      final bytes = await _readAssetBytes(path);
                      if (bytes != null) {
                        assets.add(AssetData(originalPathOrUrl: path, filename: filename, bytes: bytes));
                        addedPaths.add(path);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      } catch (_) {}
    }
    return assets;
  }

  Future<Uint8List?> _readAssetBytes(String path) async {
    try {
      if (path.startsWith('data:')) {
        final base64Str = path.split(',').last;
        return base64Decode(base64Str);
      }
      
      if (kIsWeb) {
        return null;
      }
      
      final cleanPath = path.replaceFirst('file://', '');
      final file = File(cleanPath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }

  String _suggestFilename(String path, String type, int index) {
    if (path.startsWith('data:')) {
      final match = RegExp(r'data:([a-zA-Z0-9/\-\+]+);base64').firstMatch(path);
      if (match != null) {
        final mime = match.group(1);
        final ext = mime?.split('/').last ?? 'bin';
        return '${type}_$index.$ext';
      }
      return '${type}_$index.bin';
    }
    
    final uri = Uri.parse(path);
    final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    if (filename.contains('.')) {
      return filename;
    }
    
    switch (type) {
      case 'image': return 'image_$index.png';
      case 'audio': return 'audio_$index.m4a';
      case 'pdf': return 'document_$index.pdf';
      default: return 'asset_$index.bin';
    }
  }

  // --- SHARE ACTIONS ---

  Future<void> shareNote(NoteModel note, {String? folderName, bool asMarkdown = false}) async {
    if (asMarkdown) {
      final title = note.title.replaceAll(RegExp(r'[^\w\s]+'), '_');
      final filename = '${title.isEmpty ? "note" : title}.md';
      final content = exportNoteAsMarkdown(note, folderName: folderName);

      if (kIsWeb) {
        await Share.share(content, subject: 'Gentle Notes Export: ${note.title}');
      } else {
        try {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$filename');
          await file.writeAsString(content);

          final xFile = XFile(file.path);
          await Share.shareXFiles([xFile], text: 'Sharing note: ${note.title}');
        } catch (e) {
          await Share.share(content, subject: 'Gentle Notes: ${note.title}');
        }
      }
      return;
    }

    // Share as .gentlenote zip
    final jsonStr = exportNoteAsJson(note);
    final assets = await _extractAssets([note]);
    final title = note.title.replaceAll(RegExp(r'[^\w\s]+'), '_');
    final filename = '${title.isEmpty ? "note" : title}.gentlenote';
    
    final zipBytes = ArchiveHelper.createGentleArchiveInMemory(
      jsonContent: jsonStr,
      assets: assets,
    );

    await saveFileBytes(zipBytes, filename);
  }

  Future<void> shareNoteAsPdf(
    NoteModel note, {
    required bool includeImages,
    required bool includePdfs,
    required bool includeAudio,
  }) async {
    final pdfBytes = await PdfExportService().generatePdfBytes(
      note,
      includeImages: includeImages,
      includePdfs: includePdfs,
      includeAudio: includeAudio,
    );
    
    final tempDir = await getTemporaryDirectory();
    final title = note.title.replaceAll(RegExp(r'[^\w\s]+'), '_');
    final filename = '${title.isEmpty ? "note" : title}.pdf';
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(pdfBytes);

    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: 'Sharing note: ${note.title}');
  }

  Future<void> shareTemplate(NoteTemplateModel template) async {
    final jsonStr = exportTemplateAsJson(template);
    await Share.share(jsonStr, subject: 'Gentle Notes Template: ${template.name}');
  }

  Future<void> backupToGentleArchive() async {
    final jsonStr = exportBackupAsJson();
    final notes = _storage.getNotes();
    final assets = await _extractAssets(notes);
    final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final filename = 'GentleNotes_Backup_$dateStr.gentlebackup';

    final zipBytes = ArchiveHelper.createGentleArchiveInMemory(
      jsonContent: jsonStr,
      assets: assets,
    );

    await saveFileBytes(zipBytes, filename);
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
        type: FileType.any,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return false;

      final singleFile = result.files.single;
      final extension = singleFile.extension?.toLowerCase() ?? singleFile.name.split('.').last.toLowerCase();

      final allowed = ['json', 'md', 'txt', 'gentlenote', 'gentlebackup'];
      if (!allowed.contains(extension)) return false;

      if (kIsWeb) {
        final bytes = singleFile.bytes;
        if (bytes == null) return false;

        if (extension == 'gentlenote' || extension == 'gentlebackup') {
          final extraction = await ArchiveHelper.extractGentleArchiveBytes(zipBytes: bytes);
          String? jsonContent = extraction['json'] as String?;
          final Map<String, String>? extractedAssets = (extraction['assets'] as Map?)?.cast<String, String>();
          
          if (jsonContent != null) {
            String json = jsonContent;
            if (extractedAssets != null) {
              for (final entry in extractedAssets.entries) {
                final placeholder = 'assets/${entry.key}';
                final absolutePath = entry.value;
                json = json.replaceAll(placeholder, absolutePath);
              }
            }
            return await importFromJsonString(json);
          }
          return false;
        }

        final content = utf8.decode(bytes);

        if (extension == 'json') {
          return await importFromJsonString(content);
        } else {
          final filename = singleFile.name;
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
      } else {
        if (singleFile.path == null) return false;
        final file = File(singleFile.path!);

        if (extension == 'gentlenote' || extension == 'gentlebackup') {
          final zipBytes = await file.readAsBytes();
          final appDocDir = await getApplicationDocumentsDirectory();
          final targetAssetsDir = '${appDocDir.path}/imported_assets';

          final extraction = await ArchiveHelper.extractGentleArchiveBytes(
            zipBytes: zipBytes,
            targetAssetsDir: targetAssetsDir,
          );

          String? jsonContent = extraction['json'] as String?;
          final Map<String, String>? extractedAssets = (extraction['assets'] as Map?)?.cast<String, String>();

          if (jsonContent != null) {
            String json = jsonContent;
            if (extractedAssets != null) {
              for (final entry in extractedAssets.entries) {
                final placeholder = 'assets/${entry.key}';
                final absolutePath = entry.value.replaceAll(r'\', '/');
                final ext = entry.key.split('.').last.toLowerCase();
                final isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'heic', 'heif'].contains(ext);
                final pathWithScheme = isImage ? 'file://$absolutePath' : absolutePath;
                json = json.replaceAll(placeholder, pathWithScheme);
              }
            }
            return await importFromJsonString(json);
          }
          return false;
        }

        final content = await file.readAsString();

        if (extension == 'json') {
          return await importFromJsonString(content);
        } else {
          final filename = singleFile.name;
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
      }
    } catch (_) {
      return false;
    }
  }
}
