import 'package:uuid/uuid.dart';

abstract interface class EntityIdGenerator {
  String nextId();
}

final class UuidEntityIdGenerator implements EntityIdGenerator {
  const UuidEntityIdGenerator();

  static const _uuid = Uuid();

  @override
  String nextId() => _uuid.v4();
}
