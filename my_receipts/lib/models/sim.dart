
class Sim {
  final int id;
  final int profileId;
  String name;
  final DateTime createdAt;

  Sim({
    required this.id,
    required this.profileId,
    required this.name,
    required this.createdAt,
  });

  factory Sim.fromMap(Map<String, dynamic> map) {
    return Sim(
      id: map['id'],
      profileId: map['profileId'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}