import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'constants.dart';

class FileHelper {
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase().replaceFirst('.', '');
  }

  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 بايت";
    const suffixes = ["بايت", "كيلوبايت", "ميجابايت", "جيجابايت", "تيرابايت"];
    var i = (log(bytes) / log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  static double getFileSizeInMB(int bytes) {
    return bytes / (1024 * 1024);
  }

  static bool isImageFile(String filePath) {
    return AppConstants.supportedImageTypes.contains(getFileExtension(filePath));
  }

  static bool isDocumentFile(String filePath) {
    return AppConstants.supportedDocumentTypes.contains(getFileExtension(filePath));
  }

  static Future<bool> isFileSizeValid(String filePath, int maxSizeMB) async {
    try {
      final file = File(filePath);
      final sizeInBytes = await file.length();
      final sizeInMB = getFileSizeInMB(sizeInBytes);
      return sizeInMB <= maxSizeMB;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isImageSizeValid(String filePath) async {
    return await isFileSizeValid(filePath, AppConstants.maxImageSizeMB);
  }

  static Future<bool> isDocumentSizeValid(String filePath) async {
    return await isFileSizeValid(filePath, AppConstants.maxDocumentSizeMB);
  }

  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<File?> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        return await sourceFile.copy(destinationPath);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> readFileAsString(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<int>?> readFileAsBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static String getFileTypeDescription(String filePath) {
    final extension = getFileExtension(filePath);
    switch (extension) {
      case 'pdf':
        return 'مستند PDF';
      case 'pptx':
      case 'ppt':
        return 'عرض تقديمي PowerPoint';
      case 'docx':
      case 'doc':
        return 'مستند Word';
      case 'jpg':
      case 'jpeg':
        return 'صورة JPEG';
      case 'png':
        return 'صورة PNG';
      case 'gif':
        return 'صورة GIF';
      case 'bmp':
        return 'صورة BMP';
      default:
        return 'ملف ${extension.toUpperCase()}';
    }
  }

  static String getFileIcon(String filePath) {
    final extension = getFileExtension(filePath);
    switch (extension) {
      case 'pdf':
        return '📄';
      case 'pptx':
      case 'ppt':
        return '📊';
      case 'docx':
      case 'doc':
        return '📝';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return '🖼️';
      default:
        return '📎';
    }
  }

  static bool isValidFileType(String filePath, List<String> allowedTypes) {
    final extension = getFileExtension(filePath);
    return allowedTypes.contains(extension);
  }

  static String sanitizeFileName(String fileName) {
    // Remove invalid characters for file names
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  static Future<Map<String, dynamic>> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود');
      }

      final stats = await file.stat();
      final extension = getFileExtension(filePath);
      
      return {
        'name': getFileName(filePath),
        'nameWithoutExtension': getFileNameWithoutExtension(filePath),
        'extension': extension,
        'path': filePath,
        'size': stats.size,
        'sizeFormatted': formatFileSize(stats.size),
        'sizeMB': getFileSizeInMB(stats.size),
        'type': getFileTypeDescription(filePath),
        'icon': getFileIcon(filePath),
        'isImage': isImageFile(filePath),
        'isDocument': isDocumentFile(filePath),
        'lastModified': stats.modified,
        'lastAccessed': stats.accessed,
        'created': stats.changed,
      };
    } catch (e) {
      throw Exception('فشل في الحصول على معلومات الملف: $e');
    }
  }

  static Future<String> generateUniqueFileName(String originalPath, String directory) async {
    final extension = getFileExtension(originalPath);
    final nameWithoutExt = getFileNameWithoutExtension(originalPath);
    
    int counter = 1;
    String newPath = path.join(directory, '$nameWithoutExt.$extension');
    
    while (await fileExists(newPath)) {
      newPath = path.join(directory, '${nameWithoutExt}_$counter.$extension');
      counter++;
    }
    
    return newPath;
  }

  static Future<List<String>> filterValidFiles(List<String> filePaths, List<String> allowedTypes) async {
    final validFiles = <String>[];
    
    for (final filePath in filePaths) {
      if (await fileExists(filePath) && isValidFileType(filePath, allowedTypes)) {
        validFiles.add(filePath);
      }
    }
    
    return validFiles;
  }

  static String getMimeType(String filePath) {
    final extension = getFileExtension(filePath);
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'doc':
        return 'application/msword';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<bool> isReadableFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      // Try to read a small portion of the file
      await file.openRead(0, 1).first;
      return true;
    } catch (e) {
      return false;
    }
  }
} 