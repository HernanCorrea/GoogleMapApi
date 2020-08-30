import 'package:flutter/material.dart';
import 'package:googlemaps/MapaFindDirections.dart';
import 'package:googlemaps/directionsProvider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DirectionProvider(),
      child: MaterialApp(
        title: 'Mapas',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MapaFindDirections(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
