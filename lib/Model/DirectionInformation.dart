import 'package:google_maps_flutter/google_maps_flutter.dart';


class DirectionInformation{
  String distance;
  String direction;
  String duration;
  String mode;
  LatLng location;
  DirectionInformation({
    this.distance,
    this.duration,
    this.direction,
    this.mode,
    this.location
  });
}