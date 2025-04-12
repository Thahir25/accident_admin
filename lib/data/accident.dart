class Accident {
  final String accidentStatus;
  final String alcoholStatus;
  final String alcoholValue;
  final String fireStatus;
  final String latitude;
  final String longitude;
  final String time;

  Accident({
    required this.accidentStatus,
    required this.alcoholStatus,
    required this.alcoholValue,
    required this.fireStatus,
    required this.latitude,
    required this.longitude,
    required this.time,
  });

  factory Accident.fromMap(Map<String, dynamic> map) {
    return Accident(
      accidentStatus: map['accident-status'] as String? ?? 'Unknown',
      alcoholStatus: map['alcohol-status'] as String? ?? 'Unknown',
      alcoholValue: map['alcohol-value'] as String? ?? '0',
      fireStatus: map['fire-status'] as String? ?? 'Unknown',
      latitude: map['latitude'] as String? ?? '0.0',
      longitude: map['longitude'] as String? ?? '0.0',
      time: map['time'] as String? ?? 'Unknown',
    );
  }
}
