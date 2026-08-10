import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/database/app_database.dart';
import 'package:kami/core/persistence/entity_id_generator.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();
  ref.onDispose(database.close);
  return database;
});

final entityIdGeneratorProvider = Provider<EntityIdGenerator>((ref) {
  return const UuidEntityIdGenerator();
});
