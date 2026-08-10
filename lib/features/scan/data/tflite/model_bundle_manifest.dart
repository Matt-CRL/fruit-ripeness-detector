import 'dart:convert';

const tfliteModelManifestAssetPath =
    'assets/models/mobilenetv4_fruit_float32.manifest.json';

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
    if (schemaVersion != 1) {
      throw ModelContractException(
        'Unsupported model manifest schema version $schemaVersion.',
      );
    }

    final model = _requiredMap(json, 'model');
    final input = ModelInputContract.fromJson(_requiredMap(json, 'input'));
    final output = ModelOutputContract.fromJson(_requiredMap(json, 'output'));
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
}

final class ModelInputContract {
  const ModelInputContract({
    required this.name,
    required this.shape,
    required this.dataType,
    required this.pixelScale,
    required this.mean,
    required this.standardDeviation,
  });

  factory ModelInputContract.fromJson(Map<String, dynamic> json) {
    final shape = _requiredIntList(json, 'shape');
    final mean = _requiredDoubleList(json, 'mean');
    final standardDeviation = _requiredDoubleList(json, 'standardDeviation');
    final pixelScale = _requiredDouble(json, 'pixelScale');

    if (shape.length != 4 ||
        shape[0] != 1 ||
        shape[1] <= 0 ||
        shape[2] <= 0 ||
        shape[3] != 3) {
      throw const ModelContractException(
        'The model input shape must be [1, height, width, 3].',
      );
    }
    if (mean.length != 3 ||
        standardDeviation.length != 3 ||
        standardDeviation.any((value) => value <= 0)) {
      throw const ModelContractException(
        'The model input mean and standard deviation must have three valid channels.',
      );
    }
    if (pixelScale <= 0) {
      throw const ModelContractException(
        'The model input pixel scale must be greater than zero.',
      );
    }
    if (_requiredString(json, 'dataType') != 'float32' ||
        _requiredString(json, 'colorSpace') != 'rgb' ||
        _requiredString(json, 'squareTransform') != 'center_crop' ||
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
    );
  }

  final String name;
  final List<int> shape;
  final String dataType;
  final double pixelScale;
  final List<double> mean;
  final List<double> standardDeviation;

  int get height => shape[1];
  int get width => shape[2];
}

final class ModelOutputContract {
  const ModelOutputContract({
    required this.name,
    required this.shape,
    required this.dataType,
    required this.orderedLabels,
  });

  factory ModelOutputContract.fromJson(Map<String, dynamic> json) {
    final shape = _requiredIntList(json, 'shape');
    final labels = _requiredStringList(json, 'orderedLabels');
    if (shape.length != 2 || shape[0] != 1 || shape[1] <= 0) {
      throw const ModelContractException(
        'The model output shape must be [1, class count].',
      );
    }
    if (labels.toSet().length != labels.length) {
      throw const ModelContractException(
        'The model output labels must be unique.',
      );
    }
    if (labels.length != supportedModelOutputLabels.length ||
        !labels.toSet().containsAll(supportedModelOutputLabels)) {
      throw const ModelContractException(
        'The model output labels must contain every supported fruit and ripeness class exactly once.',
      );
    }
    if (_requiredString(json, 'dataType') != 'float32' ||
        _requiredString(json, 'interpretation') != 'logits' ||
        _requiredString(json, 'activation') != 'softmax') {
      throw const ModelContractException(
        'The model output contract contains an unsupported decoding mode.',
      );
    }

    return ModelOutputContract(
      name: _requiredString(json, 'name'),
      shape: List.unmodifiable(shape),
      dataType: 'float32',
      orderedLabels: List.unmodifiable(labels),
    );
  }

  final String name;
  final List<int> shape;
  final String dataType;
  final List<String> orderedLabels;
}

final class ModelConfidencePolicy {
  const ModelConfidencePolicy({
    required this.automaticRetakeEnabled,
    required this.threshold,
    required this.reason,
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
    );
  }

  final bool automaticRetakeEnabled;
  final double? threshold;
  final String reason;
}

final class ModelContractException implements Exception {
  const ModelContractException(this.message);

  final String message;

  @override
  String toString() => 'ModelContractException: $message';
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) {
    return value;
  }
  throw ModelContractException('The model manifest field "$key" is missing.');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  throw ModelContractException('The model manifest field "$key" is invalid.');
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  throw ModelContractException('The model manifest field "$key" is invalid.');
}

double _requiredDouble(Map<String, dynamic> json, String key) =>
    _asDouble(json[key], key);

double _asDouble(Object? value, String key) {
  if (value is num) {
    return value.toDouble();
  }
  throw ModelContractException('The model manifest field "$key" is invalid.');
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
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
