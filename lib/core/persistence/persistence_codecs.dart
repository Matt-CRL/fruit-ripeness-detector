import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/core/persistence/image_sync_state.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

abstract final class PersistenceCodecs {
  static const fruitCodes = <String>{
    'carabao_mango',
    'lakatan_banana',
    'red_papaya',
  };

  static const ripenessCodes = <String>{'unripe', 'ripe', 'overripe'};

  static const resultOriginCodes = <String>{'demo', 'on_device_model'};

  static const syncStateCodes = <String>{
    'local_only',
    'pending',
    'syncing',
    'synchronized',
    'failed',
  };

  static const imageSyncStateCodes = <String>{
    'local_only',
    'pending_upload',
    'uploading',
    'synchronized',
    'remote_only',
    'failed',
  };

  static const orderStatusCodes = <String>{'pending', 'completed'};

  static const shelfLifeAvailable = 'available';
  static const shelfLifeUnavailable = 'unavailable';

  static String encodeFruit(FruitIdentifier value) => switch (value) {
    FruitIdentifier.carabaoMango => 'carabao_mango',
    FruitIdentifier.lakatanBanana => 'lakatan_banana',
    FruitIdentifier.redPapaya => 'red_papaya',
  };

  static FruitIdentifier decodeFruit(String value) => switch (value) {
    'carabao_mango' => FruitIdentifier.carabaoMango,
    'lakatan_banana' => FruitIdentifier.lakatanBanana,
    'red_papaya' => FruitIdentifier.redPapaya,
    _ => throw FormatException('Unknown persisted fruit code: $value'),
  };

  static String encodeRipeness(RipenessStage value) => switch (value) {
    RipenessStage.unripe => 'unripe',
    RipenessStage.ripe => 'ripe',
    RipenessStage.overripe => 'overripe',
  };

  static RipenessStage decodeRipeness(String value) => switch (value) {
    'unripe' => RipenessStage.unripe,
    'ripe' => RipenessStage.ripe,
    'overripe' => RipenessStage.overripe,
    _ => throw FormatException('Unknown persisted ripeness code: $value'),
  };

  static String encodeResultOrigin(ResultOrigin value) => switch (value) {
    ResultOrigin.demo => 'demo',
    ResultOrigin.onDeviceModel => 'on_device_model',
  };

  static ResultOrigin decodeResultOrigin(String value) => switch (value) {
    'demo' => ResultOrigin.demo,
    'on_device_model' => ResultOrigin.onDeviceModel,
    _ => throw FormatException('Unknown persisted result-origin code: $value'),
  };

  static String encodeSyncState(LocalSyncState value) => switch (value) {
    LocalSyncState.localOnly => 'local_only',
    LocalSyncState.pending => 'pending',
    LocalSyncState.syncing => 'syncing',
    LocalSyncState.synchronized => 'synchronized',
    LocalSyncState.failed => 'failed',
  };

  static LocalSyncState decodeSyncState(String value) => switch (value) {
    'local_only' => LocalSyncState.localOnly,
    'pending' => LocalSyncState.pending,
    'syncing' => LocalSyncState.syncing,
    'synchronized' => LocalSyncState.synchronized,
    'failed' => LocalSyncState.failed,
    _ => throw FormatException('Unknown persisted sync-state code: $value'),
  };

  static String encodeImageSyncState(ImageSyncState value) => switch (value) {
    ImageSyncState.localOnly => 'local_only',
    ImageSyncState.pendingUpload => 'pending_upload',
    ImageSyncState.uploading => 'uploading',
    ImageSyncState.synchronized => 'synchronized',
    ImageSyncState.remoteOnly => 'remote_only',
    ImageSyncState.failed => 'failed',
  };

  static ImageSyncState decodeImageSyncState(String value) => switch (value) {
    'local_only' => ImageSyncState.localOnly,
    'pending_upload' => ImageSyncState.pendingUpload,
    'uploading' => ImageSyncState.uploading,
    'synchronized' => ImageSyncState.synchronized,
    'remote_only' => ImageSyncState.remoteOnly,
    'failed' => ImageSyncState.failed,
    _ => throw FormatException('Unsupported image sync state: $value'),
  };

  static String encodeOrderStatus(BatchOrderStatus value) => switch (value) {
    BatchOrderStatus.pending => 'pending',
    BatchOrderStatus.completed => 'completed',
  };

  static BatchOrderStatus decodeOrderStatus(String value) => switch (value) {
    'pending' => BatchOrderStatus.pending,
    'completed' => BatchOrderStatus.completed,
    _ => throw FormatException('Unknown persisted order-status code: $value'),
  };
}
