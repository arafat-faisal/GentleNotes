import 'package:hive_flutter/hive_flutter.dart';
import '../../models/models.dart';

class NoteStorage {
  final Box notesBox;

  NoteStorage({required this.notesBox});

  List<NoteModel> getNotes() {
    final List<NoteModel> notes = [];
    for (var key in notesBox.keys) {
      final val = notesBox.get(key);
      if (val is Map) {
        notes.add(NoteModel.fromMap(Map<String, dynamic>.from(val)));
      }
    }
    // Sort: most recently updated first by default.
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Future<void> saveNote(NoteModel note) async {
    await notesBox.put(note.id, note.toMap());
  }

  Future<void> deleteNote(String id) async {
    await notesBox.delete(id);
  }
}
