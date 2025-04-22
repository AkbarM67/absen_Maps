import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map/db/database_helper.dart';
import 'package:google_map/models/absen_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
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
  final LatLng _kantorLocation = LatLng(-6.9675606252408375, 107.6590739481314);
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
    }
  }

  void _startRealTimeLocationUpdates() {
    Geolocator.getPositionStream(locationSettings: LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    )).listen((Position position) {
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

  Future<void> _absen() async {
    if (_currentPosition == null) return;

    final distance = _calculateDistanceInMeter(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      _kantorLocation,
    );

    if (distance > _radiusMeter) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Anda berada di luar radius kantor.')));
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now();
    final filename = '${timestamp.toIso8601String()}_${widget.username}.jpg';
    final imagePath = '${directory.path}/$filename';
    final imageFile = File(pickedFile.path);
    await imageFile.copy(imagePath);

    final absen = AbsenModel(
      username: widget.username,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      timestamp: timestamp.toIso8601String(),
      imagePath: imagePath,
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
    return Scaffold(
      appBar: AppBar(
      title: Text('Selamat Datang, ${widget.username}'),
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      ),
      body: Container(
      color: Colors.white, // Set background color to white
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
              )
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
              onPressed: _absen,
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Set background color to blue
              foregroundColor: Colors.white, // Set text color to white
              ),
              child: Text('Absen Sekarang'),
            ),
            ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            child: Text('Logout'),
            ),
            SizedBox(height: 20),
            Text('Riwayat Absen:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ..._history.map((absen) => ListTile(
              leading: Image.file(File(absen.imagePath), width: 50, height: 50),
              title: Text('Lat: ${absen.latitude}, Lng: ${absen.longitude}'),
              subtitle: Text('Waktu: ${absen.timestamp.replaceAll("T", " ").split(".")[0]}'),
              )),
          ],
          ),
        ),
        ],
      ),
      ),
    );
  }
}
