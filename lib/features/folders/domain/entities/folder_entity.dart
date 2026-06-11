/// Pure domain entity for a Folder.
///
/// Represents the business concept of a folder independent of persistence
/// or presentation concerns. No Flutter or Hive dependencies.
library;

/// Core domain entity representing a folder that contains notes.
class FolderEntity {
  const FolderEntity({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconName,
    required this.createdAt,
    required this.updatedAt,
    required this.sortOrder,
    this.parentFolderId,
    // Extension point: Cloud sync status
    this.syncStatus,
  });

  final String id;
  final String name;
  final String colorHex;
  final String iconName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;

  /// Parent folder ID for nested folders. Null means root-level folder.
  final String? parentFolderId;

  // ── Future Extension Points ──────────────────────────────────────────────────

  /// Cloud sync status for this folder.
  final String? syncStatus;

  // ── Helpers ──────────────────────────────────────────────────────────────────

  bool get isRootFolder => parentFolderId == null;

  FolderEntity copyWith({
    String? name,
    String? colorHex,
    String? iconName,
    DateTime? updatedAt,
    int? sortOrder,
    String? parentFolderId,
    String? syncStatus,
  }) {
    return FolderEntity(
      id: id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() => 'FolderEntity(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderEntity && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
