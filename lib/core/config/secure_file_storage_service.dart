// secure_file_storage_service.dart
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:elkitap/core/config/encript_service.dart';
import 'package:path_provider/path_provider.dart';

class SecureFileStorageService {
  final EncryptionService _encryptionService = EncryptionService();

  // Get the app's documents directory
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Create encrypted EPUB directory
  Future<Directory> get epubDirectory async {
    final path = await _localPath;
    final Directory dir = Directory('$path/encrypted_epubs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Create encrypted Audio directory
  Future<Directory> get audioDirectory async {
    final path = await _localPath;
    final Directory dir = Directory('$path/encrypted_audio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Save encrypted EPUB file
  Future<Map<String, dynamic>> saveEncryptedEpub(
    String fileName,
    Uint8List epubBytes,
  ) async {
    try {
      final dir = await epubDirectory;

      // Generate hash for integrity check
      final originalHash = await _encryptionService.generateFileHash(epubBytes);

      // Encrypt and save
      final encryptedPath = await _encryptionService.encryptAndSaveEpub(
        epubBytes,
        fileName,
        dir.path,
      );

      return {
        'success': true,
        'path': encryptedPath,
        'hash': originalHash,
        'size': epubBytes.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Save encrypted Audio file
  Future<Map<String, dynamic>> saveEncryptedAudio(
    String fileName,
    Uint8List audioBytes,
  ) async {
    try {
      final dir = await audioDirectory;

      // Generate hash for integrity check
      final originalHash = await _encryptionService.generateFileHash(audioBytes);

      // Encrypt and save
      final encryptedPath = await _encryptionService.encryptAndSaveAudio(
        audioBytes,
        fileName,
        dir.path,
      );

      return {
        'success': true,
        'path': encryptedPath,
        'hash': originalHash,
        'size': audioBytes.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Save raw (unencrypted) audio file for offline playback
  Future<Map<String, dynamic>> saveRawAudio(
    String fileName,
    Uint8List audioBytes,
  ) async {
    try {
      final dir = await audioDirectory;
      final file = File('${dir.path}/$fileName.aac');
      await file.writeAsBytes(audioBytes);
      return {
        'success': true,
        'path': file.path,
        'hash': '',
        'size': audioBytes.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get raw audio file for playback (no decryption needed)
  Future<File?> getRawAudioFile(String fileName) async {
    try {
      final dir = await audioDirectory;
      for (final ext in ['.aac', '.mp3', '.m4a']) {
        final file = File('${dir.path}/$fileName$ext');
        if (await file.exists()) return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Read and decrypt EPUB file
  Future<Map<String, dynamic>> readDecryptedEpub(String fileName) async {
    try {
      final dir = await epubDirectory;
      final encryptedPath = '${dir.path}/$fileName.encrypted';

      // Decrypt file
      final decryptedBytes = await _encryptionService.readAndDecryptEpub(
        encryptedPath,
      );

      return {
        'success': true,
        'data': decryptedBytes,
        'size': decryptedBytes.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Read and decrypt Audio file
  Future<Map<String, dynamic>> readDecryptedAudio(String fileName) async {
    try {
      final dir = await audioDirectory;
      final encryptedPath = '${dir.path}/$fileName.encrypted';

      log('🔓 Decrypting audio: $encryptedPath');
      final encryptedFile = File(encryptedPath);
      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted audio file not found');
      }
      log('🔓 Encrypted file exists, size: ${await encryptedFile.length()} bytes');

      // Decrypt file
      final decryptedBytes = await _encryptionService.readAndDecryptAudio(
        encryptedPath,
      );

      log('✅ Audio decrypted successfully, size: ${decryptedBytes.length} bytes');
      return {
        'success': true,
        'data': decryptedBytes,
        'size': decryptedBytes.length,
      };
    } catch (e) {
      log('❌ Failed to decrypt audio: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Verify file integrity
  Future<bool> verifyEpubIntegrity(
    String fileName,
    String originalHash,
  ) async {
    try {
      final result = await readDecryptedEpub(fileName);

      if (!result['success']) {
        return false;
      }

      return await _encryptionService.verifyFileIntegrity(
        result['data'],
        originalHash,
      );
    } catch (e) {
      return false;
    }
  }

  // Verify audio file integrity
  Future<bool> verifyAudioIntegrity(
    String fileName,
    String originalHash,
  ) async {
    try {
      final result = await readDecryptedAudio(fileName);

      if (!result['success']) {
        return false;
      }

      return await _encryptionService.verifyFileIntegrity(
        result['data'],
        originalHash,
      );
    } catch (e) {
      return false;
    }
  }

  // Delete encrypted EPUB file
  Future<bool> deleteEncryptedEpub(String fileName) async {
    try {
      final dir = await epubDirectory;
      final file = File('${dir.path}/$fileName.encrypted');

      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Delete encrypted Audio file
  Future<bool> deleteEncryptedAudio(String fileName) async {
    try {
      final dir = await audioDirectory;
      final file = File('${dir.path}/$fileName.encrypted');

      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if encrypted file exists
  Future<bool> fileExists(String fileName) async {
    final dir = await epubDirectory;
    final file = File('${dir.path}/$fileName.encrypted');
    return await file.exists();
  }

  // Check if encrypted audio exists
  Future<bool> audioExists(String fileName) async {
    final dir = await audioDirectory;
    final file = File('${dir.path}/$fileName.encrypted');
    return await file.exists();
  }

  // Get all encrypted EPUB files
  Future<List<Map<String, dynamic>>> getAllEncryptedEpubs() async {
    try {
      final dir = await epubDirectory;
      final files = dir.listSync();

      List<Map<String, dynamic>> epubList = [];

      for (var file in files) {
        if (file is File && file.path.endsWith('.encrypted')) {
          final fileName = file.path.split('/').last;
          final stats = await file.stat();

          epubList.add({
            'fileName': fileName.replaceAll('.encrypted', ''),
            'path': file.path,
            'size': stats.size,
            'modified': stats.modified,
          });
        }
      }

      return epubList;
    } catch (e) {
      return [];
    }
  }

  // Get all encrypted Audio files
  Future<List<Map<String, dynamic>>> getAllEncryptedAudio() async {
    try {
      final dir = await audioDirectory;
      final files = dir.listSync();

      List<Map<String, dynamic>> audioList = [];

      for (var file in files) {
        if (file is File && file.path.endsWith('.encrypted')) {
          final fileName = file.path.split('/').last;
          final stats = await file.stat();

          audioList.add({
            'fileName': fileName.replaceAll('.encrypted', ''),
            'path': file.path,
            'size': stats.size,
            'modified': stats.modified,
          });
        }
      }

      return audioList;
    } catch (e) {
      return [];
    }
  }

  // Export decrypted EPUB to temp (for reading)
  Future<File?> exportDecryptedToTemp(String fileName) async {
    try {
      final result = await readDecryptedEpub(fileName);

      if (!result['success']) {
        return null;
      }

      // Create temporary file with .epub extension
      final tempDir = await getTemporaryDirectory();
      final tempFileName = fileName.endsWith('.epub') ? fileName : '$fileName.epub';
      final tempFile = File('${tempDir.path}/$tempFileName');

      // Delete if exists
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Write decrypted data
      await tempFile.writeAsBytes(result['data']);

      return tempFile;
    } catch (e) {
      return null;
    }
  }

  /// Export decrypted audio to temp directory with caching support
  Future<File?> exportDecryptedAudioToTemp(String fileName) async {
    try {
      log('🎵 Exporting decrypted audio to temp: $fileName');

      // Determine temp file name/path before decrypting so we can cache-check.
      final tempDir = await getTemporaryDirectory();
      final tempFileName = fileName.endsWith('.m4a')
          ? fileName
          : fileName.endsWith('.mp3')
              ? fileName
              : '$fileName.m4a'; // Default to m4a for HLS audio
      final tempFile = File('${tempDir.path}/$tempFileName');

      // Reuse cached temp file when the encrypted source hasn't changed.
      if (await tempFile.exists()) {
        final dir = await audioDirectory;
        final encryptedPath = '${dir.path}/$fileName.encrypted';
        final encryptedFile = File(encryptedPath);
        if (await encryptedFile.exists()) {
          final tempStat = await tempFile.stat();
          final encStat = await encryptedFile.stat();
          if (tempStat.modified.isAfter(encStat.modified)) {
            log('✅ Using cached temp audio file');
            return tempFile;
          }
        }
      }

      final result = await readDecryptedAudio(fileName);

      if (!result['success']) {
        log('❌ Failed to decrypt audio for temp export');
        return null;
      }

      // Write decrypted data
      await tempFile.writeAsBytes(result['data']);
      log('✅ Temp audio file written: ${tempFile.path} (${result['size']} bytes)');

      return tempFile;
    } catch (e) {
      log('❌ exportDecryptedAudioToTemp error: $e');
      return null;
    }
  }

  // Get storage info
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final epubFiles = await getAllEncryptedEpubs();
      final audioFiles = await getAllEncryptedAudio();

      int totalSize = 0;

      for (var file in epubFiles) {
        totalSize += file['size'] as int;
      }

      for (var file in audioFiles) {
        totalSize += file['size'] as int;
      }

      return {
        'totalFiles': epubFiles.length + audioFiles.length,
        'epubFiles': epubFiles.length,
        'audioFiles': audioFiles.length,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'totalSizeGB': (totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      return {
        'totalFiles': 0,
        'epubFiles': 0,
        'audioFiles': 0,
        'totalSize': 0,
        'totalSizeMB': '0.00',
        'totalSizeGB': '0.00',
      };
    }
  }
}
