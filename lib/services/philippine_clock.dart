class PhilippineClock {
  const PhilippineClock();

  DateTime now() => DateTime.now();

  DateTime nowInPhilippines() => now().toUtc().add(const Duration(hours: 8));

  String dateStamp() {
    final ph = nowInPhilippines();
    return '${ph.year.toString().padLeft(4, '0')}-'
        '${ph.month.toString().padLeft(2, '0')}-'
        '${ph.day.toString().padLeft(2, '0')}';
  }

  String minuteStamp() {
    final ph = nowInPhilippines();
    return '${ph.hour.toString().padLeft(2, '0')}'
        '${ph.minute.toString().padLeft(2, '0')}';
  }
}

class FixedPhilippineClock extends PhilippineClock {
  const FixedPhilippineClock(this.fixedNow);

  final DateTime fixedNow;

  @override
  DateTime now() => fixedNow;
}
