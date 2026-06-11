import 'package:flutter/material.dart';

class FolderModel {
  final String id;
  final String name;
  final String? parentFolderId;
  final String colorHex;
  final String iconName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;

  FolderModel({
    required this.id,
    required this.name,
    this.parentFolderId,
    required this.colorHex,
    required this.iconName,
    required this.createdAt,
    required this.updatedAt,
    required this.sortOrder,
  });

  FolderModel copyWith({
    String? name,
    String? parentFolderId,
    bool clearParentFolder = false,
    String? colorHex,
    String? iconName,
    DateTime? updatedAt,
    int? sortOrder,
  }) {
    return FolderModel(
      id: id,
      name: name ?? this.name,
      parentFolderId: clearParentFolder ? null : (parentFolderId ?? this.parentFolderId),
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentFolderId': parentFolderId,
      'colorHex': colorHex,
      'iconName': iconName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sortOrder': sortOrder,
    };
  }

  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      parentFolderId: map['parentFolderId'],
      colorHex: map['colorHex'] ?? '#2196F3',
      iconName: map['iconName'] ?? 'folder',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      sortOrder: map['sortOrder'] ?? 0,
    );
  }

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.blue;
  }
}
