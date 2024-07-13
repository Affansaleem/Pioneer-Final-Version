import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:project/constants/AppBar_constant.dart';
import 'package:project/constants/AppColor_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../No_internet/no_internet.dart';
import '../../../introduction/bloc/bloc_internet/internet_bloc.dart';
import '../../../introduction/bloc/bloc_internet/internet_state.dart';
import '../../adminReportsFiles/models/getActiveEmployeesModel.dart';
import '../bloc/admin_geofence_bloc.dart';
import '../models/adminGeofenceModel.dart';
import '../models/adminGeofencePostRepository.dart';

class AdminMapDisplay extends StatefulWidget {
  final List<GetActiveEmpModel> selectedEmployees;

  const AdminMapDisplay({Key? key, required this.selectedEmployees})
      : super(key: key);

  @override
  State<AdminMapDisplay> createState() => _AdminMapDisplayState();
}

class _AdminMapDisplayState extends State<AdminMapDisplay> {
  late GoogleMapController mapController;
  LatLng _currentPosition = LatLng(0.0, 0.0);
  String _currentAddress = '';
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final String _locationIqApiKey = 'pk.f9a5e193687ba71e403440e7974d3038';
  double _radius = 10.0;
  bool _isKilometers = false;

  TextEditingController searchController = TextEditingController();
  List<dynamic> autocompleteResults = [];
  FocusNode searchFocusNode = FocusNode();
  bool isTyping = false; // To keep track of typing status

  double? currentLat;
  double? currentLong;
  double? sendLat;
  double? sendLong;

