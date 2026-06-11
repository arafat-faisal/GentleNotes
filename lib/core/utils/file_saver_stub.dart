import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveFileBytes(List<int> bytes, String filename) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$filename');
  await file.writeAsBytes(bytes);
  final xFile = XFile(file.path);
  await Share.shareXFiles([xFile], text: 'Sharing file: $filename');
}
