enum DrugType {
  syrup('شراب', 'water_drop'),
  tablet('أقراص', 'medication'),
  cream('كريم', 'healing'),
  spray('بخاخ', 'air'),
  drops('نقط', 'water_drop_outlined'),
  injection('حقن', 'medication_liquid');

  final String arabicName;
  final String iconName;

  const DrugType(this.arabicName, this.iconName);
}