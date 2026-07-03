double getWorkingDayContribution(DateTime date, Map<String, double> nonWorkingDays) {
  final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final nwRatio = nonWorkingDays[key] ?? 0;
  if (nwRatio >= 1.0) return 0;
  if (date.weekday == DateTime.sunday) return 0;
  final base = date.weekday == DateTime.saturday ? 0.5 : 1.0;
  return base * (1.0 - nwRatio);
}
