import 'package:flutter/material.dart';

Widget previewLine(Color color, double widthFactor) {
  return LayoutBuilder(builder: (ctx, box) {
    return Container(
      height: 5,
      width: box.maxWidth * widthFactor,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  });
}

Widget previewBar(Color color, double widthFactor) {
  return LayoutBuilder(builder: (ctx, box) {
    return Container(
      height: 5,
      width: box.maxWidth * widthFactor,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  });
}

Widget previewPill(Color bg, Color border, double width) {
  return Container(
    height: 10,
    width: width,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: border.withOpacity(0.3)),
    ),
  );
}

Widget previewColorDots() {
  const colors = [Color(0xFFFEE2E2), Color(0xFFFEF3C7), Color(0xFFECFDF5), Color(0xFFE0F2FE)];
  return Row(
    children: colors.map((c) => Container(
      margin: const EdgeInsets.only(left: 2),
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    )).toList(),
  );
}
