import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googlemaps/Model/PinPillInformation.dart';
import 'package:googlemaps/conf/configuration.dart';



List<PointLatLng> pathLines = [
  PointLatLng(2.898038, -75.265210),
  PointLatLng(2.896857, -75.264102),
  PointLatLng(2.897757, -75.263024),
  PointLatLng(2.898526, -75.263974),
  PointLatLng(2.901562, -75.266240),
  PointLatLng(2.902678, -75.266785),
  PointLatLng(2.902416, -75.267272),
  PointLatLng(2.901580, -75.268228),
];

class MapaPolyline extends StatefulWidget {
  @override
  _MapaPolylineState createState() => _MapaPolylineState();
}

class _MapaPolylineState extends State<MapaPolyline> {
  GoogleMapController _controller;
  // this set will hold my markers
  Set<Marker> _markers = {};
  // this will hold the generated polylines
  Set<Polyline> _polylines = {};
  // this will hold each polyline coordinate as Lat and Lng pairs
  List<LatLng> polylineCoordinates = [];
  // this is the key object - the PolylinePoints
  // which generates every polyline between start and finish
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPIKey = mapsApiKey;
  // for my custom icons
  BitmapDescriptor sourceIcon;
  BitmapDescriptor destinationIcon;
  //Style of my map
  String _mapStyle;
  //Show the state  animation of Container
  double pinPillPosition = -100;
  PinInformation currentlySelectedPin = PinInformation(
    pinPath: '',
    avatarPath: '',
    location: LatLng(0, 0),
    locationName: '',
    labelColor: Color(0xFFFF8A80),
  );
  PinInformation sourcePinInfo;
  PinInformation destinationPinInfo;

  @override
  void initState() {
    super.initState();
    setSourceAndDestinationIcons();
    setMapStyle();
  }

  void setSourceAndDestinationIcons() async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        "lib/images/driving_pin.png");
    destinationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        "lib/images/destination_map_marker.png");
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialLocation = CameraPosition(
        zoom: CAMERA_ZOOM,
        bearing: CAMERA_BEARING,
        tilt: CAMERA_TILT,
        target: SOURCE_LOCATION);

    return Stack(children: <Widget>[
      SafeArea(
              child: GoogleMap(
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: _markers,
          initialCameraPosition: initialLocation,
          polylines: _polylines,
          mapType: MapType.normal,
          zoomControlsEnabled: false,
          onMapCreated: _onMapCreated,
          onTap: (LatLng location) {
            setState(() {
              pinPillPosition = -100;
            });
          },
        ),
      ),
      
    ]);
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _controller.setMapStyle(_mapStyle);
    setMapPins();
    setPolylines();
    _centrarMapa();
  }

  void setMapPins() {
    setState(() {
      // START PIN
      _markers.add(Marker(
        markerId: MarkerId("sourcePin"),
        position: SOURCE_LOCATION,
        icon: sourceIcon,
        onTap: () {
          setState(() {
            print(pinPillPosition);
            currentlySelectedPin = sourcePinInfo;
            pinPillPosition = 0;
          });
        },
      ));
      // START PIN INFO
      sourcePinInfo = PinInformation(
          locationName: "Start Location",
          location: SOURCE_LOCATION,
          pinPath: "lib/images/driving_pin.png",
          avatarPath: "lib/images/avatar_1.png",
          labelColor: Colors.blueAccent);
      // DESTINATION pin
      _markers.add(Marker(
        markerId: MarkerId("destPin"),
        position: DEST_LOCATION,
        icon: destinationIcon,
        onTap: () {
          setState(() {
            currentlySelectedPin = destinationPinInfo;
            pinPillPosition = 0;
          });
        },
      ));
      destinationPinInfo = PinInformation(
          locationName: "End Location",
          location: DEST_LOCATION,
          pinPath: "lib/images/driving_pin.png",
          avatarPath: "lib/images/avatar_2.png",
          labelColor: Colors.purple);
    });
  }

  void _centrarMapa() async {
    await _controller.getVisibleRegion();
    var left = min(SOURCE_LOCATION.latitude, DEST_LOCATION.latitude);
    var right = max(SOURCE_LOCATION.latitude, DEST_LOCATION.latitude);
    var top = max(SOURCE_LOCATION.longitude, DEST_LOCATION.longitude);
    var bottom = min(SOURCE_LOCATION.longitude, DEST_LOCATION.longitude);
    _controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(left, bottom), northeast: LatLng(right, top)),
        50));
  }

  void setPolylines() async {
    List<PointLatLng>  pathLines = polylinePoints?.decodePolyline("k_uPt`kjMi@`@gAz@k@h@h@r@`@]x@q@|@q@");
    /*PolylineResult result = await polylinePoints?.getRouteBetweenCoordinates(
      googleAPIKey,
      PointLatLng(SOURCE_LOCATION.latitude, SOURCE_LOCATION.longitude),
      PointLatLng(DEST_LOCATION.latitude, DEST_LOCATION.longitude),
    );*/
    if (pathLines.length > 0) {
      // loop through all PointLatLng points and convert them
      // to a list of LatLng, required by the Polyline
      pathLines.forEach((PointLatLng point) {
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

  void setMapStyle() {
    rootBundle.loadString('lib/images/styles/map_styles.txt').then((string) {
      _mapStyle = string;
    });
  }
}
