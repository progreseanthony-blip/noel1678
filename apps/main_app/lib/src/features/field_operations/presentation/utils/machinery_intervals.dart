/// Same-day intervals are half-open: an operation ending at 10:00 allows
/// another one to start at 10:00. Missing times never imply availability.
int? operationSeconds(dynamic value) {
  if (value is! String) return null;
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  final second = parts.length > 2 ? double.tryParse(parts[2]) : 0.0;
  if (hour == null ||
      minute == null ||
      second == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59 ||
      second < 0 ||
      second >= 60)
    return null;
  return hour * 3600 + minute * 60 + second.toInt();
}

bool hasOperationInterval(Map<String, dynamic> row) {
  final start = operationSeconds(row['operation_start']);
  final end = operationSeconds(row['operation_end']);
  return start != null && end != null && end > start;
}

bool machineryIntervalOccupied(
  Map<String, dynamic> candidate,
  Iterable<Map<String, dynamic>> others,
  String field,
  String id,
) {
  return others.any((row) {
    if (identical(row, candidate) || row['is_standby'] == true) return false;
    final same =
        row[field] == id ||
        (field == 'machinery_inspection_id' &&
            row[field] == null &&
            candidate['project_machinery_id'] != null &&
            row['project_machinery_id'] == candidate['project_machinery_id']);
    if (!same) return false;
    // An unfinished or reversed interval cannot establish availability.
    // Reserve the selected resource until both intervals are valid.
    if (!hasOperationInterval(candidate)) return true;
    if (!hasOperationInterval(row)) return true;
    final start = operationSeconds(candidate['operation_start'])!;
    final end = operationSeconds(candidate['operation_end'])!;
    return start < operationSeconds(row['operation_end'])! &&
        operationSeconds(row['operation_start'])! < end;
  });
}

bool operatorAttendanceCovers(
  Map<String, dynamic> entry,
  Iterable<Map<String, dynamic>> labor,
  String worker,
) {
  if (!hasOperationInterval(entry)) return true;
  final start = operationSeconds(entry['operation_start'])!;
  final end = operationSeconds(entry['operation_end'])!;
  return labor.any((row) {
    final arrival = operationSeconds(row['check_in_time']);
    final departure = operationSeconds(row['check_out_time']);
    return row['worker_id'] == worker &&
        arrival != null &&
        departure != null &&
        arrival <= start &&
        departure >= end;
  });
}

String? machineryIntervalError(
  Map<String, dynamic> entry,
  Iterable<Map<String, dynamic>> entries,
  Iterable<Map<String, dynamic>> labor,
) {
  if (entry['is_standby'] == true) return null;
  if (!hasOperationInterval(entry)) {
    return 'Choose a start and end time within the same day.';
  }
  for (final field in ['machinery_inspection_id', 'operator_id']) {
    final id = entry[field] as String?;
    if (id == null) return 'Select the physical unit and operator.';
    if (machineryIntervalOccupied(entry, entries, field, id)) {
      return field == 'operator_id'
          ? 'This operator is already occupied during this interval.'
          : 'This physical unit is already occupied during this interval.';
    }
  }
  if (!operatorAttendanceCovers(entry, labor, entry['operator_id'] as String)) {
    return 'The operator’s attendance in this crew must cover the entire interval.';
  }
  final start = entry['start_meter'] as num?;
  final end = entry['end_meter'] as num?;
  if (start == null || end == null || end < start) {
    return 'Enter valid start and end hour meter readings.';
  }
  final seconds =
      operationSeconds(entry['operation_end'])! -
      operationSeconds(entry['operation_start'])!;
  if (end - start > seconds / 3600) {
    return 'Hour meter usage exceeds the operating interval.';
  }
  return null;
}
