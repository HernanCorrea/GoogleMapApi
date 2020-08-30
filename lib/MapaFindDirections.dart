import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/directions.dart' as webservice;
import 'package:googlemaps/Model/DirectionInformation.dart';
import 'package:googlemaps/Model/MatrixDirection.dart';
import 'package:googlemaps/Servicios/GoogleMapServices.dart';
import 'package:googlemaps/Widgets/MapPinPillComponent.dart';
import 'package:googlemaps/conf/configuration.dart';

class MapaFindDirections extends StatefulWidget {
  @override
  _MapaFindDirectionsState createState() => _MapaFindDirectionsState();
}

LatLng sourceLocation = LatLng(2.898038, -75.265210);
LatLng destLocation = LatLng(2.901580, -75.268228);

class _MapaFindDirectionsState extends State<MapaFindDirections> {
  //GoogleMaps Instances
  GoogleMapController _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  CameraPosition initialLocation = CameraPosition(
      zoom: CAMERA_ZOOM,
      bearing: CAMERA_BEARING,
      tilt: CAMERA_TILT,
      target: sourceLocation);
  //Polyline Instances
  PolylinePoints polylinePoints = PolylinePoints();
  //Custom Icons
  BitmapDescriptor sourceIcon;
  BitmapDescriptor destinationIcon;
  //Style of my map
  String _mapStyle;
  //TextField Instances
  TextEditingController _searchAdressController = TextEditingController();
  //Geolocator dependecy
  Geolocator _geolocator = Geolocator();
  Placemark placeLocation;
  Placemark placeDestination;
  //WebService Direction dependency
  webservice.GoogleMapsDirections directionsApi =
      webservice.GoogleMapsDirections(apiKey: mapsApiKey);
  //animation card
  double _cardPosition = -100;
  DirectionInformation _directionInformation = DirectionInformation(
      direction: '', distance: '0 km', duration: '0 m', mode: 'Driving');

  @override
  void initState() {
    super.initState();
    _setSourceAndDestinationIcons();
    _setMapStyle();
  }

