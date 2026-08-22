import 'dart:convert';

const tfliteModelManifestAssetPath =
    'assets/models/fruit_ripeness_v5.manifest.json';

const supportedModelOutputLabels = <String>{
  'unripe-banana',
  'ripe-banana',
  'overripe-banana',
  'unripe-mango',
  'ripe-mango',
  'overripe-mango',
  'unripe-papaya',
  'ripe-papaya',
  'overripe-papaya',
};

const expectedModelOutputLabels = <String>[
  'overripe-banana',
  'overripe-mango',
  'overripe-papaya',
  'ripe-banana',
  'ripe-mango',
  'ripe-papaya',
  'unripe-banana',
  'unripe-mango',
  'unripe-papaya',
];

final class AuxiliaryModelContract {
  const AuxiliaryModelContract({
    required this.assetPath,
    required this.sha256,
    required this.version,
    required this.inputShape,
    required this.outputShape,
  });

  factory AuxiliaryModelContract.fromJson(Map<String, dynamic> json) {
    final assetPath = _requiredString(json, 'assetPath');
    final sha256 = _requiredString(json, 'sha256').toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256)) {
      throw const ModelContractException(
        'The auxiliary model manifest SHA-256 must contain 64 hexadecimal characters.',
      );
    }
    final version = _requiredString(json, 'version');
    final inputShape = _requiredIntList(json, 'inputShape');
    final outputShape = _requiredIntList(json, 'outputShape');
    return AuxiliaryModelContract(
      assetPath: assetPath,
      sha256: sha256,
      version: version,
      inputShape: List.unmodifiable(inputShape),
      outputShape: List.unmodifiable(outputShape),
    );
  }

  final String assetPath;
  final String sha256;
  final String version;
  final List<int> inputShape;
  final List<int> outputShape;
}

final class ModelBundleManifest {
  const ModelBundleManifest({
    required this.modelAssetPath,
    required this.modelSha256,
    required this.modelVersion,
    required this.sourceRepository,
    required this.sourceCommit,
    required this.input,
    required this.output,
    required this.confidencePolicy,
    this.heatmapOutput,
    this.auxiliaryModel,
  });

  factory ModelBundleManifest.fromJsonText(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const ModelContractException(
        'The model manifest root must be a JSON object.',
      );
    }
    return ModelBundleManifest.fromJson(decoded);
  }

  factory ModelBundleManifest.fromJson(Map<String, dynamic> json) {
    final schemaVersion = _requiredInt(json, 'schemaVersion');
    if (schemaVersion != 1 && schemaVersion != 2) {
      throw ModelContractException(
        'Unsupported model manifest schema version $schemaVersion.',
      );
    }
    final model = _requiredMap(json, 'model');
    final auxiliary = json['auxiliaryModel'] is Map<String, dynamic>
        ? AuxiliaryModelContract.fromJson(
            json['auxiliaryModel'] as Map<String, dynamic>,
          )
        : null;
    final input = ModelInputContract.fromJson(_requiredMap(json, 'input'));
    final outputKey = json.containsKey('classificationOutput')
        ? 'classificationOutput'
        : 'output';
    final output = ModelOutputContract.fromJson(
      _requiredMap(json, outputKey),
      defaultIndex: 0,
      allowLogits: true,
    );
    final heatmap = json['heatmapOutput'] is Map<String, dynamic>
        ? ModelHeatmapContract.fromJson(
            json['heatmapOutput'] as Map<String, dynamic>,
          )
        : null;
    if (heatmap != null && heatmap.index == output.index) {
      throw const ModelContractException(
        'Model output tensor indices must be unique.',
      );
    }
    final confidencePolicy = ModelConfidencePolicy.fromJson(
      _requiredMap(json, 'confidencePolicy'),
    );
    final sha256 = _requiredString(model, 'sha256').toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256)) {
      throw const ModelContractException(
        'The model manifest SHA-256 must contain 64 hexadecimal characters.',
      );
    }
    if (output.shape[0] != 1 ||
        output.shape[1] != output.orderedLabels.length) {
      throw const ModelContractException(
        'The model output shape must match the ordered label count.',
      );
    }
    return ModelBundleManifest(
      modelAssetPath: _requiredString(model, 'assetPath'),
      modelSha256: sha256,
      modelVersion: _requiredString(model, 'version'),
      sourceRepository: _requiredString(model, 'sourceRepository'),
      sourceCommit: _requiredString(model, 'sourceCommit'),
      input: input,
      output: output,
      confidencePolicy: confidencePolicy,
      heatmapOutput: heatmap,
      auxiliaryModel: auxiliary,
    );
  }

  final String modelAssetPath;
  final String modelSha256;
  final String modelVersion;
  final String sourceRepository;
  final String sourceCommit;
  final ModelInputContract input;
  final ModelOutputContract output;
  final ModelConfidencePolicy confidencePolicy;
  final ModelHeatmapContract? heatmapOutput;
  final AuxiliaryModelContract? auxiliaryModel;
}

