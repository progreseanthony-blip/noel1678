import 'package:intl/intl.dart';

class EstimationCalculator {
  static Map<String, dynamic> calculate({
    required double topsoilVolume,
    required double compactedVolume,
    required double swellFactor,
    required DateTime startDate,
    required List<Map<String, dynamic>> resources, // { quantity, trips_per_day, capacity_per_trip }
  }) {
    final totalCYLoose = (topsoilVolume + compactedVolume) * (1 + swellFactor);
    double remainingVolume = totalCYLoose;
    
    if (remainingVolume <= 0) {
      return {
        'totalCYLoose': totalCYLoose,
        'endDate': startDate,
        'workingDays': 0,
        'dailySchedule': [],
      };
    }

    DateTime currentDate = startDate;
    int workingDays = 0;
    List<Map<String, dynamic>> dailySchedule = [];

    // Safety break to prevent infinite loops
    int maxDays = 3650; // 10 years
    int daysCount = 0;

    while (remainingVolume > 0 && daysCount < maxDays) {
      double dayProduction = 0;
      bool isSaturday = currentDate.weekday == DateTime.saturday;
      bool isSunday = currentDate.weekday == DateTime.sunday;

      if (!isSunday) {
        final factor = isSaturday ? 0.5 : 1.0;
        
        for (var res in resources) {
          final qty = (res['quantity'] as num?)?.toDouble() ?? 0;
          final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0;
          final capacity = (res['capacity_per_trip'] as num?)?.toDouble() ?? 0;
          dayProduction += (qty * trips * capacity * factor);
        }

        if (dayProduction > 0) {
          double productionToApply = dayProduction;
          if (productionToApply > remainingVolume) {
            productionToApply = remainingVolume;
          }
          
          remainingVolume -= productionToApply;
          workingDays++;
          
          dailySchedule.add({
            'date': currentDate,
            'production': productionToApply,
            'isSaturday': isSaturday,
            'resources': resources.map((res) {
              final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0.0;
              final qty = (res['quantity'] as num?)?.toDouble() ?? 0.0;
              return {
                'name': res['machine_name'] ?? 'Machine',
                'loads': (trips * factor * qty),
              };
            }).toList(),
          });
        }
      } else {
        // Sunday - No production
        dailySchedule.add({
            'date': currentDate,
            'production': 0,
            'isSunday': true,
        });
      }

      if (remainingVolume > 0) {
        currentDate = currentDate.add(const Duration(days: 1));
      }
      daysCount++;
    }

    return {
      'totalCYLoose': totalCYLoose,
      'endDate': currentDate,
      'workingDays': workingDays,
      'dailySchedule': dailySchedule,
    };
  }
}
