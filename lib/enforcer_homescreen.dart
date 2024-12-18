import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
// ignore: unused_import
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parkpro_enforcers/login_form.dart';
import 'package:parkpro_enforcers/parking_area_list.dart';
import 'package:parkpro_enforcers/reports.dart';
import 'package:parkpro_enforcers/task_management.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mixins/status_mixin.dart';

class EnforcerDashboard extends StatefulWidget {
  final String enforcerName;
  final String enforcerId;
  final String firstName;
  final String lastName;

  const EnforcerDashboard({
    super.key,
    required this.enforcerName,
    required this.enforcerId,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<EnforcerDashboard> createState() => _EnforcerDashboardState();
}

class _EnforcerDashboardState extends State<EnforcerDashboard>
    with WidgetsBindingObserver, StatusMixin {
  String _enforcerName = '';
  String _enforcerId = '';
  bool _isLoading = true;
  bool _isLocationEnabled = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String _currentAddress = '';
  Timer? _locationTimer;
  // ignore: unused_field
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEnforcerData();
    _monitorEnforcerData();

    _initializeLocation();
  }

  @override
  void dispose() {
    _updateStatusToOffline();
    _locationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _updateStatusToOffline();
    } else if (state == AppLifecycleState.resumed) {
      _updateStatusToOnline();
    }
  }

  Future<void> _loadEnforcerData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _enforcerName = prefs.getString('enforcerName') ?? widget.enforcerName;
      _enforcerId = prefs.getString('enforcerId') ?? widget.enforcerId;
      _isLoading = false;
    });

    // Save the data again to ensure it persists
    await prefs.setString('enforcerName', _enforcerName);
    await prefs.setString('enforcerId', _enforcerId);
  }

  Future<void> _updateStatusToOnline() async {
    if (_enforcerId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('enforcer_account')
            .where('enforcer_id', isEqualTo: _enforcerId)
            .get()
            .then((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            final docId = snapshot.docs.first.id;
            await FirebaseFirestore.instance
                .collection('enforcer_account')
                .doc(docId)
                .update({
              'status': 'Online',
              'last_active': FieldValue.serverTimestamp(),
            });
          }
        });
      } catch (e) {
        debugPrint('Error updating online status: $e');
      }
    }
  }

  Future<void> _updateStatusToOffline() async {
    if (_enforcerId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('enforcer_account')
            .where('enforcer_id', isEqualTo: _enforcerId)
            .get()
            .then((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            final docId = snapshot.docs.first.id;
            await FirebaseFirestore.instance
                .collection('enforcer_account')
                .doc(docId)
                .update({
              'status': 'Offline',
              'last_active': FieldValue.serverTimestamp(),
            });
          }
        });
      } catch (e) {
        debugPrint('Error updating offline status: $e');
      }
    }
  }

  Future<void> _initializeLocation() async {
    await _checkLocationPermission();
    // Initial update
    await _updateLocation();

    // Set up periodic location updates (every 5 minutes)
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _checkLocationPermission();
      if (_isLocationEnabled) {
        await _updateLocation();
      }
    });
  }

  Future<void> _updateLocation() async {
    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.locality}';

        // Update Firestore with new location and timestamp
        await _updateFirestore(position);
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  Future<void> _updateFirestore(Position position) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('enforcer_account')
          .where('enforcer_id', isEqualTo: _enforcerId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('enforcer_account')
            .doc(docId)
            .update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'location': _currentAddress,
          'last_active': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating Firestore: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocationEnabled = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLocationEnabled = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocationEnabled = false;
        });
        return;
      }

      setState(() {
        _isLocationEnabled = true;
      });

      // Update location immediately when permission is granted
      if (_isLocationEnabled) {
        await _updateLocation();
      }
    } catch (e) {
      setState(() {
        _isLocationEnabled = false;
      });
    }
  }

  /// Monitors if the enforcer's data exists in Firestore
  Future<void> _monitorEnforcerData() async {
    try {
      FirebaseFirestore.instance
          .collection('enforcer_account')
          .where('enforcer_id', isEqualTo: widget.enforcerId.trim())
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.docs.isEmpty) {
          // If no enforcer data exists, log the enforcer out
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', false);
          await prefs.remove('loggedInEmail');

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          }
        }
      });
    } catch (e) {
      // Handle Firestore or network errors
      print('Error monitoring enforcer data: $e');
    }
  }

  /// Logout and navigate to login screen
  Future<void> _logout() async {
    await _updateStatusToOffline();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored data
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginForm()),
    );
  }

  /// Save the profile image path to SharedPreferences
  Future<void> _changeProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final savedImagePath = '${directory.path}/profile_picture.png';
        final savedImage = File(savedImagePath);

        if (_profileImage != null && await _profileImage!.exists()) {
          await _profileImage!.delete();
        }

        await File(pickedFile.path).copy(savedImagePath);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'profile_image_${widget.enforcerId}', savedImagePath);

        setState(() {
          _profileImage = savedImage;
        });
      }
    } catch (e) {
      print('Error changing profile image: $e');
    }
  }

  // Function to handle feature taps
  void _handleFeatureTap(BuildContext context, Widget destination) {
    if (!_isLocationEnabled) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Required'),
          content: const Text(
              'Please enable location services to access this feature.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _checkLocationPermission();
                if (_isLocationEnabled && mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => destination),
                  );
                }
              },
              child: const Text('Enable Location'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.amberAccent[400],
      appBar: AppBar(
        title: const Text(
          'Enforcer Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Makes the text bold
          ),
        ),
        backgroundColor: Colors.amberAccent[100],
        automaticallyImplyLeading: false,
        actions: [
          // Location status indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              _isLocationEnabled ? Icons.location_on : Icons.location_off,
              color: _isLocationEnabled ? Colors.green : Colors.red,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _changeProfileImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.black,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent[100],
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _enforcerName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ID: $_enforcerId',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: const Icon(Icons.assignment),
                      title: const Text('Task Management'),
                      subtitle: const Text('View and manage assigned tasks.'),
                      onTap: () => _handleFeatureTap(
                        context,
                        TaskManagementEnforcer(enforcerId: _enforcerId),
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: const Icon(Icons.map),
                      title: const Text('Parking Monitoring'),
                      subtitle: const Text('View parking area statuses.'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const ParkingAreaList()),
                        );
                      },
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: const Icon(Icons.report),
                      title: const Text('Reports'),
                      subtitle: const Text('Generate and view reports.'),
                      onTap: () => _handleFeatureTap(
                        context,
                        const Reports(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
