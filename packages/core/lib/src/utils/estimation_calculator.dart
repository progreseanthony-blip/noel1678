import 'package:intl/intl.dart';
import 'schedule_utils.dart';

class EstimationCalculator {
  static Map<String, dynamic> calculate({
    required double topsoilVolume,
    required double compactedVolume,
    required double swellFactor,
    required DateTime startDate,
    required List<Map<String, dynamic>> resources, // { quantity, trips_per_day, capacity_per_trip, performance_per_day }
    bool isAreaBased = false,
    bool isLinearBased = false,
    bool isAcresBased = false,
    double totalArea = 0,
    double totalLength = 0,
    double totalAcres = 0,
    double thicknessInches = 0,
    double gravelThicknessInches = 0,
    double trenchWidthInches = 0,
    double trenchDepthInches = 0,
    Map<String, double> nonWorkingDays = const {},
  }) {
    double totalTarget;
    double totalCYLoose;
    double earthCY = 0;
    double gravelCY = 0;
    double trenchFillCY = 0;

    if (isAcresBased) {
      totalTarget = totalAcres;
      totalCYLoose = 0;
    } else if (isLinearBased) {
      totalTarget = totalLength;
      // Formula for trench excavation: (Length * Width * TotalDepth) / 27
      earthCY = thicknessInches > 0
          ? ((totalLength * (trenchWidthInches / 12) * (thicknessInches / 12)) / 27) * (1 + swellFactor)
          : 0;
      // Formula for trench bedding: (Length * Width * BeddingDepth) / 27
      gravelCY = trenchDepthInches > 0
          ? ((totalLength * (trenchWidthInches / 12) * (trenchDepthInches / 12)) / 27) * (1 + swellFactor)
          : 0;
      
      totalCYLoose = earthCY + gravelCY;
      trenchFillCY = totalCYLoose;
    } else if (isAreaBased) {
      // Area mode: Convert to volume target for machinery trips
      // Earth layer: ((SQFT * earthThickness/12) / 27) * (1 + swell)
      earthCY = thicknessInches > 0
          ? ((totalArea * (thicknessInches / 12)) / 27) * (1 + swellFactor)
          : 0;
      // Gravel layer: ((SQFT * gravelThickness/12) / 27) * (1 + swell)
      gravelCY = gravelThicknessInches > 0
          ? ((totalArea * (gravelThicknessInches / 12)) / 27) * (1 + swellFactor)
          : 0;
      totalCYLoose = earthCY + gravelCY;
      totalTarget = totalCYLoose;
    } else {
      totalCYLoose = (topsoilVolume + compactedVolume) * (1 + swellFactor);
      totalTarget = totalCYLoose;
    }

    double remainingTarget = isAcresBased
        ? totalAcres
        : (isLinearBased ? totalLength : totalCYLoose);
    
    if (remainingTarget <= 0) {
      return {
        'totalCYLoose': totalCYLoose,
        'earthCY': earthCY,
        'gravelCY': gravelCY,
        'trenchFillCY': trenchFillCY,
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
      final contribution = getWorkingDayContribution(currentDate, nonWorkingDays);

      if (contribution > 0) {
        final factor = contribution; // already incorporates Sat/Sun/non-working
        
        for (var res in resources) {
          final type = res['machinery_type']?.toString() ?? 'hauling';
          if (type == 'support') continue;

          final qty = (res['quantity'] as num?)?.toDouble() ?? 0;
          
          if (isLinearBased || isAcresBased) {
            // In Area/Linear/Acre mode, we use performance_per_day (SQFT/Day, LF/Day, or AC/Day)
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
            'contribution': contribution,
            'resources': resources.map((res) {
              final type = res['machinery_type']?.toString() ?? 'hauling';
              final qty = (res['quantity'] as num?)?.toDouble() ?? 0.0;
              
              double dailyOutput;
              double calculatedVolume;

              if (isLinearBased || isAcresBased) {
                final performance = (res['performance_per_day'] as num?)?.toDouble() ?? 0.0;
                dailyOutput = performance * factor * qty;
                // Proportional volume for this machine's production
                final divisor = isAcresBased ? totalAcres : (isAreaBased ? totalArea : totalLength);
                calculatedVolume = divisor > 0 ? (dailyOutput / divisor) * totalCYLoose : 0;
              } else {
                final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0.0;
                final capacity = (res['capacity_per_trip'] as num?)?.toDouble() ?? 0.0;
                dailyOutput = (trips * factor * qty); // trips * qty
                calculatedVolume = dailyOutput * capacity;
              }

              return {
                'name': res['machine_name'] ?? 'Machine',
                'type': type,
                'loads': (isAreaBased || isLinearBased || isAcresBased) ? 0 : dailyOutput, // "loads" only makes sense for hauling
                'production': (isLinearBased || isAcresBased) ? dailyOutput : calculatedVolume,
                'area_production': (isAreaBased && totalCYLoose > 0) ? (calculatedVolume / totalCYLoose) * totalArea : 0,
                'linear_production': isLinearBased ? dailyOutput : 0,
                'acre_production': isAcresBased ? dailyOutput : 0,
              };
            }).toList(),
          });
        }
      } else {
        dailySchedule.add({
            'date': currentDate,
            'production': 0,
            'contribution': 0,
        });
      }

      if (remainingTarget > 0) {
        currentDate = currentDate.add(const Duration(days: 1));
      }
      daysCount++;
    }

    return {
      'totalCYLoose': totalCYLoose,
      'earthCY': earthCY,
      'gravelCY': gravelCY,
      'endDate': currentDate,
      'workingDays': workingDays,
      'dailySchedule': dailySchedule,
    };
  }
}
