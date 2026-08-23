import 'dart:async';
import 'dart:io';
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
        'The on-device model is no longer available. Restart Chami and try again.',
      );
    }

    try {
      final session = await (_session ??= _createSession());
      final inputContract = session.manifest.input;
      final imageBytes = await File(imagePath).readAsBytes();

      List<double>? u2netAlphaMask;
      if (session.hasU2net) {
        try {
          final u2Input = await Isolate.run(
            () => prepareU2netInput(imageBytes),
            debugName: 'KamiU2netInputPrep',
          );
          u2netAlphaMask = await session.runU2net(u2Input);
        } on Object catch (error) {
          if (kDebugMode) {
            debugPrint('U2-Net background matting skipped: $error');
          }
        }
      }

      final preprocessed = await Isolate.run(
        () => preprocessImageBytes(
          imageBytes,
          inputContract,
          u2netAlphaMask: u2netAlphaMask,
        ),
        debugName: 'KamiImagePreprocessing',
      );

      final output = await session.run(preprocessed.tensorValues);
      final decoded = _outputDecoder.decode(
        logits: output.probabilities,
        manifest: session.manifest,
        isolatedImageBytes: preprocessed.isolatedImageBytes,
      );
      if (!decoded.requiresRetake || output.heatmap == null) {
        return decoded;
      }

      Uint8List? gradCamImageBytes;
      final baseBytes = preprocessed.isolatedImageBytes ?? imageBytes;
      try {
        gradCamImageBytes = await Isolate.run(
          () => generateGradCamOverlay(baseBytes, output.heatmap!),
          debugName: 'KamiGradCamOverlay',
        );
      } on Object catch (e) {
        if (kDebugMode) {
          debugPrint('Grad-CAM overlay generation skipped: $e');
        }
      }

      return _outputDecoder.decode(
        logits: output.probabilities,
        heatmap: output.heatmap,
        manifest: session.manifest,
        isolatedImageBytes: preprocessed.isolatedImageBytes,
        gradCamImageBytes: gradCamImageBytes,
      );
    } on RipenessClassificationException {
      rethrow;
    } on ImagePreprocessingException catch (error) {
      throw RipenessClassificationException(
        'Chami could not prepare that image for assessment. Choose another photo.',
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
        'Chami could not run the on-device model. Restart the app or choose another photo.',
        error,
      );
    }
  }

  @override
  Future<ClassificationResult> classifyFrame(LiveCameraFrame frame) async {
    if (_closed) {
      throw const RipenessClassificationException(
        'The on-device model is no longer available. Restart Chami and try again.',
      );
    }

    try {
      if (frame.targetCrop == null || !frame.targetCrop!.isValid) {
        throw const RipenessClassificationException(
          'The live target frame is not ready. Center the fruit inside the target box and try again.',
        );
      }
      final session = await (_session ??= _createSession());
      final inputContract = session.manifest.input;
      final input = await Isolate.run(
        () => preprocessCameraFrame(frame, inputContract),
        debugName: 'KamiCameraFramePreprocessing',
      );
      final output = await session.run(input);
      return _outputDecoder.decode(
        logits: output.probabilities,
        manifest: session.manifest,
      );
    } on RipenessClassificationException {
      rethrow;
    } on ImagePreprocessingException catch (error) {
      throw RipenessClassificationException(
        'Chami could not prepare the camera frame for assessment.',
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
        'Chami could not run the on-device model for Live Scan.',
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
    Interpreter? u2netInterpreter;
    IsolateInterpreter? isolateInterpreter;
    IsolateInterpreter? u2netIsolateInterpreter;

    try {
      _validateInterpreter(interpreter, manifest);
      isolateInterpreter = await IsolateInterpreter.create(
        address: interpreter.address,
        debugName: 'KamiTfliteInference',
      );

      final aux = manifest.auxiliaryModel;
      if (aux != null) {
        final u2Data = await _assetBundle.load(aux.assetPath);
        final u2Bytes = u2Data.buffer.asUint8List(
          u2Data.offsetInBytes,
          u2Data.lengthInBytes,
        );
        final u2Sha256 = await Isolate.run(
          () => sha256.convert(u2Bytes).toString(),
          debugName: 'KamiU2netChecksum',
        );
        if (u2Sha256 != aux.sha256) {
          throw const ModelContractException(
            'The bundled auxiliary model checksum does not match its manifest.',
          );
        }
        final loadedU2net = Interpreter.fromBuffer(u2Bytes);
        _validateAuxiliaryInterpreter(loadedU2net, aux);
        u2netInterpreter = loadedU2net;
        u2netIsolateInterpreter = await IsolateInterpreter.create(
          address: loadedU2net.address,
          debugName: 'KamiU2netInference',
        );
      }

      return _TfliteModelSession(
        manifest: manifest,
        interpreter: interpreter,
        isolateInterpreter: isolateInterpreter,
        u2netInterpreter: u2netInterpreter,
        u2netIsolateInterpreter: u2netIsolateInterpreter,
      );
    } on Object {
      isolateInterpreter?.close();
      interpreter.close();
      u2netIsolateInterpreter?.close();
      u2netInterpreter?.close();
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
  final heatmapContract = manifest.heatmapOutput;
  final expectedOutputCount = heatmapContract == null ? 1 : 2;
  if (inputs.length != 1 || outputs.length != expectedOutputCount) {
    throw const ModelContractException(
      'The bundled model tensor count does not match its manifest.',
    );
  }

  final input = inputs.single;
  if (input.name != manifest.input.name ||
      !_sameShape(input.shape, manifest.input.shape) ||
      input.type != TensorType.float32) {
    throw const ModelContractException(
      'The bundled model input tensor does not match its manifest.',
    );
  }
  if (manifest.output.index >= outputs.length) {
    throw const ModelContractException(
      'The classification output index is outside the interpreter outputs.',
    );
  }
  final output = outputs[manifest.output.index];
  if (output.name != manifest.output.name ||
      !_sameShape(output.shape, manifest.output.shape) ||
      output.type != TensorType.float32) {
    throw const ModelContractException(
      'The bundled model output tensor does not match its manifest.',
    );
  }
  if (heatmapContract != null) {
    if (heatmapContract.index >= outputs.length) {
      throw const ModelContractException(
        'The heatmap output index is outside the interpreter outputs.',
      );
    }
    final heatmap = outputs[heatmapContract.index];
    if (heatmap.name != heatmapContract.name ||
        !_sameShape(heatmap.shape, heatmapContract.shape) ||
        heatmap.type != TensorType.float32) {
      throw const ModelContractException(
        'The bundled model heatmap tensor does not match its manifest.',
      );
    }
  }
}

void _validateAuxiliaryInterpreter(
  Interpreter interpreter,
  AuxiliaryModelContract contract,
) {
  final inputs = interpreter.getInputTensors();
  final outputs = interpreter.getOutputTensors();
  if (inputs.length != 1 || outputs.length != 1) {
    throw const ModelContractException(
      'The bundled auxiliary model tensor count does not match its manifest.',
    );
  }
  final input = inputs.single;
  final output = outputs.single;
  if (input.type != TensorType.float32 ||
      !_sameShape(input.shape, contract.inputShape) ||
      output.type != TensorType.float32 ||
      !_sameShape(output.shape, contract.outputShape)) {
    throw const ModelContractException(
      'The bundled auxiliary model tensors do not match its manifest.',
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
    this.u2netInterpreter,
    this.u2netIsolateInterpreter,
  });

  final ModelBundleManifest manifest;
  final Interpreter _interpreter;
  final IsolateInterpreter _isolateInterpreter;
  final Interpreter? u2netInterpreter;
  final IsolateInterpreter? u2netIsolateInterpreter;

  bool get hasU2net => u2netIsolateInterpreter != null;

  Future<List<double>> runU2net(Float32List input) async {
    final outputMask = List.generate(
      1,
      (_) => List.generate(
        1,
        (_) => List.generate(
          320,
          (_) => List<double>.filled(320, 0),
        ),
      ),
    );
    await u2netIsolateInterpreter!.runForMultipleInputs(
      [input.buffer],
      {0: outputMask},
    );
    return outputMask[0][0].expand((row) => row).toList(growable: false);
  }

  Future<_TfliteModelOutput> run(Float32List input) async {
    final probabilities = <List<double>>[
      List<double>.filled(manifest.output.orderedLabels.length, 0),
    ];
    final outputs = <int, Object>{manifest.output.index: probabilities};
    List<List<List<List<double>>>>? rawHeatmap;
    final heatmapContract = manifest.heatmapOutput;
    if (heatmapContract != null) {
      rawHeatmap = List.generate(
        1,
        (_) => List.generate(
          1,
          (_) => List.generate(
            heatmapContract.height,
            (_) => List<double>.filled(heatmapContract.width, 0),
          ),
        ),
      );
      outputs[heatmapContract.index] = rawHeatmap;
    }
    await _isolateInterpreter.runForMultipleInputs([input.buffer], outputs);
    final heatmapValues = rawHeatmap
        ?.expand(
          (channel) => channel.expand((row) => row.expand((values) => values)),
        )
        .toList();
    if (heatmapValues != null &&
        heatmapValues.any((value) => !value.isFinite)) {
      throw const ModelContractException(
        'The model produced a non-finite heatmap value.',
      );
    }
    final heatmap = heatmapValues == null
        ? null
        : ActivationHeatmap(
            width: heatmapContract!.width,
            height: heatmapContract.height,
            values: List.unmodifiable(heatmapValues),
          );
    return _TfliteModelOutput(
      probabilities: List<double>.unmodifiable(probabilities.single),
      heatmap: heatmap,
    );
  }

  Future<void> close() async {
    await _isolateInterpreter.close();
    _interpreter.close();
    await u2netIsolateInterpreter?.close();
    u2netInterpreter?.close();
  }
}

final class _TfliteModelOutput {
  const _TfliteModelOutput({required this.probabilities, this.heatmap});

  final List<double> probabilities;
  final ActivationHeatmap? heatmap;
}
