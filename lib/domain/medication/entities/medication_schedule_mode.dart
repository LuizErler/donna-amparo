enum MedicationScheduleMode {
  fixedTimes('fixed_times'),
  interval('interval');

  const MedicationScheduleMode(this.code);

  final String code;

  static MedicationScheduleMode fromCode(String? code) {
    if (code == MedicationScheduleMode.interval.code) {
      return MedicationScheduleMode.interval;
    }
    return MedicationScheduleMode.fixedTimes;
  }
}
