class Profile {
  final int? id;
  String name;
  double walletAmount;
  String calendarPreference; // 'gregorian' or 'hijri'

  Profile({
    this.id,
    required this.name,
    required this.walletAmount,
    this.calendarPreference = 'gregorian',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'walletAmount': walletAmount,
      'calendarPreference': calendarPreference,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      name: map['name'],
      walletAmount: map['walletAmount'],
      calendarPreference: map['calendarPreference'],
    );
  }
}