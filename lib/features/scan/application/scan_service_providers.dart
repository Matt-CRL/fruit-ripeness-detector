import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/scan/data/shelf_life/literature_shelf_life_advisor.dart';
import 'package:kami/features/scan/data/tflite/tflite_ripeness_classifier.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';

final tfliteRipenessClassifierProvider = Provider<TfliteRipenessClassifier>((
  ref,
) {
  final classifier = TfliteRipenessClassifier();
  ref.onDispose(() => unawaited(classifier.close()));
  return classifier;
});

final ripenessClassifierProvider = Provider<RipenessClassifier>((ref) {
  return ref.watch(tfliteRipenessClassifierProvider);
});

final liveRipenessClassifierProvider = Provider<LiveRipenessClassifier>((ref) {
  return ref.watch(tfliteRipenessClassifierProvider);
});

final shelfLifeAdvisorProvider = Provider<ShelfLifeAdvisor>((ref) {
  return const LiteratureShelfLifeAdvisor();
});
