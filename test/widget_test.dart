import 'package:flutter_test/flutter_test.dart';
import 'package:gentle_notes/models/models.dart';

void main() {
  test('FolderModel serialization test', () {
    final folder = FolderModel(
      id: 'test-id',
      name: 'Test Folder',
      colorHex: '#6366F1',
      iconName: 'folder',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sortOrder: 1,
    );

    final map = folder.toMap();
    expect(map['id'], 'test-id');
    expect(map['name'], 'Test Folder');

    final deserialized = FolderModel.fromMap(map);
    expect(deserialized.id, folder.id);
    expect(deserialized.name, folder.name);
  });
}
