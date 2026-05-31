import 'package:hive_flutter/hive_flutter.dart';
import '../../models/models.dart';

class FolderStorage {
  final Box foldersBox;
  final Box notesBox;

  FolderStorage({required this.foldersBox, required this.notesBox});

  List<FolderModel> getFolders() {
    final List<FolderModel> folders = [];
    for (var key in foldersBox.keys) {
      final val = foldersBox.get(key);
      if (val is Map) {
        folders.add(FolderModel.fromMap(Map<String, dynamic>.from(val)));
      }
    }
    folders.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return folders;
  }

  Future<void> saveFolder(FolderModel folder) async {
    await foldersBox.put(folder.id, folder.toMap());
  }

  Future<void> deleteFolder(String id) async {
    await foldersBox.delete(id);
    // Unlink orphan notes from the deleted folder
    for (var key in notesBox.keys) {
      final val = notesBox.get(key);
      if (val is Map) {
        final note = NoteModel.fromMap(Map<String, dynamic>.from(val));
        if (note.folderId == id) {
          await notesBox.put(note.id, note.copyWith(folderId: null).toMap());
        }
      }
    }
  }
}
