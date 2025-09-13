/// Test configuration constants and settings
class TestConfig {
  /// Default timeout for test operations
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  /// ML processing performance threshold
  static const Duration mlProcessingThreshold = Duration(milliseconds: 100);
  
  /// Camera mode switching performance threshold
  static const Duration cameraSwitchingThreshold = Duration(milliseconds: 200);
  
  /// Supabase sync operation threshold
  static const Duration supabaseSyncThreshold = Duration(seconds: 5);
  
  /// Memory usage threshold for camera sessions (MB)
  static const int memoryUsageThreshold = 100;
  
  /// Maximum simultaneous objects for tracking tests
  static const int maxSimultaneousObjects = 10;
  
  /// Coverage thresholds
  static const double coverageThreshold = 0.85;
  static const double serviceCoverageThreshold = 0.85;
  static const double criticalPathCoverageThreshold = 0.90;
  static const double supabaseIntegrationCoverageThreshold = 0.90;
  static const double cameraMLCoverageThreshold = 0.80;
  
  /// Test environment settings
  static const String testSupabaseUrl = 'https://test.supabase.co';
  static const String testSupabaseKey = 'test-anon-key';
  static const String testGoogleMapsApiKey = 'test-maps-key';
  
  /// Mock data settings
  static const int defaultMockUserCount = 10;
  static const int defaultMockInventoryCount = 50;
  static const int defaultMockBinCount = 20;
  static const int defaultMockDetectionCount = 5;
  
  /// Performance test settings
  static const int performanceTestIterations = 100;
  static const Duration performanceTestWarmupDuration = Duration(seconds: 2);
  
  /// Golden test settings
  static const double goldenTestThreshold = 0.01;
  static const List<String> supportedDeviceSizes = [
    'phone',
    'tablet',
  ];
  
  /// Test data paths
  static const String testImagesPath = 'test/fixtures/test_images';
  static const String goldenFilesPath = 'test/golden/files';
  static const String mockDataPath = 'test/fixtures/mock_data';
  
  /// Camera test settings
  static const Duration cameraInitializationTimeout = Duration(seconds: 10);
  static const Duration mlDetectionTimeout = Duration(seconds: 5);
  static const Duration qrScanTimeout = Duration(seconds: 3);
  
  /// Network simulation settings
  static const Duration networkDelayMin = Duration(milliseconds: 100);
  static const Duration networkDelayMax = Duration(milliseconds: 1000);
  static const double networkFailureRate = 0.1; // 10% failure rate for testing
  
  /// Authentication test settings
  static const String testUserEmail = 'test@cleanclik.com';
  static const String testUserPassword = 'testpassword123';
  static const String testUserUsername = 'testuser';
  static const String testUserFullName = 'Test User';
  
  /// Location test settings
  static const double testLatitude = 37.7749;
  static const double testLongitude = -122.4194;
  static const double binProximityRadius = 10.0; // meters
  static const double locationAccuracy = 5.0; // meters
  
  /// Waste category test data
  static const Map<String, List<String>> wasteCategories = {
    'recycle': ['plastic bottle', 'aluminum can', 'cardboard box'],
    'organic': ['apple core', 'banana peel', 'food scraps'],
    'landfill': ['plastic bag', 'styrofoam', 'mixed waste'],
    'ewaste': ['smartphone', 'laptop', 'battery'],
    'hazardous': ['paint can', 'chemical bottle', 'medical waste'],
  };
  
  /// Points system test data
  static const Map<String, int> categoryPoints = {
    'recycle': 10,
    'organic': 8,
    'landfill': 5,
    'ewaste': 15,
    'hazardous': 20,
  };
  
  /// Achievement test data
  static const List<Map<String, dynamic>> testAchievements = [
    {
      'id': 'first_recycler',
      'title': 'First Recycler',
      'description': 'Recycle your first item',
      'requiredPoints': 10,
      'category': 'recycle',
    },
    {
      'id': 'eco_warrior',
      'title': 'Eco Warrior',
      'description': 'Collect 100 items',
      'requiredPoints': 1000,
      'category': null,
    },
    {
      'id': 'organic_expert',
      'title': 'Organic Expert',
      'description': 'Dispose 50 organic items',
      'requiredPoints': 400,
      'category': 'organic',
    },
  ];
  
  /// Leaderboard test data
  static const int leaderboardPageSize = 20;
  static const Duration leaderboardUpdateInterval = Duration(seconds: 30);
  
  /// Social sharing test data
  static const String testShareText = 'I just cleaned up the city with CleanClik!';
  static const String testShareUrl = 'https://cleanclik.com/share';
  
  /// Deep link test data
  static const String testDeepLinkScheme = 'cleanclik';
  static const String testDeepLinkHost = 'app';
  
  /// Error messages for testing
  static const Map<String, String> errorMessages = {
    'network_error': 'Network connection failed',
    'auth_error': 'Authentication failed',
    'camera_error': 'Camera initialization failed',
    'location_error': 'Location permission denied',
    'ml_error': 'Object detection failed',
    'sync_error': 'Data synchronization failed',
  };
  
  /// Test flags
  static const bool enableVerboseLogging = false;
  static const bool enablePerformanceTracking = true;
  static const bool enableGoldenTestUpdates = false;
  static const bool enableNetworkSimulation = true;
  static const bool enableMemoryTracking = true;
}