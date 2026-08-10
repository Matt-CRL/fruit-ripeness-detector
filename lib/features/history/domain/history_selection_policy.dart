import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

/// Describes which bulk actions are safe for the complete History selection.
///
/// History never partially applies an action to a mixed assignment selection:
/// assigned scans must first be corrected from Batch Details.
final class HistorySelectionPolicy {
  const HistorySelectionPolicy._({
    required this.records,
    required this.hasAssignedScan,
    required this.hasMixedFruit,
    required this.hasMixedOwner,
    required this.fruit,
  });

  factory HistorySelectionPolicy.from(Iterable<SavedScanRecord> records) {
    final selected = List<SavedScanRecord>.unmodifiable(records);
    final fruits = selected.map((record) => record.fruit).toSet();
    final owners = selected.map((record) => record.ownerId).toSet();
    return HistorySelectionPolicy._(
      records: selected,
      hasAssignedScan: selected.any((record) => record.batchId != null),
      hasMixedFruit: fruits.length > 1,
      hasMixedOwner: owners.length > 1,
      fruit: fruits.length == 1 ? fruits.single : null,
    );
  }

  final List<SavedScanRecord> records;
  final bool hasAssignedScan;
  final bool hasMixedFruit;
  final bool hasMixedOwner;
  final FruitIdentifier? fruit;

  bool get hasSelection => records.isNotEmpty;

  bool get allUnassigned => hasSelection && !hasAssignedScan;

  bool get canDelete => allUnassigned;

  bool get canAddToBatch => allUnassigned && !hasMixedFruit && !hasMixedOwner;

  String? get guidance {
    if (!hasSelection) {
      return null;
    }
    if (hasAssignedScan) {
      return 'Assigned scans can only be managed from Batch Details.';
    }
    if (hasMixedFruit) {
      return 'Select scans of one fruit type to add them to a batch.';
    }
    if (hasMixedOwner) {
      return 'Select scans from the same local account to add them to a batch.';
    }
    return null;
  }
}
