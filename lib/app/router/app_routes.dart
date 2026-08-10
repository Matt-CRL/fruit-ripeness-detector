abstract final class AppRoutes {
  static const root = '/';
  static const onboarding = '/onboarding';
  static const accountChoice = '/account-choice';
  static const signIn = '/sign-in';
  static const createAccount = '/create-account';
  static const home = '/home';
  static const batches = '/batches';
  static const batchCreate = '/batches/new';
  static const scan = '/scan';
  static const scanLive = '/scan/live';
  static const scanUpload = '/scan/upload';
  static const scanResult = '/scan/result';
  static const scanRetake = '/scan/retake';
  static const history = '/history';
  static const profile = '/profile';
  static const shelfLifePreview = '/shelf-life-preview';
  static const addMultipleScansToBatch = '/saved-scans/add-to-batch';
  static const batchCreateForScans = '/batches/new-for-scans';

  static String batchDetails(String batchId) => '/batches/$batchId';

  static String batchScans(String batchId) => '/batches/$batchId/scans';

  static String batchAddScans(String batchId) => '/batches/$batchId/add-scans';

  static String batchCreateForScan(String scanId) =>
      '$batchCreate?scanId=$scanId';

  static String batchOrder(String batchId) => '/batches/$batchId/order';

  static String historyDetails(String scanId) => '/history/$scanId';

  /// Opens a saved scan without mounting the main shell again. Use this when
  /// navigating from a top-level workflow such as batch details.
  static String savedScanDetails(
    String scanId, {
    bool fromAddScans = false,
    bool fromBatchScans = false,
  }) {
    final path = '/saved-scans/$scanId';
    final context = fromAddScans
        ? 'add-scans'
        : fromBatchScans
        ? 'batch-scans'
        : null;
    return context == null ? path : '$path?context=$context';
  }

  static String addToBatch(String scanId) =>
      '/saved-scans/$scanId/add-to-batch';

  static String moveToBatch(String scanId) =>
      '/saved-scans/$scanId/move-to-batch';
}
