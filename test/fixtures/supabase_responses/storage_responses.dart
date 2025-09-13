/// Mock Supabase storage responses for testing
class StorageResponses {
  /// Mock successful file upload response
  static Map<String, dynamic> createUploadResponse({
    required String fileName,
    required String bucketId,
    int? fileSize,
  }) {
    return {
      'Key': '$bucketId/$fileName',
      'id': 'file-${DateTime.now().millisecondsSinceEpoch}',
      'fullPath': '$bucketId/$fileName',
      'path': fileName,
      'bucketId': bucketId,
      'size': fileSize ?? 1024000, // 1MB default
      'mimeType': _getMimeType(fileName),
      'uploadedAt': DateTime.now().toIso8601String(),
      'lastAccessedAt': DateTime.now().toIso8601String(),
      'metadata': {
        'uploadedBy': 'test-user-id',
        'originalName': fileName,
        'cacheControl': '3600',
      },
    };
  }

  /// Mock file download response
  static List<int> createDownloadResponse({
    int size = 1024000, // 1MB default
  }) {
    // Return mock binary data
    return List.generate(size, (index) => index % 256);
  }

  /// Mock file list response
  static List<Map<String, dynamic>> createListResponse({
    required String bucketId,
    int count = 10,
  }) {
    return List.generate(count, (index) => {
      'name': 'file-$index.jpg',
      'id': 'file-id-$index',
      'size': 1024000 + (index * 100000),
      'mimeType': 'image/jpeg',
      'createdAt': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
      'updatedAt': DateTime.now().subtract(Duration(hours: index)).toIso8601String(),
      'lastAccessedAt': DateTime.now().subtract(Duration(minutes: index * 10)).toIso8601String(),
      'metadata': {
        'uploadedBy': 'user-${index % 3}',
        'category': ['recycle', 'organic', 'landfill'][index % 3],
        'processed': index % 2 == 0,
      },
    });
  }

