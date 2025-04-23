import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map/db/database_helper.dart';
import 'package:google_map/models/absen_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final String username;

  const HomePage({required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final LatLng _kantorLocation = LatLng(-6.967613544433433, 107.65907756008848);
  final double _radiusMeter = 30;

  List<AbsenModel> _history = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadAbsenHistory();
    _startRealTimeLocationUpdates();
  }

  void _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permission denied')));
    }
  }

  void _startRealTimeLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  double _calculateDistanceInMeter(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  Future<void> _loadAbsenHistory() async {
    final data = await DatabaseHelper.instance.getAbsenByUsername(widget.username);
    setState(() {
      _history = data;
    });
  }

  Future<void> _absen(String jenis) async {
    if (_currentPosition == null) return;

    // Validasi lokasi
    final distance = _calculateDistanceInMeter(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      _kantorLocation,
    );

    if (distance > _radiusMeter) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda berada di luar radius kantor.')),
      );
      return;
    }

    // Validasi sudah absen jenis sama hari ini
    final alreadyAbsen = await DatabaseHelper.instance.hasAbsenToday(widget.username, jenis);
    if (alreadyAbsen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda sudah melakukan absen $jenis hari ini.')),
      );
      return;
    }

    // Konfirmasi sebelum absen
    final confirm = await showDialog<bool>( 
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Konfirmasi Absen'),
        content: Text('Yakin ingin absen $jenis sekarang?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Ya')),
        ],
      ),
    );
    if (confirm != true) return;

    // Ambil foto
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    // Simpan foto
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now();
    final filename = '${timestamp.toIso8601String()}_${widget.username}_$jenis.jpg';
    final imagePath = '${directory.path}/$filename';
    final imageFile = File(pickedFile.path);
    await imageFile.copy(imagePath);

    // Simpan absen ke SQLite
    final absen = AbsenModel(
      username: widget.username,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      timestamp: timestamp.toIso8601String(),
      imagePath: imagePath,
      jenis: jenis,
      status: jenis,
    );

    await DatabaseHelper.instance.insertAbsen(absen);
    _loadAbsenHistory();
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd-MM-yyyy HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: Text('Selamat Datang, ${widget.username}'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 250,
              child: _currentPosition == null
                  ? Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        zoom: 16,
                      ),
                      myLocationEnabled: true,
                      markers: {
                        Marker(
                          markerId: MarkerId('kantor'),
                          position: _kantorLocation,
                          infoWindow: InfoWindow(title: 'Lokasi Kantor'),
                        ),
                      },
                      onMapCreated: (controller) => _mapController = controller,
                    ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Text('Lokasi: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}'),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _absen('Masuk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Absen Masuk'),
                  ),
                  ElevatedButton(
                    onPressed: () => _absen('Pulang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Absen Pulang'),
                  ),
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: Text('Logout'),
                  ),
                  SizedBox(height: 20),
                  Text('Riwayat Absen:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  ..._history.map((absen) {
                    final formattedTime = formatter.format(DateTime.parse(absen.timestamp));
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Image.file(
                          File(absen.imagePath),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              absen.jenis == 'Masuk' ? Icons.login : Icons.logout,
                              color: absen.jenis == 'Masuk' ? Colors.green : Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('${absen.jenis} - ${absen.username}', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Waktu: $formattedTime'),
                            Text('Lokasi: (${absen.latitude.toStringAsFixed(5)}, ${absen.longitude.toStringAsFixed(5)})'),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
