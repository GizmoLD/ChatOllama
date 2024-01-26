import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/*
- Convertir el mensaje en json
- Enviar el json y abrirlo en el servidor

*/

class AppData with ChangeNotifier {
  // Access appData globaly with:
  // AppData appData = Provider.of<AppData>(context);
  // AppData appData = Provider.of<AppData>(context, listen: false)

  bool loadingGet = false;
  bool loadingPost = false;
  bool loadingFile = false;

  dynamic dataGet;
  dynamic dataPost;
  dynamic dataFile;

  // Funció per fer crides tipus 'GET' i agafar la informació a mida que es va rebent
  Future<String> loadHttpGetByChunks(String url) async {
    var httpClient = HttpClient();
    var completer = Completer<String>();
    String result = "";

    // If development, wait 1 second to simulate a delay
    if (!kReleaseMode) {
      await Future.delayed(const Duration(seconds: 1));
    }

    try {
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();

      response.transform(utf8.decoder).listen(
        (data) {
          // Aquí rep cada un dels troços de dades que envia el servidor amb 'res.write'
          result += data;
        },
        onDone: () {
          completer.complete(result);
        },
        onError: (error) {
          completer.completeError(
              "Error del servidor (appData/loadHttpGetByChunks): $error");
        },
      );
    } catch (e) {
      completer.completeError("Excepció (appData/loadHttpGetByChunks): $e");
    }

    return completer.future;
  }

  // Funció per fer crides tipus 'POST' amb un arxiu adjunt,
  //i agafar la informació a mida que es va rebent
  Future<String> loadHttpPostByChunks(
      String url, File file, String messageType, String messageText) async {
    var completer = Completer<String>();
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Afegir les dades JSON com a part del formulari
    request.fields['data'] =
        '{"type": "$messageType", "message": "$messageText"}';
    // Adjunta l'arxiu com a part del formulari
    var stream = http.ByteStream(file.openRead());
    var length = await file.length();
    var multipartFile = http.MultipartFile('file', stream, length,
        filename: file.path.split('/').last,
        contentType: MediaType('application', 'octet-stream'));
    request.files.add(multipartFile);

    try {
      var response = await request.send();

      dataPost = "";

      // Listen to each chunk of data
      response.stream.transform(utf8.decoder).listen(
        (data) {
          print("Recibiendo datos...");
          // Aquí rep cada un dels troços de dades que envia el servidor amb 'res.write'
          // Decodificar el json de la respuesta para extrar el texto
          // var jsonData = json.decode(data);
          // String resposta = jsonData['text'];
          // print(resposta);

          dataPost += data;
          notifyListeners();
        },
        onDone: () {
          completer.complete(dataPost); // Complete with the accumulated data
        },
        onError: (error) {
          completer.completeError(
              "Error del servidor (appData/loadHttpPostByChunks): $error");
        },
      );
    } catch (e) {
      completer.completeError("Excepció (appData/loadHttpPostByChunks): $e");
    }

    return completer.future; // Return the future here
  }

  // Funció per fer carregar dades d'un arxiu json de la carpeta 'assets'
  Future<dynamic> readJsonAsset(String filePath) async {
    // If development, wait 1 second to simulate a delay
    if (!kReleaseMode) {
      await Future.delayed(const Duration(seconds: 1));
    }

    try {
      var jsonString = await rootBundle.loadString(filePath);
      final jsonData = json.decode(jsonString);
      return jsonData;
    } catch (e) {
      throw Exception("Excepció (appData/readJsonAsset): $e");
    }
  }

  // Carregar dades segons el tipus que es demana
  void load(String type,
      {File? selectedFile,
      required String messageType,
      required String messageText}) async {
    switch (type) {
      case 'GET':
        loadingPost = true;
        notifyListeners();

        // dataPost = await loadHttpPostByChunks('http://localhost:3000/data',
        //     selectedFile!, messageType, messageText);

        loadingPost = false;
        notifyListeners();
        break;
      case 'POST':
        loadingPost = true;
        notifyListeners();
        await loadHttpPostByChunks('http://localhost:3000/data', selectedFile!,
            messageType, messageText);
        loadingPost = false;
        notifyListeners();
        notifyListeners();
        break;
      case 'FILE':
        loadingFile = true;
        notifyListeners();

        var fileData = await readJsonAsset("assets/data/example.json");

        loadingFile = false;
        dataFile = fileData;
        notifyListeners();
        break;
    }
  }
}
