import 'package:flutter/material.dart'; // Importa el paquete Material
import 'layout_desktop.dart';

// Main application widget
class App extends StatefulWidget {
  const App({super.key});

  @override
  AppState createState() => AppState();
}

// Main application state
class AppState extends State<App> {
  // Define the layout to use depending on the screen width
  Widget _setLayout(BuildContext context) {
    return MaterialApp(
      // Cambia a MaterialApp
      title: "XatIETI",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const LayoutDesktop(),
    );
  }

  // Definir el contenido del widget 'App'
  @override
  Widget build(BuildContext context) {
    return _setLayout(context);
  }
}
