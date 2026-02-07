import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Upload a file to Firebase Storage from bytes (for web)
  /// Returns the download URL
  Future<String?> uploadFileFromBytes({
    required Uint8List bytes,
    required String fileName,
    String? folder,
  }) async {
    try {
      print('Starting uploadFileFromBytes...');
      String storagePath = folder != null ? '$folder/$fileName' : fileName;
      print('Storage Path: $storagePath');

      Reference ref = _storage.ref().child(storagePath);
      print('Reference created.');

      UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: _getContentType(fileName)),
      );

      print('Upload task started...');

      final snapshot = await uploadTask;
      print('Upload completed. State: ${snapshot.state}');

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('Download URL obtained: $downloadUrl');
        return downloadUrl;
      } else {
        print('Upload failed with state: ${snapshot.state}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error uploading file: $e');
      print('Stack trace: $stackTrace');
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
      print('Starting uploadFileFromPath...');
      if (kIsWeb) {
        throw Exception('Use uploadFileFromBytes for web');
      }

      String storagePath = folder != null ? '$folder/$fileName' : fileName;
      print('Storage Path: $storagePath');
      print('Source File Path: $path');

      Reference ref = _storage.ref().child(storagePath);

      final file = File(path);
      if (!await file.exists()) {
        print('Error: File does not exist at path: $path');
        return null;
      }

      UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: _getContentType(fileName)),
      );

      print('Upload task started...');

      final snapshot = await uploadTask;
      print('Upload completed. State: ${snapshot.state}');

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('Download URL obtained: $downloadUrl');
        return downloadUrl;
      } else {
        print('Upload failed with state: ${snapshot.state}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error uploading file: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Upload resume file from bytes (web)
  Future<String?> uploadResumeFromBytes({
    required String userId,
    required String userName,
    required Uint8List bytes,
    required String fileName,
  }) async {
    // Sanitize user name to be safe for folder names
    final safeUserName = userName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    return await uploadFileFromBytes(
      bytes: bytes,
      fileName: fileName,
      folder: 'resumes/$safeUserName',
    );
  }

  /// Upload resume file to Realtime Database (Alternative to Storage)
  /// Returns a custom scheme URI: rtdb://resumes/userId/key
  Future<String?> uploadResumeToRTDB({
    required String userId,
    required String userName,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      print('Starting RTDB upload...');

      // Convert bytes to Base64
      final base64String = base64Encode(bytes);

      // Create a reference path
      final resumeRef = _database.child('resumes').child(userId).push();

      await resumeRef.set({
        'fileName': fileName,
        'content': base64String,
        'uploadedAt': DateTime.now().toIso8601String(),
        'userId': userId,
        'userName': userName,
        'size': bytes.length,
      });

      print('RTDB Upload completed.');

      // Return a custom scheme path
      return 'rtdb://resumes/$userId/${resumeRef.key}';
    } catch (e) {
      print('Error uploading to RTDB: $e');
      return null;
    }
  }

  /// Upload resume from path to RTDB
  Future<String?> uploadResumeToRTDBFromPath({
    required String userId,
    required String userName,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      return await uploadResumeToRTDB(
        userId: userId,
        userName: userName,
        bytes: bytes,
        fileName: fileName,
      );
    } catch (e) {
      print('Error uploading to RTDB from path: $e');
      return null;
    }
  }

  /// Get all resumes for a user from RTDB
  Future<List<Map<String, dynamic>>> getUserResumesFromRTDB(
    String userId,
  ) async {
    try {
      final snapshot = await _database.child('resumes').child(userId).get();

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> resumes = [];

        data.forEach((key, value) {
          final resumeData = Map<String, dynamic>.from(value as Map);
          resumeData['id'] = key; // Add the key as ID
          // Don't include the full content to save memory when listing
          resumeData.remove('content');
          resumes.add(resumeData);
        });

        // Sort by uploadedAt descending
        resumes.sort((a, b) {
          final aDate = DateTime.tryParse(a['uploadedAt'] ?? '') ?? DateTime(0);
          final bDate = DateTime.tryParse(b['uploadedAt'] ?? '') ?? DateTime(0);
          return bDate.compareTo(aDate);
        });

        return resumes;
      }
      return [];
    } catch (e) {
      print('Error fetching user resumes: $e');
      return [];
    }
  }

  /// Retrieve resume data from RTDB
  Future<Map<String, dynamic>?> downloadResumeFromRTDB(String rtdbPath) async {
    try {
      // Parse path: rtdb://resumes/userId/key
      // Remove 'rtdb://' prefix
      final dbPath = rtdbPath.substring(7);

      final snapshot = await _database.child(dbPath).get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final base64String = data['content'] as String;
        final fileName = data['fileName'] as String;

        return {'fileName': fileName, 'bytes': base64Decode(base64String)};
      }
      return null;
    } catch (e) {
      print('Error downloading from RTDB: $e');
      return null;
    }
  }

  /// Upload resume file from path (mobile/desktop)
  Future<String?> uploadResumeFromPath({
    required String userId,
    required String userName,
    required String filePath,
    required String fileName,
  }) async {
    // Sanitize user name to be safe for folder names
    final safeUserName = userName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    return await uploadFileFromPath(
      path: filePath,
      fileName: fileName,
      folder: 'resumes/$safeUserName',
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

  /// Download file from Firebase Storage or RTDB
  Future<dynamic> downloadFile(String pathOrUrl) async {
    try {
      if (pathOrUrl.startsWith('rtdb://')) {
        return await downloadResumeFromRTDB(pathOrUrl);
      }

      // For web, we can't download directly, but we can open the URL
      if (kIsWeb) {
        return pathOrUrl;
      }

      // For mobile/desktop, download to local storage
      final ref = _storage.refFromURL(pathOrUrl);
      final bytes = await ref.getData();

      if (bytes != null) {
        // Save to local file system (mobile/desktop only)
        // This would require path_provider
        return pathOrUrl;
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
