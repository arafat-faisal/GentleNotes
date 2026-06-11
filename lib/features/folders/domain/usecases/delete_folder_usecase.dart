/// Use case: Delete a folder by ID.
library;

import '../repositories/i_folders_repository.dart';

class DeleteFolderUseCase {
  const DeleteFolderUseCase(this._repository);

  final IFoldersRepository _repository;

  /// Deletes the folder with [folderId].
  /// Notes inside the folder are orphaned (moved to root), not deleted.
  Future<void> call(String folderId) async {
    await _repository.deleteFolder(folderId);
  }
}
