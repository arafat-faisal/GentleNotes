import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;

class AssetData {
  final String originalPathOrUrl;
  final String filename;
  final Uint8List bytes;

  AssetData({
    required this.originalPathOrUrl,
    required this.filename,
    required this.bytes,
  });
}

class ArchiveHelper {
  /// Zips a list of files and a json string into a destination zip file.
  /// Deprecated in favor of [createGentleArchiveInMemory].
  static Future<void> createGentleArchive({
    required String jsonContent,
    required List<String> localAssetPaths,
    required String destinationPath,
  }) async {
    final assets = <AssetData>[];
    for (final path in localAssetPaths) {
      if (!kIsWeb) {
        final file = io.File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          assets.add(AssetData(
            originalPathOrUrl: path,
            filename: p.basename(path),
            bytes: bytes,
          ));
        }
      }
    }
    final zipBytes = createGentleArchiveInMemory(jsonContent: jsonContent, assets: assets);
    if (!kIsWeb) {
      final file = io.File(destinationPath);
      await file.create(recursive: true);
      await file.writeAsBytes(zipBytes);
    }
  }

  /// In-memory zip creation. Returns zip bytes.
  static List<int> createGentleArchiveInMemory({
    required String jsonContent,
    required List<AssetData> assets,
  }) {
    final archive = Archive();
    String modifiedJson = jsonContent;

    for (final asset in assets) {
      archive.addFile(ArchiveFile('assets/${asset.filename}', asset.bytes.length, asset.bytes));
      
      // Replace original path/url with relative placeholder in the JSON content
      modifiedJson = modifiedJson.replaceAll(asset.originalPathOrUrl, 'assets/${asset.filename}');
      
      // Also handle backslash/forward slash variant if it's a file path
      final normalized = asset.originalPathOrUrl.replaceAll(r'\', '/');
      if (normalized != asset.originalPathOrUrl) {
        modifiedJson = modifiedJson.replaceAll(normalized, 'assets/${asset.filename}');
      }
    }

    // Add data.json
    final jsonBytes = utf8.encode(modifiedJson);
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

    final encoder = ZipEncoder();
    return encoder.encode(archive) ?? [];
  }

  /// Extracts a `.gentle` archive from path.
  /// Deprecated: use [extractGentleArchiveBytes] instead.
  static Future<Map<String, dynamic>> extractGentleArchive({
    required String archivePath,
    required String targetAssetsDir,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('extractGentleArchive from file path is not supported on Web.');
    }
    final bytes = await io.File(archivePath).readAsBytes();
    return extractGentleArchiveBytes(zipBytes: bytes, targetAssetsDir: targetAssetsDir);
  }

  /// Extracts a `.gentle` archive from in-memory bytes.
  /// Returns a map containing:
  /// - 'json': String? (the JSON content string)
  /// - 'assets': Map<String, String> (translates old asset filename to the newly extracted local file path/base64 URL)
  static Future<Map<String, dynamic>> extractGentleArchiveBytes({
    required List<int> zipBytes,
    String? targetAssetsDir,
  }) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    String? jsonContent;
    final Map<String, String> extractedAssets = {};

    for (final file in archive) {
      if (file.isFile) {
        if (file.name == 'data.json') {
          jsonContent = utf8.decode(file.content as List<int>);
        } else if (file.name.startsWith('assets/')) {
          final data = file.content as List<int>;
          final filename = p.basename(file.name);

          if (kIsWeb || targetAssetsDir == null) {
            // Convert to base64 data URL on Web
            final mime = _getMimeType(filename);
            final base64Str = base64Encode(data);
            final dataUrl = 'data:$mime;base64,$base64Str';
            extractedAssets[filename] = dataUrl;
          } else {
            // Native platform: save to targetAssetsDir
            final outPath = p.join(targetAssetsDir, filename);
            final outFile = io.File(outPath);
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(data);
            extractedAssets[filename] = outPath;
          }
        }
      }
    }

    return {
      'json': jsonContent,
      'assets': extractedAssets,
    };
  }

  static String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'pdf': return 'application/pdf';
      case 'm4a': return 'audio/m4a';
      case 'mp3': return 'audio/mpeg';
      case 'wav': return 'audio/wav';
      default: return 'application/octet-stream';
    }
  }
}
