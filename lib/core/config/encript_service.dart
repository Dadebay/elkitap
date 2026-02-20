// encript_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Top-level functions required by compute() — run in a background isolate

Uint8List _decryptBytesIsolate(Map<String, dynamic> params) {
  final encryptedBytes = params['bytes'] as Uint8List;
  final key = Key(params['key'] as Uint8List);
  final iv = IV(params['iv'] as Uint8List);
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  return Uint8List.fromList(
    encrypter.decryptBytes(Encrypted(encryptedBytes), iv: iv),
  );
}

Uint8List _encryptBytesIsolate(Map<String, dynamic> params) {
  final fileBytes = params['bytes'] as Uint8List;
  final key = Key(params['key'] as Uint8List);
  final iv = IV(params['iv'] as Uint8List);
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  return encrypter.encryptBytes(fileBytes, iv: iv).bytes;
}

class EncryptionService {
  // Secure storage for encryption key
  final _secureStorage = const FlutterSecureStorage();
  static const String _keyStorageKey = 'epub_encryption_key';
  static const String _ivStorageKey = 'epub_encryption_iv';

  // Generate or retrieve encryption key
  Future<Key> _getEncryptionKey() async {
    String? storedKey = await _secureStorage.read(key: _keyStorageKey);

    if (storedKey == null) {
      // Generate new key
      final key = Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: _keyStorageKey,
        value: base64.encode(key.bytes),
      );
      return key;
    }

    return Key(base64.decode(storedKey));
  }

  // Generate or retrieve IV (Initialization Vector)
  Future<IV> _getIV() async {
    String? storedIV = await _secureStorage.read(key: _ivStorageKey);

    if (storedIV == null) {
      // Generate new IV
      final iv = IV.fromSecureRandom(16);
      await _secureStorage.write(
        key: _ivStorageKey,
        value: base64.encode(iv.bytes),
      );
      return iv;
    }

    return IV(base64.decode(storedIV));
  }

  // Encrypt file
  Future<File> encryptFile(File inputFile, String outputPath) async {
    try {
      // Read file bytes
      final Uint8List fileBytes = await inputFile.readAsBytes();

      // Get key and IV
      final key = await _getEncryptionKey();
      final iv = await _getIV();

      // Run CPU-intensive AES encryption in a background isolate so the
      // UI thread is not blocked (especially important for large audio files).
      final encryptedBytes = await compute(_encryptBytesIsolate, {
        'bytes': fileBytes,
        'key': key.bytes,
        'iv': iv.bytes,
      });

      // Write encrypted data to file
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(encryptedBytes);

      return outputFile;
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  // Decrypt file
  Future<Uint8List> decryptFile(File encryptedFile) async {
    try {
      // Read encrypted bytes
      final Uint8List encryptedBytes = await encryptedFile.readAsBytes();

      // Get key and IV
      final key = await _getEncryptionKey();
      final iv = await _getIV();

      // Run CPU-intensive AES decryption in a background isolate so the
      // UI thread is not blocked (especially important for large audio files).
      return await compute(_decryptBytesIsolate, {
        'bytes': encryptedBytes,
        'key': key.bytes,
        'iv': iv.bytes,
      });
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  // Encrypt and save EPUB file
  Future<String> encryptAndSaveEpub(
    Uint8List epubBytes,
    String fileName,
    String storagePath,
  ) async {
    try {
      // Create temporary file for original data
      final tempFile = File('$storagePath/temp_$fileName');
      await tempFile.writeAsBytes(epubBytes);

      // Encrypt file
      final encryptedPath = '$storagePath/$fileName.encrypted';
      await encryptFile(tempFile, encryptedPath);

      // Delete temporary file
      await tempFile.delete();

      return encryptedPath;
    } catch (e) {
      throw Exception('Failed to encrypt and save: $e');
    }
  }

  // Encrypt and save Audio file
  Future<String> encryptAndSaveAudio(
    Uint8List audioBytes,
    String fileName,
    String storagePath,
  ) async {
    try {
      // Create temporary file for original data
      final tempFile = File('$storagePath/temp_$fileName');
      await tempFile.writeAsBytes(audioBytes);

      // Encrypt file
      final encryptedPath = '$storagePath/$fileName.encrypted';
      await encryptFile(tempFile, encryptedPath);

      // Delete temporary file
      await tempFile.delete();

      return encryptedPath;
    } catch (e) {
      throw Exception('Failed to encrypt and save audio: $e');
    }
  }

  // Read and decrypt EPUB file
  Future<Uint8List> readAndDecryptEpub(String encryptedFilePath) async {
    try {
      final encryptedFile = File(encryptedFilePath);

      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted file not found');
      }

      return await decryptFile(encryptedFile);
    } catch (e) {
      throw Exception('Failed to read and decrypt: $e');
    }
  }

  // Read and decrypt Audio file
  Future<Uint8List> readAndDecryptAudio(String encryptedFilePath) async {
    try {
      final encryptedFile = File(encryptedFilePath);

      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted audio file not found');
      }

      return await decryptFile(encryptedFile);
    } catch (e) {
      throw Exception('Failed to read and decrypt audio: $e');
    }
  }

  // Verify file integrity using hash
  Future<String> generateFileHash(Uint8List bytes) async {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Compare file hash for integrity check
  Future<bool> verifyFileIntegrity(
    Uint8List decryptedBytes,
    String originalHash,
  ) async {
    final currentHash = await generateFileHash(decryptedBytes);
    return currentHash == originalHash;
  }

  // Delete encryption keys (use carefully!)
  Future<void> deleteEncryptionKeys() async {
    await _secureStorage.delete(key: _keyStorageKey);
    await _secureStorage.delete(key: _ivStorageKey);
  }

  // Re-encrypt with new key (for key rotation)
  Future<void> reEncryptFile(String filePath) async {
    try {
      // Decrypt with old key
      final decryptedData = await readAndDecryptEpub(filePath);

      // Delete old keys
      await deleteEncryptionKeys();

      // Encrypt with new key
      final tempPath = '$filePath.temp';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(decryptedData);

      await encryptFile(tempFile, filePath);
      await tempFile.delete();
    } catch (e) {
      throw Exception('Re-encryption failed: $e');
    }
  }
}
