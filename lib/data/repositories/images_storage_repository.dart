import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Update file (delete old and upload new)
  Future<String> updateFile({
    required String businessId,
    required String branchId,
    required String folder,
    required Uint8List newBytes,
    required String fileExtension,
    String? oldFileUrl,
  }) async {
    try {
      // Delete old file if exists
      if (oldFileUrl != null && oldFileUrl.isNotEmpty) {
        await deleteFile(oldFileUrl);
      }

      // Upload new file and return its URL
      final newFileUrl = await uploadFile(
        businessId: businessId,
        branchId: branchId,
        folder: folder,
        bytes: newBytes,
        fileExtension: fileExtension,
      );

      return newFileUrl;
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  // Multi-tenant path structure
  String _getStoragePath({
    required String businessId,
    required String branchId,
    required FileType type,
    required String fileName,
  }) {
    return 'businesses/$businessId/branches/$branchId/${type.folderName}/$fileName';
  }

  // Upload file with bytes
  Future<String> uploadFile({
    required String businessId,
    required String branchId,
    required String folder,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    try {
      final normalizedExtension = fileExtension.trim().toLowerCase();
      // Generate unique filename
      final fileName = '${_uuid.v4()}.$normalizedExtension';
      final path =
          'businesses/$businessId/branches/$branchId/$folder/$fileName';

      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: _getContentType(normalizedExtension)),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // Delete file by URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }
  // Upload file with metadata
  // Future<String> uploadFile({
  //   required String businessId,
  //   required String branchId,
  //   required FileType type,
  //   required String filePath,
  //   required String originalFileName,
  //   Map<String, String>? customMetadata,
  // }) async {
  //   try {
  //     // Generate unique filename
  //     final fileExtension = originalFileName.split('.').last;
  //     final uniqueFileName = '${_uuid.v4()}.$fileExtension';

  //     // Create storage reference
  //     final storageRef = _storage.ref().child(
  //       _getStoragePath(
  //         businessId: businessId,
  //         branchId: branchId,
  //         type: type,
  //         fileName: uniqueFileName,
  //       ),
  //     );

  //     // Prepare metadata
  //     final metadata = SettableMetadata(
  //       contentType: _getContentType(fileExtension),
  //       customMetadata: {
  //         'originalFileName': originalFileName,
  //         'uploadedAt': DateTime.now().toIso8601String(),
  //         'businessId': businessId,
  //         'branchId': branchId,
  //         'fileType': type.name,
  //         ...?customMetadata,
  //       },
  //     );

  //     // Upload file
  //     final uploadTask = storageRef.putFile(File(filePath), metadata);
  //     final snapshot = await uploadTask;

  //     // Get download URL
  //     final downloadUrl = await snapshot.ref.getDownloadURL();
  //     return downloadUrl;
  //   } catch (e) {
  //     throw StorageException('Failed to upload file: $e');
  //   }
  // }

  // // Delete file by URL
  // Future<void> deleteFile(String fileUrl) async {
  //   try {
  //     final ref = _storage.refFromURL(fileUrl);
  //     await ref.delete();
  //   } catch (e) {
  //     throw StorageException('Failed to delete file: $e');
  //   }
  // }

  // Get file metadata
  Future<FullMetadata> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw StorageException('Failed to get file metadata: $e');
    }
  }

  // Check if file exists
  Future<bool> fileExists(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper methods
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}

// File types for multi-tenant organization
enum FileType {
  productImages('product_images'),
  categoryImages('category_images'),
  menuImages('menu_images'),
  userAvatars('user_avatars'),
  restaurantLogos('restaurant_logos'),
  documents('documents');

  const FileType(this.folderName);
  final String folderName;
}

// Custom exceptions
class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
