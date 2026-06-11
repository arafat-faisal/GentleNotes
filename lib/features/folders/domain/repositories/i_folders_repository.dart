/// Abstract repository contract for folders.
library;

import '../../../../models/models.dart';

/// Contract that all folder repositories must fulfill.
abstract class IFoldersRepository {
  /// Returns all folders, sorted by [sortOrder].
  List<FolderModel> getAllFolders();

  /// Returns the folder with [id], or null if not found.
  FolderModel? getFolderById(String id);

  /// Persists a new folder.
  Future<void> createFolder(FolderModel folder);

  /// Updates an existing folder.
  Future<void> updateFolder(FolderModel folder);

  /// Deletes the folder with [id] and orphans its notes (sets folderId to null).
  Future<void> deleteFolder(String id);
}
