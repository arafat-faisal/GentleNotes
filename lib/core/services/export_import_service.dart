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
import '../../features/pdf_viewer/data/models/pdf_annotation_model.dart';
import '../../features/pdf_viewer/data/models/pdf_bookmark_model.dart';

class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  factory ExportImportService() => _instance;
  ExportImportService._internal();

  final HiveLocalStorage _storage = HiveLocalStorage();

  // --- EXPORT HELPERS ---

  List<String> _extractPdfPathsFromNote(NoteModel note) {
    final pdfPaths = <String>[];
    for (final attachment in note.attachments) {
      if (attachment.type.name == 'pdf' || attachment.pathOrUrl.toLowerCase().endsWith('.pdf')) {
        pdfPaths.add(attachment.pathOrUrl);
      }
    }
    try {
      final List<dynamic> delta = jsonDecode(note.content);
      for (final op in delta) {
        if (op is Map<String, dynamic> && op['insert'] is Map<String, dynamic>) {
          final insert = op['insert'] as Map<String, dynamic>;
          if (insert.containsKey('pdf')) {
            final pdfVal = insert['pdf'];
            String? path;
            if (pdfVal is Map<String, dynamic>) {
              path = pdfVal['path']?.toString();
            } else if (pdfVal is String) {
              try {
                final parsed = jsonDecode(pdfVal);
                if (parsed is Map<String, dynamic>) {
                  path = parsed['path']?.toString();
                }
              } catch (_) {}
            }
            if (path != null && path.isNotEmpty) {
              pdfPaths.add(path);
            }
          }
        }
      }
    } catch (_) {}
    return pdfPaths;
  }

  List<Map<String, dynamic>> _getFolderStructureForNote(String? folderId) {
    final structure = <Map<String, dynamic>>[];
    if (folderId == null) return structure;

    final folders = _storage.getFolders();
    final folderMap = {for (final f in folders) f.id: f};

    String? currentId = folderId;
    while (currentId != null) {
      final f = folderMap[currentId];
      if (f == null) break;
      structure.insert(0, f.toMap()); // root folder first
      currentId = f.parentFolderId;
    }
    return structure;
  }

  // --- EXPORT TO STRING (JSON) ---

  String exportNoteAsJson(NoteModel note) {
    final pdfPaths = _extractPdfPathsFromNote(note);
    final List<Map<String, dynamic>> annotations = [];
    final List<Map<String, dynamic>> bookmarks = [];
    for (final path in pdfPaths) {
      final anns = _storage.getPdfAnnotations(path);
      final bms = _storage.getPdfBookmarks(path);
      annotations.addAll(anns.map((a) => a.toMap()));
      bookmarks.addAll(bms.map((b) => b.toMap()));
    }

    final folderStructure = _getFolderStructureForNote(note.folderId);

    final payload = {
      'appName': 'Gentle Notes',
      'exportVersion': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'exportType': 'note',
      'data': note.toMap(),
      'pdfAnnotations': annotations,
      'pdfBookmarks': bookmarks,
      'folderStructure': folderStructure,
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

      // 3. Extract from PDF annotations (snapshots and flashcards)
      final pdfPaths = _extractPdfPathsFromNote(note);
      for (final path in pdfPaths) {
        final anns = _storage.getPdfAnnotations(path);
        for (final ann in anns) {
          if ((ann.type == 'snapshot' || ann.type == 'flashcard') && ann.snapshotPath != null) {
            final snapPath = ann.snapshotPath!;
            if (snapPath.isNotEmpty && !addedPaths.contains(snapPath)) {
              if (snapPath.startsWith('/') || snapPath.contains(r':\') || snapPath.startsWith('file://') || snapPath.startsWith('data:')) {
                final filename = _suggestFilename(snapPath, 'image', assets.length);
                final bytes = await _readAssetBytes(snapPath);
                if (bytes != null) {
                  assets.add(AssetData(originalPathOrUrl: snapPath, filename: filename, bytes: bytes));
                  addedPaths.add(snapPath);
                }
              }
            }
          }
        }
      }
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

  void _collectSubtree(
    String folderId,
    List<FolderModel> allFolders,
    List<NoteModel> allNotes,
    List<FolderModel> collectedFolders,
    List<NoteModel> collectedNotes,
  ) {
    final subfolders = allFolders.where((f) => f.parentFolderId == folderId).toList();
    for (var sf in subfolders) {
      collectedFolders.add(sf);
      _collectSubtree(sf.id, allFolders, allNotes, collectedFolders, collectedNotes);
    }
    final notes = allNotes.where((n) => n.folderId == folderId).toList();
    collectedNotes.addAll(notes);
  }

  Future<void> shareFolder(FolderModel folder) async {
    final allFolders = _storage.getFolders();
    final allNotes = _storage.getNotes();

    final collectedFolders = <FolderModel>[folder];
    final collectedNotes = <NoteModel>[];

    _collectSubtree(folder.id, allFolders, allNotes, collectedFolders, collectedNotes);
    collectedNotes.addAll(allNotes.where((n) => n.folderId == folder.id).toList());

    final uniqueNotesMap = {for (var n in collectedNotes) n.id: n};
    final uniqueNotes = uniqueNotesMap.values.toList();

    final List<Map<String, dynamic>> annotations = [];
    final List<Map<String, dynamic>> bookmarks = [];
    for (final note in uniqueNotes) {
      final pdfPaths = _extractPdfPathsFromNote(note);
      for (final path in pdfPaths) {
        final anns = _storage.getPdfAnnotations(path);
        final bms = _storage.getPdfBookmarks(path);
        annotations.addAll(anns.map((a) => a.toMap()));
        bookmarks.addAll(bms.map((b) => b.toMap()));
      }
    }

    final parentFolderStructure = _getFolderStructureForNote(folder.parentFolderId);

    final payload = {
      'appName': 'Gentle Notes',
      'exportVersion': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'exportType': 'folder_tree',
      'folders': collectedFolders.map((f) => f.toMap()).toList(),
      'notes': uniqueNotes.map((n) => n.toMap()).toList(),
      'pdfAnnotations': annotations,
      'pdfBookmarks': bookmarks,
      'parentFolderStructure': parentFolderStructure,
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    final assets = await _extractAssets(uniqueNotes);
    final title = folder.name.replaceAll(RegExp(r'[^\w\s]+'), '_');
    final filename = '${title.isEmpty ? "folder" : title}.gentlefolder';

    final zipBytes = ArchiveHelper.createGentleArchiveInMemory(
      jsonContent: jsonStr,
      assets: assets,
    );

    await saveFileBytes(zipBytes, filename);
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
        var note = NoteModel.fromMap(noteMap);

        // Recreate folder structure if it exists in the payload
        String? newFolderId;
        if (payload.containsKey('folderStructure')) {
          final foldersList = payload['folderStructure'] as List;
          String? parentId; // root folder parent is null
          for (var fObj in foldersList) {
            final fMap = Map<String, dynamic>.from(fObj);
            final existingFolders = _storage.getFolders();
            FolderModel? match;
            for (var extF in existingFolders) {
              if (extF.name.toLowerCase() == fMap['name'].toString().toLowerCase() &&
                  extF.parentFolderId == parentId) {
                match = extF;
                break;
              }
            }

            if (match != null) {
              parentId = match.id;
            } else {
              final newId = const Uuid().v4();
              final newFolder = FolderModel(
                id: newId,
                name: fMap['name'],
                parentFolderId: parentId,
                colorHex: fMap['colorHex'] ?? '#2196F3',
                iconName: fMap['iconName'] ?? 'folder',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                sortOrder: fMap['sortOrder'] ?? 0,
              );
              await _storage.saveFolder(newFolder);
              parentId = newId;
            }
          }
          newFolderId = parentId;
        }

        if (newFolderId != null) {
          note = note.copyWith(folderId: newFolderId);
        }

        await _storage.saveNote(note);

        // Save PDF annotations & bookmarks
        if (payload.containsKey('pdfAnnotations')) {
          final annList = payload['pdfAnnotations'] as List;
          for (var annMap in annList) {
            final ann = PdfAnnotationModel.fromMap(Map<String, dynamic>.from(annMap));
            await _storage.savePdfAnnotation(ann);
          }
        }
        if (payload.containsKey('pdfBookmarks')) {
          final bmList = payload['pdfBookmarks'] as List;
          for (var bmMap in bmList) {
            final bm = PdfBookmarkModel.fromMap(Map<String, dynamic>.from(bmMap));
            await _storage.savePdfBookmark(bm);
          }
        }
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
      } else if (type == 'folder_tree') {
        // Recreate the parent folder structure if it exists
        String? currentParentId;
        if (payload.containsKey('parentFolderStructure')) {
          final parentStructure = payload['parentFolderStructure'] as List;
          for (var fObj in parentStructure) {
            final fMap = Map<String, dynamic>.from(fObj);
            final existingFolders = _storage.getFolders();
            FolderModel? match;
            for (var extF in existingFolders) {
              if (extF.name.toLowerCase() == fMap['name'].toString().toLowerCase() &&
                  extF.parentFolderId == currentParentId) {
                match = extF;
                break;
              }
            }

            if (match != null) {
              currentParentId = match.id;
            } else {
              final newId = const Uuid().v4();
              final newFolder = FolderModel(
                id: newId,
                name: fMap['name'],
                parentFolderId: currentParentId,
                colorHex: fMap['colorHex'] ?? '#2196F3',
                iconName: fMap['iconName'] ?? 'folder',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                sortOrder: fMap['sortOrder'] ?? 0,
              );
              await _storage.saveFolder(newFolder);
              currentParentId = newId;
            }
          }
        }

        // Now import folders recursively, adjusting parentFolderId mapping
        final foldersList = payload['folders'] as List;
        final folderIdMapping = <String, String>{}; // maps old folder ID to new folder ID

        final unresolvedFolders = foldersList.map((f) => Map<String, dynamic>.from(f)).toList();
        
        int iterations = 0;
        while (unresolvedFolders.isNotEmpty && iterations < 100) {
          iterations++;
          final toRemove = <Map<String, dynamic>>[];
          for (var fMap in unresolvedFolders) {
            final oldId = fMap['id'] as String;
            final oldParentId = fMap['parentFolderId'] as String?;
            
            final bool canResolve = oldParentId == null ||
                foldersList.every((other) => other['id'] != oldParentId) ||
                folderIdMapping.containsKey(oldParentId);

            if (canResolve) {
              final resolvedParentId = (oldParentId == null || foldersList.every((other) => other['id'] != oldParentId))
                  ? currentParentId
                  : folderIdMapping[oldParentId];

              final existingFolders = _storage.getFolders();
              FolderModel? match;
              for (var extF in existingFolders) {
                if (extF.name.toLowerCase() == fMap['name'].toString().toLowerCase() &&
                    extF.parentFolderId == resolvedParentId) {
                  match = extF;
                  break;
                }
              }

              if (match != null) {
                folderIdMapping[oldId] = match.id;
              } else {
                final newId = const Uuid().v4();
                final newFolder = FolderModel(
                  id: newId,
                  name: fMap['name'],
                  parentFolderId: resolvedParentId,
                  colorHex: fMap['colorHex'] ?? '#2196F3',
                  iconName: fMap['iconName'] ?? 'folder',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  sortOrder: fMap['sortOrder'] ?? 0,
                );
                await _storage.saveFolder(newFolder);
                folderIdMapping[oldId] = newId;
              }
              toRemove.add(fMap);
            }
          }
          unresolvedFolders.removeWhere((item) => toRemove.contains(item));
        }

        // Now import notes, mapping their folderId to the new folderId
        final notesList = payload['notes'] as List;
        for (var nMap in notesList) {
          var note = NoteModel.fromMap(Map<String, dynamic>.from(nMap));
          final oldFolderId = note.folderId;
          if (oldFolderId != null && folderIdMapping.containsKey(oldFolderId)) {
            note = note.copyWith(folderId: folderIdMapping[oldFolderId]);
          } else {
            note = note.copyWith(folderId: currentParentId);
          }
          await _storage.saveNote(note);
        }

        // Save PDF annotations & bookmarks
        if (payload.containsKey('pdfAnnotations')) {
          final annList = payload['pdfAnnotations'] as List;
          for (var annMap in annList) {
            final ann = PdfAnnotationModel.fromMap(Map<String, dynamic>.from(annMap));
            await _storage.savePdfAnnotation(ann);
          }
        }
        if (payload.containsKey('pdfBookmarks')) {
          final bmList = payload['pdfBookmarks'] as List;
          for (var bmMap in bmList) {
            final bm = PdfBookmarkModel.fromMap(Map<String, dynamic>.from(bmMap));
            await _storage.savePdfBookmark(bm);
          }
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

      final allowed = ['json', 'md', 'txt', 'gentlenote', 'gentlebackup', 'gentlefolder'];
      if (!allowed.contains(extension)) return false;

      if (kIsWeb) {
        final bytes = singleFile.bytes;
        if (bytes == null) return false;

        if (extension == 'gentlenote' || extension == 'gentlebackup' || extension == 'gentlefolder') {
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

        if (extension == 'gentlenote' || extension == 'gentlebackup' || extension == 'gentlefolder') {
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
