import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:page_transition/page_transition.dart';
import 'package:project/constants/AppBar_constant.dart';
import 'package:project/constants/AppColor_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../No_internet/no_internet.dart';
import '../../../introduction/bloc/bloc_internet/internet_bloc.dart';
import '../../../introduction/bloc/bloc_internet/internet_state.dart';
import '../../adminReportsFiles/models/getActiveEmployeesModel.dart';
import '../bloc/admin_geofence_bloc.dart';
import '../models/adminGeofenceModel.dart';
import '../models/adminGeofencePostRepository.dart';
import 'package:http/http.dart' as http;

class AdminMapDisplay extends StatefulWidget {
  final List<GetActiveEmpModel> selectedEmployees;

  const AdminMapDisplay({Key? key, required this.selectedEmployees})
      : super(key: key);

  @override
  State<AdminMapDisplay> createState() => _AdminMapDisplayState();
}

class _AdminMapDisplayState extends State<AdminMapDisplay> {
  double? currentLat;
  double? currentLong;
  double? sendLat;
  double? sendLong;

  // below new
  String address = "";
  String apiKey = 'pk.f9a5e193687ba71e403440e7974d3038';
  TextEditingController searchController = TextEditingController();
  List<dynamic> autocompleteResults = [];
  LatLng _center = LatLng(51.509364, -0.128928); // Default center
  String locationMessage = '';
  MapController mapController = MapController(); // Create a MapController
  LatLng draggableMarkerPosition =
      LatLng(51.509364, -0.128928); // Position for the draggable marker
  FocusNode searchFocusNode = FocusNode(); // Define a FocusNode
  double radius = 0.0; // Add this line
  late double setRadius = 0;
  String unit = 'KM'; // Default unit is kilometers
  bool isSearchBarFocused =
      false; // Add this line at the beginning of your _MapsPageState class
  bool isAddressFetched = false;

  bool locationError = false;
  final adminGeoFenceRepository = AdminGeoFenceRepository();

  @override
  void initState() {
    super.initState();
    // Initialize the MapController
    mapController = MapController();

    // Set up the focus node listener for the search bar
    searchFocusNode.addListener(_focusListener);

    // Get the current location and set it as the initial center of the map
    _getCurrentLocation().then((value) {
      setState(() {
        currentLat = value.latitude;
        currentLong = value.longitude;
        _center = LatLng(currentLat!, currentLong!);
        draggableMarkerPosition = _center;
        locationMessage =
        'Latitude ${value.latitude} Longitude ${value.longitude}';
      });
      liveLocation();
    });
  }


  void _focusListener() {
    setState(() {
      isSearchBarFocused = searchFocusNode.hasFocus;
      print(isSearchBarFocused);
    });
  }

  @override
  void dispose() {
    searchFocusNode.removeListener(_focusListener);
    searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> reverseGeocode(double latitude, double longitude) async {
    String apiUrl = 'https://us1.locationiq.com/v1/reverse.php';
    String apiKey =
        'pk.f9a5e193687ba71e403440e7974d3038'; // Replace with your actual API key
    String url = '$apiUrl?key=$apiKey&lat=$latitude&lon=$longitude&format=json';

    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var addressComponents = data['address'];

        // Extract and concatenate address components
        String fetchedAddress = [
          addressComponents['neighbourhood'],
          addressComponents['suburb'],
          addressComponents['district'],
          addressComponents['state'],
          addressComponents['postcode'],
          addressComponents['country'],
        ]
            .where((component) => component != null && component.isNotEmpty)
            .join(', ');

        print("Address: $fetchedAddress");

        // Update the address state variable
        setState(() {
          address = fetchedAddress;
          isAddressFetched = true;
          print(address);
        });
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
    }
  }

