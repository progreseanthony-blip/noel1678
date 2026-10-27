class ProductionMeasure {
  final String unit;
  final double dailyPlan, today, crewToday, plannedToDate, actualToDate;
  final bool hasPlan;
  const ProductionMeasure(
    this.unit,
    this.dailyPlan,
    this.today,
    this.crewToday,
    this.plannedToDate,
    this.actualToDate, {
    this.hasPlan = true,
  });
}

/// Computes operational progress from one authorized, date-scoped snapshot.
/// Current form values replace this crew's saved values in that snapshot.
class MachineryProgress {
  final Map<String, dynamic> snapshot;
  final List<Map<String, dynamic>> entries;
  MachineryProgress(this.snapshot, this.entries);

  static double number(dynamic value) => (value as num?)?.toDouble() ?? 0;
  static List<Map<String, dynamic>> rows(dynamic value) =>
      (value as List? ?? [])
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
  List<Map<String, dynamic>> get machines => rows(snapshot['machinery']);
  Map<String, dynamic>? find(String id) {
    for (final m in machines) {
      if (m['id'] == id) return m;
    }
    return null;
  }

  DateTime? _date(dynamic value) => value == null
      ? null
      : DateTime.tryParse(value.toString().split('T').first.split(' ').first);
  double weight(DateTime date) {
    if (date.weekday == DateTime.sunday) return 0;
    double ratio = 0;
    for (final row in rows(snapshot['calendar'])) {
      if (_date(row['date']) == date) {
        ratio = number(row['partial_ratio']).clamp(0, 1);
      }
    }
    return (date.weekday == DateTime.saturday ? 0.5 : 1) * (1 - ratio);
  }

  (double, double, bool) _plannedDays(Map<String, dynamic> m) {
    final day = _date(snapshot['date']);
    if (day == null) return (0, 0, false);
    final assignments = rows(m['assignments']);
    if (assignments.isEmpty) {
      if (_date(m['start_date']) == null) return (0, 0, false);
      assignments.add({
        'start_date': m['start_date'],
        'end_date': m['end_date'],
        'quantity': m['expected_quantity'],
      });
    }
    double today = 0, elapsed = 0;
    for (final a in assignments) {
      final start = _date(a['start_date']);
      final end = _date(a['end_date']) ?? day;
      if (start == null || start.isAfter(day)) continue;
      final count = number(a['quantity']);
      if (!day.isAfter(end)) today += weight(day) * count;
      final last = end.isBefore(day) ? end : day;
      for (
        var d = start;
        !d.isAfter(last);
        d = DateTime(d.year, d.month, d.day + 1)
      ) {
        elapsed += weight(d) * count;
      }
    }
    return (today, elapsed, true);
  }

  bool hasPlan(String id) => find(id) != null && _plannedDays(find(id)!).$3;

  List<ProductionMeasure> machine(String id, {String? physicalUnit}) {
    final m = find(id);
    if (m == null) return [];
    final unit = (m['unit'] as String? ?? 'units').toUpperCase();
    final capacity = number(m['capacity_per_trip']);
    final trips = number(m['trips_per_day']);
    final tripBased =
        ['CY', 'FT2', 'SQFT', 'SF'].contains(unit) && capacity > 0 && trips > 0;
    final rate = tripBased ? trips : number(m['performance_per_day']);
    if (rate <= 0) return [];
    final plan = _plannedDays(m);
    final quantity = number(m['expected_quantity']);
    final share = physicalUnit == null
        ? 1.0
        : quantity > 0
        ? 1 / quantity
        : 0.0;
    double before = 0, other = 0, own = 0;
    for (final row in rows(m['actual'])) {
      if (physicalUnit != null && row['unit_id'] != physicalUnit) continue;
      before += number(row['before']);
      if (snapshot['scope'] != 'report') {
        other += number(row['today_other']);
      }
    }
    for (final row in entries) {
      if (row['project_machinery_id'] != id) continue;
      if (physicalUnit != null &&
          row['machinery_inspection_id'] != physicalUnit) {
        continue;
      }
      own += number(row['production_value']);
    }
    ProductionMeasure measure(String label, double factor) => ProductionMeasure(
      label,
      plan.$1 * rate * factor * share,
      (other + own) * factor,
      own * factor,
      plan.$2 * rate * factor * share,
      (before + other + own) * factor,
      hasPlan: plan.$3,
    );
    return [
      measure(tripBased ? 'trips' : unit, 1),
      if (tripBased) measure('CY', capacity),
    ];
  }

  List<ProductionMeasure> service(
    String? serviceId, {
    Set<String> fallbackIds = const {},
  }) {
    final grouped = <String, List<ProductionMeasure>>{};
    for (final m in machines) {
      if (serviceId == null
          ? !fallbackIds.contains(m['id'])
          : m['quote_service_id'] != serviceId) {
        continue;
      }
      for (final value in machine(m['id'] as String)) {
        grouped.putIfAbsent(value.unit, () => []).add(value);
      }
    }
    double sum(
      List<ProductionMeasure> list,
      double Function(ProductionMeasure) f,
    ) => list.fold(0, (value, item) => value + f(item));
    return grouped.entries
        .map(
          (g) => ProductionMeasure(
            g.key,
            sum(g.value, (v) => v.dailyPlan),
            sum(g.value, (v) => v.today),
            sum(g.value, (v) => v.crewToday),
            sum(g.value, (v) => v.plannedToDate),
            sum(g.value, (v) => v.actualToDate),
            hasPlan: g.value.every((v) => v.hasPlan),
          ),
        )
        .toList();
  }
}
