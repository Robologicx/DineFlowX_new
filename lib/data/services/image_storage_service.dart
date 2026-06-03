import 'dart:io';
import 'dart:typed_data';

import 'package:hotel_management_system/data/repositories/images_storage_repository.dart';

class StorageService {
  final StorageRepository _repository;

  StorageService(this._repository);
  // ---------- INTEGRATED IMAGE PICKING + UPLOAD ----------

  // ---------- PRODUCT IMAGES ----------
  Future<String> uploadProductImage({
    required String businessId,
    required String branchId,
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    return _repository.uploadFile(
      businessId: businessId,
      branchId: branchId,
      folder: 'product_images',
      bytes: imageBytes,
      fileExtension: fileExtension,
    );
  }

  Future<void> deleteProductImage(String imageUrl) async {
    await _repository.deleteFile(imageUrl);
  }

  // ---------- CATEGORY IMAGES ----------
  Future<String> uploadCategoryImage({
    required String businessId,
    required String branchId,
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    return _repository.uploadFile(
      businessId: businessId,
      branchId: branchId,
      folder: 'category_images',
      bytes: imageBytes,
      fileExtension: fileExtension,
    );
  }

  Future<void> deleteCategoryImage(String imageUrl) async {
    await _repository.deleteFile(imageUrl);
  }

  // ---------- MENU IMAGES ----------
  Future<String> uploadMenuImage({
    required String businessId,
    required String branchId,
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    return _repository.uploadFile(
      businessId: businessId,
      branchId: branchId,
      folder: 'menu_images',
      bytes: imageBytes,
      fileExtension: fileExtension,
    );
  }

  Future<void> deleteMenuImage(String imageUrl) async {
    await _repository.deleteFile(imageUrl);
  }

  // ---------- USER AVATARS ----------
  Future<String> uploadUserAvatar({
    required String businessId,
    required String branchId,
    required Uint8List imageBytes,
  }) async {
    return _repository.uploadFile(
      businessId: businessId,
      branchId: branchId,
      folder: 'user_avatars',
      bytes: imageBytes,
      fileExtension: 'jpg',
    );
  }

  Future<void> deleteUserAvatar(String imageUrl) async {
    await _repository.deleteFile(imageUrl);
  }

  // ---------- RESTAURANT LOGOS ----------
  Future<String> uploadRestaurantLogo({
    required String businessId,
    required String branchId,
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    return _repository.uploadFile(
      businessId: businessId,
      branchId: branchId,
      folder: 'restaurant_logos',
      bytes: imageBytes,
      fileExtension: fileExtension,
    );
  }

  Future<void> deleteRestaurantLogo(String imageUrl) async {
    await _repository.deleteFile(imageUrl);
  }

  Future<String> updateRestaurantLogo({
    required String businessId,
    required String branchId,
    required Uint8List imageBytes,
    required String fileExtension,
    String? oldImageUrl,
  }) async {
    return _repository.updateFile(
      businessId: businessId,
      branchId: branchId,
      folder: 'restaurant_logos',
      newBytes: imageBytes,
      fileExtension: fileExtension,
      oldFileUrl: oldImageUrl,
    );
  }

  // ---------- VALIDATION ----------
  bool isValidImageFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  bool isFileSizeValid(File file, {double maxSizeInMB = 10}) {
    final sizeInBytes = file.lengthSync();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    return sizeInMB <= maxSizeInMB;
  }

  // ---------- UTILITIES ----------
  Future<String> getFileSize(String fileUrl) async {
    try {
      final metadata = await _repository.getFileMetadata(fileUrl);
      final sizeInBytes = metadata.size ?? 0;

      if (sizeInBytes < 1024) return '$sizeInBytes B';
      if (sizeInBytes < 1024 * 1024) {
        return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
      }
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<bool> validateFileExists(String fileUrl) async {
    return await _repository.fileExists(fileUrl);
  }

  Future<String> _updateImage({
    required String businessId,
    required String branchId,
    required String folder,
    required Uint8List newImageBytes,
    required String fileExtension,
    String? oldImageUrl,
  }) async {
    return _repository.updateFile(
      businessId: businessId,
      branchId: branchId,
      folder: folder,
      newBytes: newImageBytes,
      fileExtension: fileExtension,
      oldFileUrl: oldImageUrl,
    );
  }
}
