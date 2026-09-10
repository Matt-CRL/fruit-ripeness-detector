abstract final class FruitTagIds {
  static const prefix = 'CH-';
  static const minimumDigits = 6;

  static String format(int sequence) {
    if (sequence < 1) {
      throw ArgumentError.value(sequence, 'sequence', 'must be positive');
    }
    return '$prefix${sequence.toString().padLeft(minimumDigits, '0')}';
  }

  static int? parse(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^CH-(\d+)$').firstMatch(value.trim());
    if (match == null) return null;
    final sequence = int.tryParse(match.group(1)!);
    return sequence == null || sequence < 1 ? null : sequence;
  }

  static bool isValid(String? value) => parse(value) != null;
}
