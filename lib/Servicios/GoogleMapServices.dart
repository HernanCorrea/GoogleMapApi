import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemaps/Model/MatrixDirection.dart';
import 'package:googlemaps/conf/configuration.dart';
import 'package:http/http.dart' as httpClient;

class MatrixDirecctionServices{
  final api = "https://maps.googleapis.com/maps/api";
  Future<MatrixDirection> matrixDirecction(
    {
    LatLng origin,
    LatLng destination,
    
  }) async {
    String origen = "${origin.latitude},${origin.longitude}";
    String destino = "${destination.latitude},${destination.longitude}";
    final url = "$api/distancematrix/json?units=metric&origins=$origen&destinations=$destino&mode=driving&key=$mapsApiKey";
    return _decode(await httpGet(url));
  }
  
  MatrixDirection _decode(httpClient.Response res){
    return MatrixDirection.fromJson(json.decode(res.body));
  }
  Future<httpClient.Response> httpGet(String url) => httpClient.get(url);
}