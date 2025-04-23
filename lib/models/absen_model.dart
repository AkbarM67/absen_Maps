class AbsenModel {
  final int? id;
  final String username;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String imagePath;
  final String jenis;
  final String status;

  AbsenModel({
    this.id,
    required this.username,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.imagePath,
    required this.jenis,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'imagePath': imagePath,
      'jenis': jenis,
      'status': status,
    };
  }

  factory AbsenModel.fromMap(Map<String, dynamic> map) {
    return AbsenModel(
      id: map['id'],
      username: map['username'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: map['timestamp'],
      imagePath: map['imagePath'],
      jenis: map['jenis'],
      status: map['status'],
    );
  }
}
