import 'package:flutter/material.dart';
import 'package:google_maps_webservice/directions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;

class DirectionProvider extends ChangeNotifier{
  GoogleMapsDirections directionsApi = GoogleMapsDirections(
    apiKey: 'digite su api aquí'
  );
  Set<maps.Polyline> _route = Set();

  Set<maps.Polyline> get currenRoute => _route;
  
  findDirecctions(maps.LatLng from , maps.LatLng to) async{
    var origin = Location(from.latitude,from.longitude);
    var destination = Location(to.latitude,to.longitude);
    var result = await directionsApi.directionsWithLocation(origin, destination,travelMode: TravelMode.driving);
    
    Set<maps.Polyline> newRoute = Set();

    if(result.isOkay){
      var route = result.routes[0];
      var leg = route.legs[0];

      List<maps.LatLng> points = [];
      leg.steps.forEach((step) {
        
        points.add(maps.LatLng(step.startLocation.lat,step.startLocation.lng));
        points.add(maps.LatLng(step.endLocation.lat,step.endLocation.lng));
      });
      var line = maps.Polyline(
        points: points,
        color: Colors.red,
        polylineId: maps.PolylineId("Mejor ruta"),
        width: 4,
        startCap: maps.Cap.roundCap,
        endCap: maps.Cap.roundCap,
      );
      newRoute.add(line);
      _route = newRoute;

      notifyListeners();
    }
  }
}