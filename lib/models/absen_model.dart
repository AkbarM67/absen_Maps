class AbsenModel {
  final int? id;
  final String username;
  final double latitude;
  final double longitude;
  final String imagePath;
  final String timestamp;

  AbsenModel({
    this.id,
    required this.username,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'latitude': latitude,
      'longitude': longitude,
      'imagePath': imagePath,
      'timestamp': timestamp,
    };
  }

  factory AbsenModel.fromMap(Map<String, dynamic> map) {
    return AbsenModel(
      id: map['id'],
      username: map['username'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      imagePath: map['imagePath'],
      timestamp: map['timestamp'],
    );
  }
}
