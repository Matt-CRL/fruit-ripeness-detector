import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/saved_scan_query.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

enum HistoryDateFilterKind {
  all,
  today,
  lastSevenDays,
  lastThirtyDays,
  specificDate,
  dateRange,
}

enum HistorySortOrder { newestFirst, oldestFirst }

final class HistoryFilters {
  const HistoryFilters({
    this.fruit,
    this.ripeness,
    this.inBatch,
    this.dateKind = HistoryDateFilterKind.all,
    this.sortOrder = HistorySortOrder.newestFirst,
    this.specificDate,
    this.rangeStart,
    this.rangeEnd,
  });

  final FruitIdentifier? fruit;
  final RipenessStage? ripeness;
  final bool? inBatch;
  final HistoryDateFilterKind dateKind;
  final HistorySortOrder sortOrder;
  final DateTime? specificDate;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  int get activeCount =>
      (fruit == null ? 0 : 1) +
      (ripeness == null ? 0 : 1) +
      (inBatch == null ? 0 : 1) +
      (dateKind == HistoryDateFilterKind.all ? 0 : 1) +
      (sortOrder == HistorySortOrder.newestFirst ? 0 : 1);

  SavedScanQuery toSavedScanQuery({DateTime? now}) {
    final bounds = _dateBounds(now: now);
    return SavedScanQuery(
      fruit: fruit,
      ripeness: ripeness,
      inBatch: inBatch,
      createdFromUtc: bounds?.start.toUtc(),
      createdUntilUtc: bounds?.end.toUtc(),
      sortOrder: sortOrder == HistorySortOrder.newestFirst
          ? SavedScanSortOrder.newestFirst
          : SavedScanSortOrder.oldestFirst,
    );
  }

  List<SavedScanRecord> apply(
    Iterable<SavedScanRecord> records, {
    DateTime? now,
  }) {
    final filtered = records.where((record) {
      if (fruit != null && record.fruit != fruit) {
        return false;
      }
      if (ripeness != null && record.ripeness != ripeness) {
        return false;
      }
      if (inBatch != null && (record.batchId != null) != inBatch) {
        return false;
      }
      return _matchesDate(record.createdAt, now: now);
    }).toList();

    filtered.sort((left, right) {
      final comparison = left.createdAt.compareTo(right.createdAt);
      return sortOrder == HistorySortOrder.newestFirst
          ? -comparison
          : comparison;
    });
    return filtered;
  }

  bool _matchesDate(DateTime createdAt, {DateTime? now}) {
    if (dateKind == HistoryDateFilterKind.all) {
      return true;
    }

    final localCreated = createdAt.toLocal();
    final createdDay = _day(localCreated);
    final currentDay = _day(now ?? DateTime.now());

    late final DateTime start;
    late final DateTime end;
    switch (dateKind) {
      case HistoryDateFilterKind.all:
        return true;
      case HistoryDateFilterKind.today:
        start = currentDay;
        end = start.add(const Duration(days: 1));
      case HistoryDateFilterKind.lastSevenDays:
        end = currentDay.add(const Duration(days: 1));
        start = currentDay.subtract(const Duration(days: 6));
      case HistoryDateFilterKind.lastThirtyDays:
        end = currentDay.add(const Duration(days: 1));
        start = currentDay.subtract(const Duration(days: 29));
      case HistoryDateFilterKind.specificDate:
        final selected = specificDate;
        if (selected == null) {
          return true;
        }
        start = _day(selected);
        end = start.add(const Duration(days: 1));
      case HistoryDateFilterKind.dateRange:
        final selectedStart = rangeStart;
        final selectedEnd = rangeEnd;
        if (selectedStart == null || selectedEnd == null) {
          return true;
        }
        start = _day(selectedStart);
        end = _day(selectedEnd).add(const Duration(days: 1));
    }

    return !createdDay.isBefore(start) && createdDay.isBefore(end);
  }

  ({DateTime start, DateTime end})? _dateBounds({DateTime? now}) {
    if (dateKind == HistoryDateFilterKind.all) {
      return null;
    }

    final currentDay = _day(now ?? DateTime.now());
    late final DateTime start;
    late final DateTime end;
    switch (dateKind) {
      case HistoryDateFilterKind.all:
        return null;
      case HistoryDateFilterKind.today:
        start = currentDay;
        end = start.add(const Duration(days: 1));
      case HistoryDateFilterKind.lastSevenDays:
        end = currentDay.add(const Duration(days: 1));
        start = currentDay.subtract(const Duration(days: 6));
      case HistoryDateFilterKind.lastThirtyDays:
        end = currentDay.add(const Duration(days: 1));
        start = currentDay.subtract(const Duration(days: 29));
      case HistoryDateFilterKind.specificDate:
        final selected = specificDate;
        if (selected == null) return null;
        start = _day(selected);
        end = start.add(const Duration(days: 1));
      case HistoryDateFilterKind.dateRange:
        final selectedStart = rangeStart;
        final selectedEnd = rangeEnd;
        if (selectedStart == null || selectedEnd == null) return null;
        start = _day(selectedStart);
        end = _day(selectedEnd).add(const Duration(days: 1));
    }
    return (start: start, end: end);
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
