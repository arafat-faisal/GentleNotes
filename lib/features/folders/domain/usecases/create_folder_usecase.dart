/// Use case: Create a new folder.
library;

import 'package:uuid/uuid.dart';
import '../../../../models/models.dart';
import '../repositories/i_folders_repository.dart';

class CreateFolderUseCase {
  const CreateFolderUseCase(this._repository);

  final IFoldersRepository _repository;

  Future<FolderModel> call({
    required String name,
    required String colorHex,
    required String iconName,
    String? parentFolderId,
    int sortOrder = 0,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Folder name cannot be empty.');
    }

    final folder = FolderModel(
      id: const Uuid().v4(),
      name: name.trim(),
      parentFolderId: parentFolderId,
      colorHex: colorHex,
      iconName: iconName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sortOrder: sortOrder,
    );

    await _repository.createFolder(folder);
    return folder;
  }
}
