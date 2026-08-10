import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/scan/application/live_camera.dart';
import 'package:kami/features/scan/application/scan_service_providers.dart';
import 'package:kami/features/scan/data/camera/flutter_live_camera_gateway.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';

final liveCameraGatewayProvider = Provider<LiveCameraGateway>((ref) {
  return const FlutterLiveCameraGateway();
});

final liveScanClassifierProvider = Provider<LiveRipenessClassifier>((ref) {
  return ref.watch(liveRipenessClassifierProvider);
});
