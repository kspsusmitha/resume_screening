import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage from bytes (for web)
  /// Returns the download URL
  Future<String?> uploadFileFromBytes({
    required Uint8List bytes,
    required String fileName,
    String? folder,
  }) async {
    try {
      String storagePath = folder != null ? '$folder/$fileName' : fileName;
      Reference ref = _storage.ref().child(storagePath);
      
      UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: _getContentType(fileName)),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Upload a file to Firebase Storage from file path (for mobile/desktop)
  /// Returns the download URL
  Future<String?> uploadFileFromPath({
    required String path,
    required String fileName,
    String? folder,
  }) async {
    try {
      if (kIsWeb) {
        throw Exception('Use uploadFileFromBytes for web');
      }
      
      String storagePath = folder != null ? '$folder/$fileName' : fileName;
      Reference ref = _storage.ref().child(storagePath);
      
      final file = File(path);
      UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: _getContentType(fileName)),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Upload resume file from bytes (web)
  Future<String?> uploadResumeFromBytes({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    return await uploadFileFromBytes(
      bytes: bytes,
      fileName: fileName,
      folder: 'resumes/$userId',
    );
  }

  /// Upload resume file from path (mobile/desktop)
  Future<String?> uploadResumeFromPath({
    required String userId,
    required String filePath,
    required String fileName,
  }) async {
    return await uploadFileFromPath(
      path: filePath,
      fileName: fileName,
      folder: 'resumes/$userId',
    );
  }

  /// Upload video resume from path (mobile/desktop)
  Future<String?> uploadVideoResumeFromPath({
    required String userId,
    required String filePath,
    required String fileName,
  }) async {
    return await uploadFileFromPath(
      path: filePath,
      fileName: fileName,
      folder: 'video_resumes/$userId',
    );
  }

  /// Upload video from bytes (for web)
  Future<String?> uploadVideoFromBytes({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      String storagePath = 'video_resumes/$userId/$fileName';
      Reference ref = _storage.ref().child(storagePath);
      
      UploadTask uploadTask = ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: 'video/webm'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  /// Download file from Firebase Storage
  Future<String?> downloadFile(String downloadUrl) async {
    try {
      // For web, we can't download directly, but we can open the URL
      if (kIsWeb) {
        return downloadUrl;
      }
      
      // For mobile/desktop, download to local storage
      final ref = _storage.refFromURL(downloadUrl);
      final bytes = await ref.getData();
      
      if (bytes != null) {
        // Save to local file system (mobile/desktop only)
        // This would require path_provider
        return downloadUrl;
      }
      
      return null;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

  /// Delete file from Firebase Storage
  Future<bool> deleteFile(String filePath) async {
    try {
      await _storage.ref().child(filePath).delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Get content type based on file extension
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}
