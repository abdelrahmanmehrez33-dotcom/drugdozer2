import 'drug.dart';

class Reminder {
  final String id;
  final Drug drug;
  final String dosageAmount;
  final DateTime time;
  bool isTaken;

  Reminder({
    required this.id,
    required this.drug,
    required this.dosageAmount,
    required this.time,
    this.isTaken = false,
  });
}