import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/local_storage.dart';
import '../../../models/models.dart';

class FoldersNotifier extends StateNotifier<List<FolderModel>> {
  final LocalStorage _storage;

  FoldersNotifier(this._storage) : super([]) {
    loadFolders();
  }

  void loadFolders() {
    state = _storage.getFolders();
  }

  Future<void> addFolder(FolderModel folder) async {
    await _storage.saveFolder(folder);
    loadFolders();
  }

  Future<void> updateFolder(FolderModel folder) async {
    await _storage.saveFolder(folder);
    loadFolders();
  }

  Future<void> deleteFolder(String id) async {
    await _storage.deleteFolder(id);
    loadFolders();
  }

  FolderModel? getFolderById(String id) {
    try {
      return state.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }
}

final foldersStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

final foldersProvider = StateNotifierProvider<FoldersNotifier, List<FolderModel>>((ref) {
  final storage = ref.watch(foldersStorageProvider);
  return FoldersNotifier(storage);
});