  void _setSourceAndDestinationIcons() async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        "lib/images/driving_pin.png");
    destinationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        "lib/images/destination_map_marker.png");
  }

  void _setMapStyle() {
    rootBundle.loadString('lib/images/styles/map_styles.txt').then((string) {
      _mapStyle = string;
    });
  }

  // Method for retrieving the current location
  _getCurrentLocation() async {
    await _geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      List<Placemark> places = await _geolocator.placemarkFromCoordinates(
          position.latitude, position.longitude);
      setState(() {
        // Store the position in the variable
        sourceLocation = LatLng(position.latitude, position.longitude);
        // Taking the most probable result
        placeLocation = places[0];
      });
    }).catchError((e) {
      print(e);
    });
  }

  _getAddress({String address,LatLng position}) async {
    try {
      List<Placemark> places = [];
      // Places are retrieved using the coordinates
      if(address != null){
        places = await _geolocator.placemarkFromAddress(address);
      }else{
        places = await _geolocator.placemarkFromPosition(
          Position(
            latitude: position.latitude,
            longitude: position.longitude
            )
        );
      }
      
      
      // Taking the most probable result
      placeDestination = places[0];
      destLocation = LatLng(placeDestination.position.latitude,
          placeDestination.position.longitude);
      _polylines.clear();
      _markers.clear();
    } catch (e) {
      clearDefault();
    }
    _setMarkers();
    _centerCamera();
    _setPolylines();
    setState(() {});
  }

  clearDefault() {
    _polylines.clear();
    _markers.clear();
    destinationIcon = null;
    placeDestination = null;
    destLocation = null;
  }

  _setMarkers() {
    // Start Location Marker
    Marker locationMarker = Marker(
      markerId: MarkerId('Ubicacion Usuario'),
      position: LatLng(
        sourceLocation.latitude,
        sourceLocation.longitude,
      ),
      infoWindow: InfoWindow(
          title: 'Start',
          snippet:
              "${placeLocation?.name}, ${placeLocation?.locality}, ${placeLocation?.postalCode}, ${placeLocation?.country}"),
      icon: BitmapDescriptor.defaultMarker,
    );

    // Destination Location Marker
    Marker destinationMarker = Marker(
      markerId: MarkerId('Destino Usuario'),
      position: LatLng(
        destLocation.latitude,
        destLocation.longitude,
      ),
      infoWindow: InfoWindow(
          title: 'Destination',
          snippet:
              "${placeDestination?.name}, ${placeDestination?.locality}, ${placeDestination?.postalCode}, ${placeDestination?.country}"),
      icon: BitmapDescriptor.defaultMarker,
      draggable: true,
      onDragEnd: onDragEnd,
    );
    if (placeLocation?.name != null) _markers.add(locationMarker);
    if (placeDestination?.name != null) _markers.add(destinationMarker);
  }
  void onDragEnd(LatLng position){
    _getAddress(position: position);
  }
  void _centerCamera() async {
    await _controller.getVisibleRegion();
    var left = min(sourceLocation.latitude, destLocation.latitude);
    var right = max(sourceLocation.latitude, destLocation.latitude);
    var top = max(sourceLocation.longitude, destLocation.longitude);
    var bottom = min(sourceLocation.longitude, destLocation.longitude);
    _controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(left, bottom), northeast: LatLng(right, top)),
        50));
  }

  Future<List<webservice.Waypoint>> _buildWayPoint() async {
    PolylineResult result = await polylinePoints?.getRouteBetweenCoordinates(
      mapsApiKey,
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destLocation.latitude, destLocation.longitude),
    );
    List<webservice.Waypoint> polylineCoordinates = [];
    if (result.status == "OK") {
      // loop through all PointLatLng points and convert them
      // to a list of LatLng, required by the Polyline
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(webservice.Waypoint.fromLocation(
            webservice.Location(point.latitude, point.longitude)));
      });
    }
    return polylineCoordinates;
  }

  void _setPolylinesWebService() async {
    try {
      List<webservice.Waypoint> waypoints = await _buildWayPoint();
      var origin = webservice.Location(
          sourceLocation.latitude, sourceLocation.longitude);
      var destination =
          webservice.Location(destLocation.latitude, destLocation.longitude);
      webservice.DirectionsResponse result =
          await directionsApi.directionsWithLocation(origin, destination,
              travelMode: webservice.TravelMode.driving);
      if (result.isOkay) {
        var route = result.routes[0];
        var leg = route.legs[0];
        List<LatLng> polylineCoordinates = [];
        leg.steps.forEach((step) {
          //polylineCoordinates.add(LatLng(step.startLocation.lat,step.startLocation.lng));
          polylineCoordinates
              .add(LatLng(step.endLocation.lat, step.endLocation.lng));
        });
        setState(() {
          // create a Polyline instance
          // with an id, an RGB color and the list of LatLng pairs
          Polyline polyline = Polyline(
            polylineId: PolylineId("poly"),
            color: Color.fromARGB(255, 40, 122, 198),
            points: polylineCoordinates,
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
            width: 4,
          );

          // add the constructed polyline as a set of points
          // to the polyline set, which will eventually
          // end up showing up on the map
          _polylines.add(polyline);
        });
      }
    } catch (e) {}
  }

  void _setPolylinesPoly() async {
    //List<PointLatLng>  pathLines = polylinePoints?.decodePolyline("w_uPpfkjMbBsApC{BaEeF}CpEwFzFwE`CyJ`DnF~G");
    PolylineResult result = await polylinePoints?.getRouteBetweenCoordinates(
      mapsApiKey,
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destLocation.latitude, destLocation.longitude),
    );
    MatrixDirecctionServices matrixDirecction = MatrixDirecctionServices();
    MatrixDirection resultMatrix = await matrixDirecction.matrixDirecction(
      origin: LatLng(sourceLocation.latitude, sourceLocation.longitude),
      destination: LatLng(destLocation.latitude, destLocation.longitude),
    );
    _directionInformation = DirectionInformation(
      distance: resultMatrix.rows[0].elements[0].distance.text,
      duration: resultMatrix.rows[0].elements[0].duration.text,
      direction: "${placeDestination?.name}, ${placeDestination?.locality}"
    );
    _cardPosition = 0;
    List<LatLng> polylineCoordinates = [];
    if (result.status == "OK") {
      // loop through all PointLatLng points and convert them
      // to a list of LatLng, required by the Polyline
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    setState(() {
      // create a Polyline instance
      // with an id, an RGB color and the list of LatLng pairs
      Polyline polyline = Polyline(
        polylineId: PolylineId("poly"),
        color: Color.fromARGB(255, 40, 122, 198),
        points: polylineCoordinates,
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
        width: 4,
      );

      // add the constructed polyline as a set of points
      // to the polyline set, which will eventually
      // end up showing up on the map
      _polylines.add(polyline);
    });
  }

  void _setPolylines() async {
    _polylines.clear();
    //_setPolylinesWebService();
    _setPolylinesPoly();
  }

  void _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    _controller.setMapStyle(_mapStyle);

    await _getCurrentLocation();
    _setMarkers();
    //setPolylines();
    //_centerCamera();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Stack(children: <Widget>[
        Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            shape: BoxShape.circle
          ),
        ),
        Positioned(
          child: GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            initialCameraPosition: initialLocation,
            polylines: _polylines,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            onMapCreated: _onMapCreated,
            onTap: (LatLng location) {
              setState(() {
                _cardPosition = -100;
              });
            },
          ),
        ),
        Positioned(
            left: 15.0,
            right: 15.0,
            top: 45.0,
            child: Container(
              height: 50.0,
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.white),
              child: TextField(
                controller: _searchAdressController,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(Icons.my_location),
                    onPressed: () {},
                  ),
                  labelText: 'Dirección',
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10.0),
                    ),
                    borderSide: BorderSide(
                      color: Colors.grey[400],
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10.0),
                    ),
                    borderSide: BorderSide(
                      color: Colors.blue[300],
                      width: 2,
                    ),
                  ),
                  hintText: "Ingresa la direccion",
                ),
                onSubmitted: (String value) {
                  _getAddress(address: value);
                },
              ),
            )),
        MapPinPillComponent(
            pinPillPosition: _cardPosition,
            currentlySelectedPin: _directionInformation)
      ]),
    );
  }
}
