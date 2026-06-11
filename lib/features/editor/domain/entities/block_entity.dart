import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'block_type.dart';

/// Represents a single self-contained piece of content in the editor.
class BlockEntity {
  final String id;
  final BlockType type;
  final Map<String, dynamic> data; // Changed from String content
  final Map<String, dynamic> attributes; // Alignment, style properties, media configs

  BlockEntity({
    required this.id,
    required this.type,
    Map<String, dynamic>? data,
    String? content,
    this.attributes = const {},
  }) : data = data ??
            (content != null
                ? (type == BlockType.photoFrame
                    ? _parsePhotoFrame(content)
                    : (type == BlockType.audio
                        ? _parseAudioBlock(content)
                        : (type == BlockType.pdf ? {'path': content} : {'text': content})))
                : const {});

  static Map<String, dynamic> _parsePhotoFrame(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return {'images': List<String>.from(decoded)};
      }
    } catch (_) {}
    return {'images': <String>[]};
  }

  static Map<String, dynamic> _parseAudioBlock(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final tracks = decoded.map((item) {
          if (item is Map) {
            return {
              'path': item['path']?.toString() ?? '',
              'name': item['name']?.toString() ?? 'Track',
            };
          }
          final path = item.toString();
          return {
            'path': path,
            'name': path.split('/').last.split('\\').last,
          };
        }).toList();
        return {'audios': tracks};
      } else if (decoded is Map) {
        if (decoded.containsKey('audios')) {
          final audios = decoded['audios'];
          if (audios is List) {
            final tracks = audios.map((item) {
              if (item is Map) {
                return {
                  'path': item['path']?.toString() ?? '',
                  'name': item['name']?.toString() ?? 'Track',
                };
              }
              final path = item.toString();
              return {
                'path': path,
                'name': path.split('/').last.split('\\').last,
              };
            }).toList();
            return {'audios': tracks};
          }
        }
      }
    } catch (_) {}
    final name = content.startsWith('data:') 
        ? 'Voice Note.webm' 
        : content.split('/').last.split('\\').last;
    return {
      'audios': [
        {'path': content, 'name': name}
      ]
    };
  }

  factory BlockEntity.create(
    BlockType type, {
    String? content,
    Map<String, dynamic>? data,
    Map<String, dynamic> attrs = const {},
  }) {
    return BlockEntity(
      id: const Uuid().v4(),
      type: type,
      content: content,
      data: data,
      attributes: attrs,
    );
  }

  String get content {
    if (data.containsKey('text')) return data['text']?.toString() ?? '';
    if (data.containsKey('value')) return data['value']?.toString() ?? '';
    if (data.containsKey('url')) return data['url']?.toString() ?? '';
    if (data.containsKey('path')) return data['path']?.toString() ?? '';
    if (data.containsKey('audios')) {
      final audios = data['audios'];
      if (audios is List && audios.isNotEmpty) {
        final first = audios.first;
        if (first is Map) return first['path']?.toString() ?? '';
        return first.toString();
      }
    }
    return '';
  }

  BlockEntity copyWith({
    Map<String, dynamic>? data,
    String? content,
    Map<String, dynamic>? attributes,
  }) {
    return BlockEntity(
      id: id,
      type: type,
      data: data ?? (content != null ? {'text': content} : this.data),
      attributes: attributes ?? this.attributes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'attributes': attributes,
    };
  }

  factory BlockEntity.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'];
    final Map<String, dynamic> parsedData = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : (map['content'] != null ? {'text': map['content']} : const {});

    return BlockEntity(
      id: map['id'] ?? const Uuid().v4(),
      type: BlockType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BlockType.text,
      ),
      data: parsedData,
      attributes: Map<String, dynamic>.from(map['attributes'] ?? {}),
    );
  }
}
