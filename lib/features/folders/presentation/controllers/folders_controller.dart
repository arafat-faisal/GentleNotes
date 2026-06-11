/// Riverpod controller and providers for the Folders feature.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage/hive_local_storage.dart';
import '../../../../core/services/storage/i_local_storage.dart';
import '../../../../models/models.dart';
import '../../data/repositories/folders_repository_impl.dart';
import '../../domain/repositories/i_folders_repository.dart';

// ── Dependency Injection ──────────────────────────────────────────────────────

final _foldersStorageProvider = Provider<ILocalStorage>((ref) => HiveLocalStorage());

final foldersRepositoryProvider = Provider<IFoldersRepository>((ref) {
  final storage = ref.watch(_foldersStorageProvider);
  return FoldersRepositoryImpl(storage);
});

// ── State Notifier ────────────────────────────────────────────────────────────

/// Controller for all folder CRUD operations.
class FoldersController extends StateNotifier<List<FolderModel>> {
  FoldersController(this._repository) : super([]) {
    loadFolders();
  }

  final IFoldersRepository _repository;

  void loadFolders() {
    state = _repository.getAllFolders();
  }

  Future<void> addFolder(FolderModel folder) async {
    await _repository.createFolder(folder);
    loadFolders();
  }

  Future<void> updateFolder(FolderModel folder) async {
    await _repository.updateFolder(folder);
    loadFolders();
  }

  Future<void> deleteFolder(String id) async {
    // Unlink any subfolders of this folder
    final subfolders = state.where((f) => f.parentFolderId == id).toList();
    for (var sub in subfolders) {
      await updateFolder(sub.copyWith(clearParentFolder: true));
    }
    await _repository.deleteFolder(id);
    loadFolders();
  }

  /// Returns the folder matching [id], or null.
  FolderModel? getFolderById(String id) {
    return _repository.getFolderById(id);
  }
}

/// Provides the complete list of folders.
final foldersProvider =
    StateNotifierProvider<FoldersController, List<FolderModel>>((ref) {
  final repository = ref.watch(foldersRepositoryProvider);
  return FoldersController(repository);
});