final class ModelInputContract {
  const ModelInputContract({
    required this.name,
    required this.shape,
    required this.dataType,
    required this.pixelScale,
    required this.mean,
    required this.standardDeviation,
    this.squareTransform = 'letterbox_black',
  });

  factory ModelInputContract.fromJson(Map<String, dynamic> json) {
    final shape = _requiredIntList(json, 'shape');
    final mean = _requiredDoubleList(json, 'mean');
    final standardDeviation = _requiredDoubleList(json, 'standardDeviation');
    final pixelScale = _requiredDouble(json, 'pixelScale');
    final isNchw = shape.length == 4 &&
        shape[0] == 1 &&
        shape[1] == 3 &&
        shape[2] > 0 &&
        shape[3] > 0;
    final isNhwc = shape.length == 4 &&
        shape[0] == 1 &&
        shape[1] > 0 &&
        shape[2] > 0 &&
        shape[3] == 3;
    if (!isNchw && !isNhwc) {
      throw const ModelContractException(
        'The model input shape must be [1, height, width, 3] or [1, 3, height, width].',
      );
    }
    if (mean.length != 3 ||
        standardDeviation.length != 3 ||
        standardDeviation.any((value) => value <= 0)) {
      throw const ModelContractException(
        'The model input mean and standard deviation must have three valid channels.',
      );
    }
    final squareTransform = _requiredString(json, 'squareTransform');
    if (pixelScale <= 0 ||
        _requiredString(json, 'dataType') != 'float32' ||
        _requiredString(json, 'colorSpace') != 'rgb' ||
        (squareTransform != 'center_crop' &&
            squareTransform != 'letterbox_black') ||
        _requiredString(json, 'resizeInterpolation') != 'bilinear') {
      throw const ModelContractException(
        'The model input contract contains an unsupported preprocessing mode.',
      );
    }
    return ModelInputContract(
      name: _requiredString(json, 'name'),
      shape: List.unmodifiable(shape),
      dataType: 'float32',
      pixelScale: pixelScale,
      mean: List.unmodifiable(mean),
      standardDeviation: List.unmodifiable(standardDeviation),
      squareTransform: squareTransform,
    );
  }

  final String name;
  final List<int> shape;
  final String dataType;
  final double pixelScale;
  final List<double> mean;
  final List<double> standardDeviation;
  final String squareTransform;

  bool get isNchw => shape.length == 4 && shape[1] == 3;
  int get height => isNchw ? shape[2] : shape[1];
  int get width => isNchw ? shape[3] : shape[2];
}

final class ModelOutputContract {
  const ModelOutputContract({
    required this.index,
    required this.name,
    required this.shape,
    required this.dataType,
    required this.interpretation,
    required this.activation,
    required this.orderedLabels,
  });

  factory ModelOutputContract.fromJson(
    Map<String, dynamic> json, {
    required int defaultIndex,
    required bool allowLogits,
  }) {
    final shape = _requiredIntList(json, 'shape');
    final labels = _requiredStringList(json, 'orderedLabels');
    final interpretation = _requiredString(json, 'interpretation');
    if (shape.length != 2 ||
        shape[0] != 1 ||
        shape[1] <= 0 ||
        labels.toSet().length != labels.length ||
        labels.length != supportedModelOutputLabels.length ||
        !labels.toSet().containsAll(supportedModelOutputLabels) ||
        !_sameStrings(labels, expectedModelOutputLabels)) {
      throw const ModelContractException(
        'The model output labels or shape are invalid.',
      );
    }
    if (_requiredString(json, 'dataType') != 'float32' ||
        (interpretation != 'probabilities' &&
            (!allowLogits || interpretation != 'logits')) ||
        _requiredString(json, 'activation') != 'softmax') {
      throw const ModelContractException(
        'The model output contract contains an unsupported decoding mode.',
      );
    }
    final index = json['index'] == null
        ? defaultIndex
        : _requiredInt(json, 'index');
    if (index < 0) {
      throw const ModelContractException(
        'The model output index must be non-negative.',
      );
    }
    return ModelOutputContract(
      index: index,
      name: _requiredString(json, 'name'),
      shape: List.unmodifiable(shape),
      dataType: 'float32',
      interpretation: interpretation,
      activation: 'softmax',
      orderedLabels: List.unmodifiable(labels),
    );
  }

