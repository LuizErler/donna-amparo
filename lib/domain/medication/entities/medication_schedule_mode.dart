enum MedicationScheduleMode {
  fixedTimes('fixed_times'),
  interval('interval'),
  intervalDays('interval_days');

  const MedicationScheduleMode(this.code);

  final String code;

  static MedicationScheduleMode fromCode(String? code) {
    switch (code) {
      case 'interval':
        return MedicationScheduleMode.interval;
      case 'interval_days':
        return MedicationScheduleMode.intervalDays;
      default:
        return MedicationScheduleMode.fixedTimes;
    }
  }
}
