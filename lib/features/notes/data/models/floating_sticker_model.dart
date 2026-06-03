class FloatingStickerModel {
  final String id;
  final String name; // Asset filename key (e.g. 'cat', 'coffee')
  final double x; // absolute X offset in the note canvas
  final double y; // absolute Y offset in the note canvas
  final double width;
  final double height;
  final double opacity; // 0.0 to 1.0
  final bool hasBackground; // White background box (false = cutout)
  final String textOver; // Optional overlay text
  final String textBehavior; // 'under', 'over', 'avoid'

  FloatingStickerModel({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.width = 120.0,
    this.height = 120.0,
    this.opacity = 1.0,
    this.hasBackground = false,
    this.textOver = '',
    this.textBehavior = 'under',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'opacity': opacity,
      'hasBackground': hasBackground ? 1 : 0,
      'textOver': textOver,
      'textBehavior': textBehavior,
    };
  }

  factory FloatingStickerModel.fromMap(Map<String, dynamic> map) {
    return FloatingStickerModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 120.0,
      height: (map['height'] as num?)?.toDouble() ?? 120.0,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      hasBackground: (map['hasBackground'] == 1 || map['hasBackground'] == true),
      textOver: map['textOver'] ?? '',
      textBehavior: map['textBehavior'] ?? 'under',
    );
  }

  FloatingStickerModel copyWith({
    String? name,
    double? x,
    double? y,
    double? width,
    double? height,
    double? opacity,
    bool? hasBackground,
    String? textOver,
    String? textBehavior,
  }) {
    return FloatingStickerModel(
      id: id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      opacity: opacity ?? this.opacity,
      hasBackground: hasBackground ?? this.hasBackground,
      textOver: textOver ?? this.textOver,
      textBehavior: textBehavior ?? this.textBehavior,
    );
  }
}
