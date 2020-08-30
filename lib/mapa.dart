import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'directionsProvider.dart';

class Mapa extends StatefulWidget {
  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  final LatLng puntoInicio = LatLng(2.898278, -75.263580);
  final LatLng puntoFinal = LatLng(2.905480, -75.270731);
  GoogleMapController controller;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Google Maps"),
      ),
      body: Consumer<DirectionProvider>(
        builder: (BuildContext context, DirectionProvider api, child) {
          return GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: puntoInicio,
              zoom: 12,
            ),
            polylines: api.currenRoute,
            markers: _crearMarcadores(),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.star), onPressed: _centrarMapa),
    );
  }

  Set<Marker> _crearMarcadores() {
    var marcador = Set<Marker>();
    marcador.add(Marker(
        markerId: MarkerId("Punto de partida"),
        position: puntoInicio,
        infoWindow: InfoWindow(title: "Hernan Correa")));
    marcador.add(Marker(
      markerId: MarkerId("Punto de destino"),
      position: puntoFinal,
    ));
    return marcador;
  }

  void _onMapCreated(GoogleMapController controller) {
    this.controller = controller;
    _centrarMapa();
 
  }

  void _centrarMapa() async {
    var api = Provider.of<DirectionProvider>(context,listen: false);
    api.findDirecctions(puntoInicio, puntoFinal);
    await controller.getVisibleRegion();
    var left = min(puntoInicio.latitude, puntoFinal.latitude);
    var right = max(puntoInicio.latitude, puntoFinal.latitude);
    var top = max(puntoInicio.longitude, puntoFinal.longitude);
    var bottom = min(puntoInicio.longitude, puntoFinal.longitude);
    controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(left, bottom), northeast: LatLng(right, top)),
        50));
  }
}