  void autocompleteSearch(String query) async {
    String apiUrl = 'https://us1.locationiq.com/v1/autocomplete.php';
    String url = '$apiUrl?key=$apiKey&q=$query';

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
      _center =
          LatLng(latitude, longitude); // Update _center with selected location
      draggableMarkerPosition =
          LatLng(latitude, longitude); // Update the draggable marker's position
    });
    // Use the MapController to move the map to the selected location
    mapController.move(LatLng(latitude, longitude), 15.0);
  }

  void liveLocation() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        locationMessage =
            'Latitude ${position.latitude} Longitude ${position.longitude}';
        print(locationMessage);
        // Use the MapController to move the map to the new coordinates
        mapController.move(LatLng(position.latitude, position.longitude), 15.0);
      });
    });
  }

  Future<Position> _getCurrentLocation() async {
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

    return await Geolocator.getCurrentPosition();
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
        radius: (setRadius).toString(),
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

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
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
          address =
              "${placemarks[0].street!}, ${placemarks[4].street!} , ${placemarks[0].country!}";
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
    final adminGeofenceBloc = BlocProvider.of<AdminGeoFenceBloc>(context);
    return BlocConsumer<InternetBloc, InternetStates>(
        listener: (context, state) {
      if (state is InternetLostState) {
        // Set the flag to true when internet is lost
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
            appBar: AppBar(
              backgroundColor: AppBarStyles.appBarBackgroundColor,
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
            body: Stack(
              children: [
                StatefulBuilder(
                  builder: (context, setState) {
                    return FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        center: _center,
                        zoom: 5.2,
                        onTap: (TapPosition tapPosition, LatLng latlng) {
                          setState(() {
                            draggableMarkerPosition = latlng;
                            print(
                                "Draggable Marker Position: Latitude ${draggableMarkerPosition.latitude}, Longitude ${draggableMarkerPosition.longitude}");
                            reverseGeocode(draggableMarkerPosition.latitude,
                                draggableMarkerPosition.longitude);
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 80.0,
                              height: 80.0,
                              point: draggableMarkerPosition,
                              child: Container(
                                  child: Icon(
                                FontAwesomeIcons.person, size: 25.0,
                                // Adjust the icon size
                                color: Colors.blue, // Adjust the icon color)
                              )),
                            ),
                          ],
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: draggableMarkerPosition,
                              radius: radius,
                              color: Colors.blue.withOpacity(0.5),
                              borderStrokeWidth: 2,
                              borderColor: Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        onChanged: (value) {
                          autocompleteSearch(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for places...',
                          labelText: 'Search',
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[700]),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[700]),
                            onPressed: () {
                              searchController.clear();
                              autocompleteSearch('');
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Colors.grey[100],
                          filled: true,
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          hintStyle: TextStyle(
                              color: Colors.grey[700]?.withOpacity(0.7)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      // Conditionally render the list container based on autocompleteResults and search text
                      if (autocompleteResults.isNotEmpty &&
                          searchController.text.isNotEmpty)
                        Container(
                          color: Colors.grey[100],
                          // Light grey background color
                          padding: EdgeInsets.all(8.0),
                          // Add some padding around the list
                          child: SizedBox(
                            height: 200.0,
                            child: ListView.builder(
                              itemCount: autocompleteResults.length,
                              itemBuilder: (context, index) {
                                var location = autocompleteResults[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  // Add padding around each item
                                  leading: Icon(Icons.location_on,
                                      color: Colors.blue),
                                  // Add a leading icon
                                  title: Text(
                                    location['display_name'],
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.grey[
                                            700]), // Customize the text style with grey color
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
                if (!isSearchBarFocused)
                  Positioned(
                    left: 229,
                    bottom: 200.0,
                    child: Column(
                      children: [
                        Transform.rotate(
                          angle: -90 * pi / 180,
                          // Rotate 90 degrees counterclockwise
                          child: Slider(
                            value: radius,
                            // Adjust the slider value based on the unit
                            min: 0.0,
                            // Adjust the slider min value based on the unit
                            max: unit == 'KM' ? 50.0 : 25.0,
                            // Adjust the slider max value based on the unit
                            divisions: 5,
                            // Adjust the slider divisions based on the unit
                            label: unit == 'KM'
                                ? (radius / 10).toStringAsFixed(1)
                                : radius.toInt().toString(),
                            onChanged: (double newRadius) {
                              setState(() {
                                radius =
                                    newRadius; // Convert the slider value to the correct unit
                                setRadius =
                                    unit == 'KM' ? radius * 100 : radius;
                                print("set radius value ${setRadius}");
                              });
                            },
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 60),
                          padding: EdgeInsets.zero,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                unit = unit == 'KM'
                                    ? 'M'
                                    : 'KM'; // Toggle the unit
                                radius = 0;
                                setRadius = 0;
                              });
                            },
                            child: Text(unit == 'KM'
                                ? '${(radius / 10).toStringAsFixed(0)} KM'
                                : '${radius.toInt()} M'),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!isSearchBarFocused)
                  Positioned(
                    bottom: 150,
                    right: 30,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          Position currentPosition =
                              await _getCurrentLocation();
                          setState(() {
                            _center = LatLng(currentPosition.latitude,
                                currentPosition.longitude);
                            draggableMarkerPosition = LatLng(
                                currentPosition.latitude,
                                currentPosition.longitude);
                            locationMessage =
                                'Latitude ${currentPosition.latitude} Longitude ${currentPosition.longitude}';
                          });
                          mapController.move(
                              LatLng(currentPosition.latitude,
                                  currentPosition.longitude),
                              15.0);
                          liveLocation();
                        } catch (e) {
                          print('Error getting current location: $e');
                        }
                      },
                      child: Padding(
                        padding:  EdgeInsets.symmetric(horizontal: 5.0),
                        child: Icon(Icons.gps_fixed),
                      ),
                    ),
                  ),
                if (!isSearchBarFocused)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 30),
                        child: isAddressFetched // Check if the address has been fetched
                            ? Card(
                                elevation: 4,
                                color: Colors.grey[100],
                                // Light grey background color
                                shadowColor: Colors.grey[300],
                                // Subtle shadow color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      10), // Rounded corners
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  // Slightly reduced padding for a more compact look
                                  child: Text(
                                    address,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[
                                            700]), // Smaller font size for concise text
                                    // Removed maxLines and overflow to show complete text
                                  ),
                                ),
                              )
                            : Container(), // Display an empty Container if the address has not been fetched
                      ),
                      Container(
                        width: double.infinity,
                        // Make the button full-width
                        margin: EdgeInsets.symmetric(vertical:10, horizontal: 20.0),
                        // Adjust margin as needed
                        child: ElevatedButton(
                          onPressed: () {
                            _updateLocation(draggableMarkerPosition.latitude,
                                draggableMarkerPosition.longitude, address);
                            showSnackbar(context, "Coordinates are saved!");
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                Colors.blue, // Set text color to white
                          ),
                          child: Text(
                            "Set Geofence",
                            style: TextStyle(
                                color: Colors.white), // Set text color to white
                          ),
                        ),
                      )
                    ],
                  )
              ],
            ),
          );
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
