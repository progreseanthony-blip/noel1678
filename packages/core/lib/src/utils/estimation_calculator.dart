import 'package:intl/intl.dart';

class EstimationCalculator {
  static Map<String, dynamic> calculate({
    required double topsoilVolume,
    required double compactedVolume,
    required double swellFactor,
    required DateTime startDate,
    required List<Map<String, dynamic>> resources, // { quantity, trips_per_day, capacity_per_trip, performance_per_day }
    bool isAreaBased = false,
    double totalArea = 0,
    double thicknessInches = 0,
  }) {
    double totalTarget;
    double totalCYLoose;

    if (isAreaBased) {
      totalTarget = totalArea;
      // Formula from Excel: ((SQFT * thickness/12) / 27) * (1 + swell)
      totalCYLoose = ((totalArea * (thicknessInches / 12)) / 27) * (1 + swellFactor);
    } else {
      totalCYLoose = (topsoilVolume + compactedVolume) * (1 + swellFactor);
      totalTarget = totalCYLoose;
    }

    double remainingTarget = totalTarget;
    
    if (remainingTarget <= 0) {
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

    while (remainingTarget > 0 && daysCount < maxDays) {
      double dayProduction = 0;
      bool isSaturday = currentDate.weekday == DateTime.saturday;
      bool isSunday = currentDate.weekday == DateTime.sunday;

      if (!isSunday) {
        final factor = isSaturday ? 0.5 : 1.0;
        
        for (var res in resources) {
          final type = res['machinery_type']?.toString() ?? 'hauling';
          if (type == 'support') continue;

          final qty = (res['quantity'] as num?)?.toDouble() ?? 0;
          
          if (isAreaBased) {
            // In Area mode, we use performance_per_day (SQFT/Day)
            final performance = (res['performance_per_day'] as num?)?.toDouble() ?? 0;
            dayProduction += (qty * performance * factor);
          } else {
            // In Volume mode, we use trips * capacity
            final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0;
            final capacity = (res['capacity_per_trip'] as num?)?.toDouble() ?? 0;
            dayProduction += (qty * trips * capacity * factor);
          }
        }

        if (dayProduction > 0) {
          double productionToApply = dayProduction;
          if (productionToApply > remainingTarget) {
            productionToApply = remainingTarget;
          }
          
          remainingTarget -= productionToApply;
          workingDays++;
          
          dailySchedule.add({
            'date': currentDate,
            'production': productionToApply,
            'isSaturday': isSaturday,
            'resources': resources.map((res) {
              final type = res['machinery_type']?.toString() ?? 'hauling';
              final qty = (res['quantity'] as num?)?.toDouble() ?? 0.0;
              
              double dailyOutput;
              double calculatedVolume;

              if (isAreaBased) {
                final performance = (res['performance_per_day'] as num?)?.toDouble() ?? 0.0;
                dailyOutput = performance * factor * qty;
                // Proportional volume for this machine's production
                calculatedVolume = totalArea > 0 ? (dailyOutput / totalArea) * totalCYLoose : 0;
              } else {
                final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0.0;
                final capacity = (res['capacity_per_trip'] as num?)?.toDouble() ?? 0.0;
                dailyOutput = (trips * factor * qty); // trips * qty
                calculatedVolume = dailyOutput * capacity;
              }

              return {
                'name': res['machine_name'] ?? 'Machine',
                'type': type,
                'loads': isAreaBased ? 0 : dailyOutput, // "loads" only makes sense for hauling
                'production': calculatedVolume,
                'area_production': isAreaBased ? dailyOutput : 0,
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

      if (remainingTarget > 0) {
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