  /// Mock file deletion response
  static Map<String, dynamic> createDeleteResponse({
    required String fileName,
    required String bucketId,
  }) {
    return {
      'message': 'File deleted successfully',
      'path': '$bucketId/$fileName',
      'deletedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Mock file move/copy response
  static Map<String, dynamic> createMoveResponse({
    required String fromPath,
    required String toPath,
    required String bucketId,
  }) {
    return {
      'message': 'File moved successfully',
      'fromPath': '$bucketId/$fromPath',
      'toPath': '$bucketId/$toPath',
      'movedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Mock signed URL response
  static Map<String, dynamic> createSignedUrlResponse({
    required String fileName,
    required String bucketId,
    int expiresIn = 3600,
  }) {
    return {
      'signedUrl': 'https://test.supabase.co/storage/v1/object/sign/$bucketId/$fileName?token=mock-signed-token',
      'path': '$bucketId/$fileName',
      'expiresIn': expiresIn,
      'expiresAt': DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String(),
    };
  }

  /// Mock bucket operations responses
  static Map<String, dynamic> createBucketResponses() {
    return {
      'list_buckets': [
        {
          'id': 'user-uploads',
          'name': 'user-uploads',
          'public': false,
          'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'allowedMimeTypes': ['image/jpeg', 'image/png', 'image/webp'],
          'fileSizeLimit': 10485760, // 10MB
        },
        {
          'id': 'public-assets',
          'name': 'public-assets',
          'public': true,
          'createdAt': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'allowedMimeTypes': null,
          'fileSizeLimit': null,
        },
      ],
      'create_bucket': {
        'name': 'test-bucket',
        'id': 'test-bucket',
        'public': false,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      'delete_bucket': {
        'message': 'Bucket deleted successfully',
        'name': 'test-bucket',
        'deletedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Mock image processing responses
  static Map<String, dynamic> createImageProcessingResponses() {
    return {
      'resize_image': createUploadResponse(
        fileName: 'resized-image.jpg',
        bucketId: 'processed-images',
        fileSize: 512000, // Smaller after resize
      ),
      'compress_image': createUploadResponse(
        fileName: 'compressed-image.jpg',
        bucketId: 'processed-images',
        fileSize: 256000, // Smaller after compression
      ),
      'generate_thumbnail': createUploadResponse(
        fileName: 'thumbnail.jpg',
        bucketId: 'thumbnails',
        fileSize: 50000, // Small thumbnail
      ),
    };
  }

  /// Mock storage analytics responses
  static Map<String, dynamic> createStorageAnalyticsResponses() {
    return {
      'bucket_usage': {
        'bucketId': 'user-uploads',
        'totalFiles': 1250,
        'totalSize': 5368709120, // 5GB
        'averageFileSize': 4294967, // ~4MB
        'fileTypes': {
          'image/jpeg': 800,
          'image/png': 350,
          'image/webp': 100,
        },
        'uploadTrends': List.generate(30, (day) => {
          'date': DateTime.now().subtract(Duration(days: day)).toIso8601String().split('T')[0],
          'uploads': 20 + (day % 10),
          'totalSize': 83886080 + (day * 1048576), // ~80MB + day*1MB
        }),
        'generatedAt': DateTime.now().toIso8601String(),
      },
      'user_storage_usage': {
        'userId': 'test-user-id',
        'totalFiles': 45,
        'totalSize': 188743680, // ~180MB
        'quotaUsed': 0.18, // 18% of 1GB quota
        'remainingQuota': 859832320, // ~820MB remaining
        'fileBreakdown': {
          'images': 40,
          'documents': 3,
          'videos': 2,
        },
        'recentUploads': List.generate(5, (index) => {
          'fileName': 'recent-file-$index.jpg',
          'size': 4194304, // 4MB
          'uploadedAt': DateTime.now().subtract(Duration(hours: index)).toIso8601String(),
        }),
      },
    };
  }

  /// Mock storage errors
  static Map<String, StorageException> getCommonStorageErrors() {
    return {
      'file_not_found': StorageException(
        'File not found',
        statusCode: '404',
      ),
      'insufficient_permissions': StorageException(
        'Insufficient permissions to access file',
        statusCode: '403',
      ),
      'file_too_large': StorageException(
        'File size exceeds maximum allowed size',
        statusCode: '413',
      ),
      'invalid_file_type': StorageException(
        'File type not allowed',
        statusCode: '415',
      ),
      'quota_exceeded': StorageException(
        'Storage quota exceeded',
        statusCode: '507',
      ),
      'upload_failed': StorageException(
        'File upload failed',
        statusCode: '500',
      ),
      'network_error': StorageException(
        'Network connection failed',
        statusCode: '0',
      ),
    };
  }

  /// Mock batch upload responses
  static Map<String, dynamic> createBatchUploadResponse({
    required List<String> fileNames,
    required String bucketId,
  }) {
    return {
      'batchId': 'batch-${DateTime.now().millisecondsSinceEpoch}',
      'totalFiles': fileNames.length,
      'successful': fileNames.map((fileName) => createUploadResponse(
        fileName: fileName,
        bucketId: bucketId,
      )).toList(),
      'failed': <Map<String, dynamic>>[], // No failures in mock
      'startedAt': DateTime.now().subtract(const Duration(seconds: 30)).toIso8601String(),
      'completedAt': DateTime.now().toIso8601String(),
      'totalSize': fileNames.length * 1024000, // 1MB per file
    };
  }

  /// Mock file metadata responses
  static Map<String, dynamic> createFileMetadataResponse({
    required String fileName,
    required String bucketId,
  }) {
    return {
      'name': fileName,
      'id': 'file-${DateTime.now().millisecondsSinceEpoch}',
      'size': 1024000,
      'mimeType': _getMimeType(fileName),
      'bucketId': bucketId,
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'updatedAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      'lastAccessedAt': DateTime.now().toIso8601String(),
      'metadata': {
        'uploadedBy': 'test-user-id',
        'originalName': fileName,
        'category': 'recycle',
        'processed': true,
        'thumbnailGenerated': true,
        'virusScanStatus': 'clean',
        'contentHash': 'sha256:mock-hash-${DateTime.now().millisecondsSinceEpoch}',
      },
      'customMetadata': {
        'description': 'Test image for unit testing',
        'tags': ['test', 'mock', 'recycle'],
        'location': {
          'latitude': 37.7749,
          'longitude': -122.4194,
        },
      },
    };
  }

  /// Mock storage configuration responses
  static Map<String, dynamic> createStorageConfigResponse() {
    return {
      'maxFileSize': 10485760, // 10MB
      'allowedMimeTypes': [
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/gif',
        'video/mp4',
        'video/quicktime',
      ],
      'buckets': {
        'user-uploads': {
          'public': false,
          'maxFileSize': 10485760,
          'allowedMimeTypes': ['image/jpeg', 'image/png', 'image/webp'],
        },
        'public-assets': {
          'public': true,
          'maxFileSize': 52428800, // 50MB
          'allowedMimeTypes': null,
        },
      },
      'quotas': {
        'perUser': 1073741824, // 1GB
        'perBucket': 107374182400, // 100GB
      },
      'features': {
        'imageProcessing': true,
        'videoProcessing': false,
        'virusScanning': true,
        'contentDeduplication': true,
      },
    };
  }

  /// Helper method to determine MIME type from file extension
  static String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Mock storage exception for error testing
class StorageException implements Exception {
  final String message;
  final String? statusCode;
  final Map<String, dynamic>? error;

  const StorageException(
    this.message, {
    this.statusCode,
    this.error,
  });

  @override
  String toString() => 'StorageException: $message';
}