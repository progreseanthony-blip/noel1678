import 'dart:math' as math;

bool isVolumeUnit(String unit) {
  final u = unit.toLowerCase();
  return u == 'cy' || u == 'ft2' || u == 'sqft' || u == 'sf';
}

double computeEffectiveProduction(double productionValue, double capacityYards, String unit) {
  if (isVolumeUnit(unit) && capacityYards > 0) {
    return productionValue * capacityYards;
  }
  return productionValue;
}

double computeProgress(double actual, double planned) {
  if (planned <= 0) return 0.0;
  return (actual / planned * 100).clamp(0.0, 100.0);
}

double computeCPI(double earnedValue, double actualCost) {
  if (actualCost <= 0) return 1.0;
  return earnedValue / actualCost;
}

double computeSPI(double earnedValue, double plannedValue) {
  if (plannedValue <= 0) return 1.0;
  return earnedValue / plannedValue;
}

List<Map<String, dynamic>> generateServiceAlerts({
  required String serviceName,
  required String serviceId,
  required double plannedQuantity,
  required double directCost,
  required double earnedValue,
  required double actualCost,
  required double progress,
}) {
  final List<Map<String, dynamic>> alerts = [];

  if (directCost > 0 && earnedValue > 0 && actualCost > 0) {
    final cpi = computeCPI(earnedValue, actualCost);
    if (cpi < 0.95) {
      alerts.add({
        'type': 'cost',
        'severity': 'warning',
        'message': '$serviceName: CPI=${cpi.toStringAsFixed(2)} below threshold',
        'service_id': serviceId,
        'value': cpi,
      });
    }
  }
  if (plannedQuantity > 0 && progress < 50) {
    alerts.add({
      'type': 'schedule',
      'severity': progress < 10 ? 'critical' : 'warning',
      'message': '$serviceName: Only ${progress.toStringAsFixed(1)}% complete',
      'service_id': serviceId,
      'value': progress,
    });
  }

  return alerts;
}

double computeMachineryCost({
  required double hours,
  required double monthlyRent,
  required double fuelAdded,
  required double gallonCost,
}) {
  double rentCost = 0;
  if (monthlyRent > 0) {
    rentCost = (hours / 8) * (monthlyRent / 30);
  }
  return rentCost + fuelAdded * gallonCost;
}

double computeLaborCost({
  required double regularHours,
  required double overtimeHours,
  required double hourlyRate,
}) {
  return regularHours * hourlyRate + overtimeHours * hourlyRate * 1.5;
}

double computeProratedEquipmentCost({
  required double totalCost,
  required double instrumentDays,
  required double elapsedDays,
}) {
  if (instrumentDays <= 0) return 0;
  return totalCost * math.min(elapsedDays / instrumentDays, 1.0);
}