  final int index;
  final String name;
  final List<int> shape;
  final String dataType;
  final String interpretation;
  final String activation;
  final List<String> orderedLabels;
}

final class ModelHeatmapContract {
  const ModelHeatmapContract({
    required this.index,
    required this.name,
    required this.shape,
    required this.dataType,
  });

  factory ModelHeatmapContract.fromJson(Map<String, dynamic> json) {
    final shape = _requiredIntList(json, 'shape');
    if (shape.length != 4 ||
        shape[0] != 1 ||
        shape[1] != 1 ||
        shape[2] <= 0 ||
        shape[3] <= 0 ||
        _requiredString(json, 'dataType') != 'float32' ||
        _requiredString(json, 'interpretation') != 'activation_map') {
      throw const ModelContractException(
        'The heatmap output contract is invalid.',
      );
    }
    final index = _requiredInt(json, 'index');
    if (index < 0) {
      throw const ModelContractException(
        'The heatmap output index must be non-negative.',
      );
    }
    return ModelHeatmapContract(
      index: index,
      name: _requiredString(json, 'name'),
      shape: List.unmodifiable(shape),
      dataType: 'float32',
    );
  }

  final int index;
  final String name;
  final List<int> shape;
  final String dataType;

  int get height => shape[2];
  int get width => shape[3];
}

final class ModelConfidencePolicy {
  const ModelConfidencePolicy({
    required this.automaticRetakeEnabled,
    required this.threshold,
    required this.reason,
    required this.rejectionMessage,
  });

  factory ModelConfidencePolicy.fromJson(Map<String, dynamic> json) {
    final enabled = _requiredBool(json, 'automaticRetakeEnabled');
    final thresholdValue = json['threshold'];
    final threshold = thresholdValue == null
        ? null
        : _asDouble(thresholdValue, 'threshold');
    if (enabled && threshold == null) {
      throw const ModelContractException(
        'An enabled confidence policy requires a threshold.',
      );
    }
    if (threshold != null && (threshold < 0 || threshold > 1)) {
      throw const ModelContractException(
        'The model confidence threshold must be between zero and one.',
      );
    }
    return ModelConfidencePolicy(
      automaticRetakeEnabled: enabled,
      threshold: threshold,
      reason: _requiredString(json, 'reason'),
      rejectionMessage: json['rejectionMessage'] is String
          ? json['rejectionMessage'] as String
          : 'Fruit not recognized or unclear.',
    );
  }

  final bool automaticRetakeEnabled;
  final double? threshold;
  final String reason;
  final String rejectionMessage;
}

final class ModelContractException implements Exception {
  const ModelContractException(this.message);

  final String message;

  @override
  String toString() => 'ModelContractException: $message';
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) return value;
  throw ModelContractException('The model manifest field "$key" is missing.');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw ModelContractException('The model manifest field "$key" is invalid.');
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw ModelContractException('The model manifest field "$key" is invalid.');
}

double _requiredDouble(Map<String, dynamic> json, String key) =>
    _asDouble(json[key], key);

double _asDouble(Object? value, String key) {
  if (value is num) return value.toDouble();
  throw ModelContractException('The model manifest field "$key" is invalid.');
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw ModelContractException('The model manifest field "$key" is invalid.');
}

List<int> _requiredIntList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List && value.every((element) => element is int)) {
    return value.cast<int>();
  }
  throw ModelContractException('The model manifest field "$key" is invalid.');
}

List<double> _requiredDoubleList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List && value.every((element) => element is num)) {
    return value.cast<num>().map((element) => element.toDouble()).toList();
  }
  throw ModelContractException('The model manifest field "$key" is invalid.');
}

List<String> _requiredStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List &&
      value.isNotEmpty &&
      value.every(
        (element) => element is String && element.trim().isNotEmpty,
      )) {
    return value.cast<String>();
  }
  throw ModelContractException('The model manifest field "$key" is invalid.');
}

bool _sameStrings(List<String> actual, List<String> expected) {
  if (actual.length != expected.length) return false;
  for (var index = 0; index < actual.length; index++) {
    if (actual[index] != expected[index]) return false;
  }
  return true;
}
