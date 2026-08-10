import 'package:uuid/uuid.dart';

abstract final class PersistenceValidation {
  static void entityId(String value, String fieldName) {
    if (!Uuid.isValidUUIDFormat(fromString: value)) {
      throw ArgumentError.value(value, fieldName, 'must be a valid UUID');
    }
  }

  static void optionalEntityId(String? value, String fieldName) {
    if (value != null) {
      entityId(value, fieldName);
    }
  }

  static void nonBlank(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be blank');
    }
  }

  static void utc(DateTime value, String fieldName) {
    if (!value.isUtc) {
      throw ArgumentError.value(value, fieldName, 'must use UTC');
    }
  }

  static void chronological({
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) {
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt must not be before createdAt');
    }
    if (deletedAt != null && deletedAt.isBefore(createdAt)) {
      throw ArgumentError('deletedAt must not be before createdAt');
    }
  }

  static void relativePath(String? value, String fieldName) {
    if (value == null) {
      return;
    }
    nonBlank(value, fieldName);
    final normalized = value.replaceAll('\\', '/');
    final hasDrivePrefix = RegExp(r'^[A-Za-z]:').hasMatch(value);
    final hasParentSegment = normalized.split('/').contains('..');
    if (normalized.startsWith('/') || hasDrivePrefix || hasParentSegment) {
      throw ArgumentError.value(
        value,
        fieldName,
        'must be a relative app-private path',
      );
    }
  }
}
