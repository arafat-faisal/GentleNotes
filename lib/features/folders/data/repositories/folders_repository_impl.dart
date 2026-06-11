/// Concrete implementation of [IFoldersRepository] backed by local storage.
library;

import '../../../../core/services/storage/i_local_storage.dart';
import '../../../../models/models.dart';
import '../../domain/repositories/i_folders_repository.dart';

class FoldersRepositoryImpl implements IFoldersRepository {
  const FoldersRepositoryImpl(this._storage);

  final ILocalStorage _storage;

  @override
  List<FolderModel> getAllFolders() => _storage.getFolders();

  @override
  FolderModel? getFolderById(String id) {
    try {
      return _storage.getFolders().firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createFolder(FolderModel folder) => _storage.saveFolder(folder);

  @override
  Future<void> updateFolder(FolderModel folder) => _storage.saveFolder(folder);

  @override
  Future<void> deleteFolder(String id) => _storage.deleteFolder(id);
}
