import 'dart:async';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kami/features/scan/data/tflite/model_bundle_manifest.dart';
import 'package:kami/features/scan/data/tflite/model_output_decoder.dart';
import 'package:kami/features/scan/data/tflite/tflite_image_preprocessor.dart';
import 'package:kami/features/scan/domain/ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

final class TfliteRipenessClassifier
    implements RipenessClassifier, LiveRipenessClassifier {
  TfliteRipenessClassifier({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle,
      _outputDecoder = const ModelOutputDecoder();

  final AssetBundle _assetBundle;
  final ModelOutputDecoder _outputDecoder;

  Future<_TfliteModelSession>? _session;
  bool _closed = false;

  @override
  Future<ClassificationResult> classify(String imagePath) async {
    if (_closed) {
      throw const RipenessClassificationException(
        'The on-device model is no longer available. Restart Kami and try again.',
      );
    }

    try {
      final session = await (_session ??= _createSession());
      final inputContract = session.manifest.input;
      final input = await Isolate.run(
        () => preprocessImageFile(imagePath, inputContract),
        debugName: 'KamiImagePreprocessing',
      );
      final logits = await session.run(input);
      return _outputDecoder.decode(logits: logits, manifest: session.manifest);
    } on RipenessClassificationException {
      rethrow;
    } on ImagePreprocessingException catch (error) {
      throw RipenessClassificationException(
        'Kami could not prepare that image for assessment. Choose another photo.',
        error,
      );
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'On-device classification failed: ${error.runtimeType}: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      throw RipenessClassificationException(
        'Kami could not run the on-device model. Restart the app or choose another photo.',
        error,
      );
    }
  }

  @override
  Future<ClassificationResult> classifyFrame(LiveCameraFrame frame) async {
    if (_closed) {
      throw const RipenessClassificationException(
        'The on-device model is no longer available. Restart Kami and try again.',
      );
    }

    try {
      final session = await (_session ??= _createSession());
      final inputContract = session.manifest.input;
      final input = await Isolate.run(
        () => preprocessCameraFrame(frame, inputContract),
        debugName: 'KamiCameraFramePreprocessing',
      );
      final logits = await session.run(input);
      return _outputDecoder.decode(logits: logits, manifest: session.manifest);
    } on RipenessClassificationException {
      rethrow;
    } on ImagePreprocessingException catch (error) {
      throw RipenessClassificationException(
        'Kami could not prepare the camera frame for assessment.',
        error,
      );
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Live on-device classification failed: ${error.runtimeType}: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      throw RipenessClassificationException(
        'Kami could not run the on-device model for Live Scan.',
        error,
      );
    }
  }

  Future<_TfliteModelSession> _createSession() async {
    final manifestText = await _assetBundle.loadString(
      tfliteModelManifestAssetPath,
    );
    final manifest = ModelBundleManifest.fromJsonText(manifestText);
    final modelData = await _assetBundle.load(manifest.modelAssetPath);
    final modelBytes = modelData.buffer.asUint8List(
      modelData.offsetInBytes,
      modelData.lengthInBytes,
    );
    final actualSha256 = await Isolate.run(
      () => sha256.convert(modelBytes).toString(),
      debugName: 'KamiModelChecksum',
    );
    if (actualSha256 != manifest.modelSha256) {
      throw const ModelContractException(
        'The bundled model checksum does not match its manifest.',
      );
    }

    final interpreter = Interpreter.fromBuffer(modelBytes);
    try {
      _validateInterpreter(interpreter, manifest);
      final isolateInterpreter = await IsolateInterpreter.create(
        address: interpreter.address,
        debugName: 'KamiTfliteInference',
      );
      return _TfliteModelSession(
        manifest: manifest,
        interpreter: interpreter,
        isolateInterpreter: isolateInterpreter,
      );
    } on Object {
      interpreter.close();
      rethrow;
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    final session = _session;
    if (session == null) {
      return;
    }
    try {
      await (await session).close();
    } on Object {
      // Disposal is best effort during application shutdown.
    }
  }
}

void _validateInterpreter(
  Interpreter interpreter,
  ModelBundleManifest manifest,
) {
  final inputs = interpreter.getInputTensors();
  final outputs = interpreter.getOutputTensors();
  if (inputs.length != 1 || outputs.length != 1) {
    throw const ModelContractException(
      'The bundled model must have exactly one input and one output.',
    );
  }

  final input = inputs.single;
  final output = outputs.single;
  if (input.name != manifest.input.name ||
      !_sameShape(input.shape, manifest.input.shape) ||
      input.type != TensorType.float32) {
    throw const ModelContractException(
      'The bundled model input tensor does not match its manifest.',
    );
  }
  if (output.name != manifest.output.name ||
      !_sameShape(output.shape, manifest.output.shape) ||
      output.type != TensorType.float32) {
    throw const ModelContractException(
      'The bundled model output tensor does not match its manifest.',
    );
  }
}

bool _sameShape(List<int> actual, List<int> expected) {
  if (actual.length != expected.length) {
    return false;
  }
  for (var index = 0; index < actual.length; index++) {
    if (actual[index] != expected[index]) {
      return false;
    }
  }
  return true;
}

final class _TfliteModelSession {
  _TfliteModelSession({
    required this.manifest,
    required this._interpreter,
    required this._isolateInterpreter,
  });

  final ModelBundleManifest manifest;
  final Interpreter _interpreter;
  final IsolateInterpreter _isolateInterpreter;

  Future<List<double>> run(Float32List input) async {
    final output = <List<double>>[
      List<double>.filled(manifest.output.orderedLabels.length, 0),
    ];
    await _isolateInterpreter.run(input.buffer, output);
    return List<double>.unmodifiable(output.single);
  }

  Future<void> close() async {
    await _isolateInterpreter.close();
    _interpreter.close();
  }
}
