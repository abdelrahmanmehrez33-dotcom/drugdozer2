import 'package:flutter/material.dart';
import '../../domain/entities/drug.dart';

class DoseCalculator {
  double calculateMinDoseMl(double weightInKg, Drug drug) {
    if (drug.concentrationMg == 0) return 0;
    
    double minDosePerKg = drug.minDosePerKg;
    double concentrationMl = drug.concentrationMl;
    double concentrationMg = drug.concentrationMg;

    return (weightInKg * minDosePerKg * concentrationMl) / concentrationMg;
  }

  double calculateMaxDoseMl(double weightInKg, Drug drug) {
    if (drug.concentrationMg == 0) return 0;
    
    double maxDosePerKg = drug.maxDosePerKg;
    double concentrationMl = drug.concentrationMl;
    double concentrationMg = drug.concentrationMg;

    return (weightInKg * maxDosePerKg * concentrationMl) / concentrationMg;
  }

  String getDoseRecommendation(double weightInKg, Drug drug) {
    if (drug.fixedDose != null) return drug.fixedDose!;
    
    double min = calculateMinDoseMl(weightInKg, drug);
    double max = calculateMaxDoseMl(weightInKg, drug);
    
    return "${min.toStringAsFixed(1)} - ${max.toStringAsFixed(1)} ml";
  }
}
