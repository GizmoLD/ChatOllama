import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_postget/chat_message.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AppData with ChangeNotifier {
  bool loadingGet = false;
  bool loadingPost = false;
  bool loadingFile = false;
  List<ChatMessage> messages = [];
  String currentMessageText =
      ''; // Variable para almacenar el texto del mensaje actual

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
    if (messageType == 'conversa') {
      request.fields['data'] =
          '{"type": "$messageType", "message": "$messageText"}';
    } else if (messageType == 'imatge') {
      request.fields['data'] = '{"type": "$messageType"}';
    }
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
          var jsonData = json.decode(data);
          String resposta = jsonData['conversa'];
          print(resposta);

          dataPost += resposta;
          if (messages.isNotEmpty) {
            messages[0] = messages[0].withText(dataPost);
          }
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
        await loadHttpGetByChunks(
            'http://localhost:3000/llistat?cerca=motos&color=vermell');
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