  String address = "";
  bool isAddressFetched = false;
  bool locationError = false;
  final adminGeoFenceRepository = AdminGeoFenceRepository();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    searchFocusNode.addListener(_focusListener);
  }

  void _focusListener() {
    setState(() {
      isTyping = searchFocusNode.hasFocus;
      if (!isTyping) {
        autocompleteResults.clear();
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _getCurrentLocation();
  }

  @override
  void dispose() {
    searchFocusNode.removeListener(_focusListener);
    searchFocusNode.dispose();
    super.dispose();
  }

  void autocompleteSearch(String query) async {
    String apiUrl = 'https://us1.locationiq.com/v1/autocomplete.php';
    String url = '$apiUrl?key=$_locationIqApiKey&q=$query';

    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          autocompleteResults = json.decode(response.body);
        });
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void handleAutocompleteTap(double latitude, double longitude) {
    setState(() {
      _currentPosition = LatLng(latitude, longitude);
      _updatePosition(_currentPosition);
    });
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 15,
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _currentPosition = LatLng(position.latitude, position.longitude);

    List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      _currentAddress =
      '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}, ${place.thoroughfare}';
    }

    setState(() {
      _updatePosition(_currentPosition);
      if (mapController != null) {
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentPosition,
              zoom: 15,
            ),
          ),
        );
      }
    });
  }

  Future<void> _updatePosition(LatLng position) async {
    _currentPosition = position;
    List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      _currentAddress =
      '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}';
    }

    setState(() {
      _markers.clear();
      _circles.clear();
      _markers.add(
        Marker(
          markerId: MarkerId(_currentPosition.toString()),
          position: _currentPosition,
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: _currentAddress,
          ),
          draggable: true,
          onDragEnd: (newPosition) {
            _updatePosition(newPosition);
          },
        ),
      );

      _circles.add(
        Circle(
          circleId: CircleId("radius"),
          center: _currentPosition,
          radius: _isKilometers ? _radius * 1000 : _radius,
          fillColor: Colors.blue.withOpacity(0.1),
          strokeColor: Colors.blue.withOpacity(0.5),
          strokeWidth: 2,
        ),
      );

      if (mapController != null) {
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentPosition,
              zoom: 15,
            ),
          ),
        );
      }
    });
  }

  void _updateRadius(double radius) {
    setState(() {
      _radius = radius;
      _circles.clear();
      _circles.add(
        Circle(
          circleId: CircleId("radius"),
          center: _currentPosition,
          radius: _isKilometers ? _radius * 1000 : _radius,
          fillColor: Colors.blue.withOpacity(0.1),
          strokeColor: Colors.blue.withOpacity(0.5),
          strokeWidth: 2,
        ),
      );
    });
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              color: Colors.white,
              constraints: BoxConstraints(
                minHeight: 200, // Set the minimum height of the card
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _currentAddress,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.visible,
                            softWrap: true,
                            maxLines: null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          "Radius",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            Text('Km', style: TextStyle(color: Colors.black54)),
                            Switch(
                              value: !_isKilometers,
                              onChanged: (value) {
                                setState(() {
                                  _isKilometers = !value;
                                  _radius = _isKilometers ? 1.0 : 10.0;
                                });
                              },
                              activeColor: Colors.black,
                              inactiveThumbColor: Colors.black,
                              inactiveTrackColor: Colors.white,
                            ),
                            Text('M', style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Slider(
                      value: _radius,
                      min: _isKilometers ? 1 : 10,
                      max: _isKilometers ? 5 : 50,
                      divisions: _isKilometers ? 4 : 8,
                      label: _isKilometers ? '${_radius.round()} km' : '${_radius.round()} meters',
                      activeColor: Colors.black,
                      inactiveColor: Colors.blue.withOpacity(0.3),
                      onChanged: (value) {
                        setState(() {
                          _updateRadius(value);
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        _updateLocation(
                          _currentPosition.latitude,
                          _currentPosition.longitude,
                          _currentAddress,
                        );
                        Fluttertoast.showToast(msg: "Coordinates are saved!");
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text('Set Geofence'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // old content
  Future<void> saveLocationToSharedPreferences(double lat, double long) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('latitude', lat);
    await prefs.setDouble('longitude', long);
  }

  Future<void> _submitGeofenceDataForSelectedEmployees() async {
    final adminGeofenceBloc = BlocProvider.of<AdminGeoFenceBloc>(context);

    final List<GetActiveEmpModel> selectedEmployees = widget.selectedEmployees;
    final List<AdminGeoFenceModel> geofenceDataList = [];

    for (int i = 0; i < selectedEmployees.length; i++) {
      final employee = selectedEmployees[i];

      // Use the employee data to create the geofence model
      final geofenceModel = AdminGeoFenceModel(
        empId: employee.empId ?? 0,
        empName: employee.empName,
        lat: sendLat.toString(),
        lon: sendLong.toString(),
        radius: (_radius).toString(),
        emailAddress: null,
        fatherName: null,
        phoneNo: null,
        profilePic: null,
        pwd: null,
        // Add other required fields based on your model
      );

      geofenceDataList.add(geofenceModel);
    }

    // Post the geofence data for selected employees
    await adminGeoFenceRepository.postGeoFenceData(geofenceDataList);
  }

  Future<void> checkLocationPermissionAndFetchLocation() async {
    final permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      try {
        final data = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) {
          currentLat = data.latitude;
          currentLong = data.longitude;
          address = getAddress(currentLat, currentLong);
          locationError = false;
        }
      } catch (e) {
        print('Error getting location: $e');
      }
    } else {
      if (mounted) {
        locationError = true;
      }
    }
  }

  Future<void> checkSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble('latitude');
    final longitude = prefs.getDouble('longitude');

    print('Latitude: $latitude');
    print('Longitude: $longitude');
  }

  getAddress(double? lat, double? long) async {
    if (lat != null && long != null) {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      if (mounted) {
        setState(() {
          address = "${placemarks[0].street!}, ${placemarks[4].street!} , ${placemarks[0].country!}";
        });
      }
    } else {}
  }

  Future<void> showSnackbar(BuildContext context, String message) async {
    await SharedPreferences.getInstance();

    if (sendLat != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green, // Set the background color to green
        ),
      );
    }
  }

  void popPage() {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pop(context);
    });
  }

  bool isInternetLost = false;

  void _updateLocation(double latitude, double longitude, String addressName) {
    setState(() {
      sendLat = latitude;
      sendLong = longitude;
      address = addressName;
      print(sendLat);
      print(sendLong);
      print(address);
      _submitGeofenceDataForSelectedEmployees();
      saveLocationToSharedPreferences(sendLat!, sendLong!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InternetBloc, InternetStates>(
        listener: (context, state) {
          if (state is InternetLostState) {
            isInternetLost = true;
            Future.delayed(Duration(seconds: 2), () {
              Navigator.push(
                context,
                PageTransition(
                  child: NoInternet(),
                  type: PageTransitionType.rightToLeft,
                ),
              );
            });
          } else if (state is InternetGainedState) {
            // Check if internet was previously lost
            if (isInternetLost) {
              // Navigate back to the original page when internet is regained
              Navigator.pop(context);
            }
            isInternetLost = false; // Reset the flag
          }
        }, builder: (context, state) {
      if (state is InternetGainedState) {
        if (currentLat != null && currentLong != null && !locationError) {
          return Scaffold(
            body: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 15,
                  ),
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onTap: _updatePosition,
                ),
                Positioned(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 30),
                        child: Material(
                          elevation: 5.0,
                          shadowColor: Colors.grey[300],
                          borderRadius: BorderRadius.circular(50.0),
                          child: TextField(
                            controller: searchController,
                            focusNode: searchFocusNode,
                            onChanged: (value) {
                              autocompleteSearch(value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search here',
                              prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[700]),
                                onPressed: () {
                                  searchController.clear();
                                  autocompleteSearch('');
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.grey[100],
                              filled: true,
                              labelStyle: TextStyle(color: Colors.grey[700]),
                              hintStyle: TextStyle(
                                  color: Colors.grey[700]?.withOpacity(0.7)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      // Conditionally render the list container based on autocompleteResults and search text
                      if (autocompleteResults.isNotEmpty &&
                          searchController.text.isNotEmpty)
                        Container(
                          color: Colors.grey[100],
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 200.0,
                            child: ListView.builder(
                              itemCount: autocompleteResults.length,
                              itemBuilder: (context, index) {
                                var location = autocompleteResults[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  leading: Icon(Icons.location_on, color: Colors.black),
                                  title: Text(
                                    location['display_name'],
                                    style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
                                  ),
                                  onTap: () {
                                    handleAutocompleteTap(
                                      double.parse(location['lat']),
                                      double.parse(location['lon']),
                                    );
                                    searchFocusNode.unfocus();
                                    setState(() {
                                      autocompleteResults.clear();
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        )
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 15,
                  child: FloatingActionButton(
                    mini: true, // This makes the button smaller
                    backgroundColor: Colors.white, // Set background color to white
                    onPressed: _getCurrentLocation,
                    child: Icon(
                      Icons.my_location,
                      color: Colors.black, // Set icon color to blue
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: isTyping
                ? null
                : SizedBox(
              height: 40, // Adjust height
              child: FloatingActionButton.extended(
                backgroundColor: Colors.white, // Set background color to white
                onPressed: () => _showBottomSheet(context),
                label: Text(
                  'Show Address',
                  style: TextStyle(color: Colors.black, fontSize: 12), // Set text color to blue and font size
                ),
                icon: Icon(
                  Icons.location_on,
                  color: Colors.black, // Set icon color to blue
                  size: 16, // Adjust icon size
                ),
              ),
            ),
          );
        }
        else {
          checkLocationPermissionAndFetchLocation();
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primaryColor,
              elevation: 0,
              title: const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 55.0), // Add right padding
                  child: Text(
                    "Maps",
                    style: AppBarStyles.appBarTextStyle,
                  ),
                ),
              ),
              iconTheme: IconThemeData(color: AppBarStyles.appBarIconColor),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Fetching Location..."),
                  SizedBox(height: 16),
                  // Text("Turn On Location..."),
                ],
              ),
            ),
          );
        }
      } else {
        checkLocationPermissionAndFetchLocation();
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            title: const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 55.0), // Add right padding
                child: Text(
                  "Maps",
                  style: AppBarStyles.appBarTextStyle,
                ),
              ),
            ),
            iconTheme: IconThemeData(color: AppBarStyles.appBarIconColor),
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Fetching Location..."),
                SizedBox(height: 16),
                // Text("Turn On Location..."),
              ],
            ),
          ),
        );
      }
    });
  }
}
