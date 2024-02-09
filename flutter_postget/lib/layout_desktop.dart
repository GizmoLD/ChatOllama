import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cupertino_desktop_kit/cdk.dart';
import 'package:flutter_postget/chat_message.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';

import 'app_data.dart';

class LayoutDesktop extends StatefulWidget {
  const LayoutDesktop({super.key});

  @override
  State<LayoutDesktop> createState() => _LayoutDesktopState();
}

class _LayoutDesktopState extends State<LayoutDesktop> {
  final TextEditingController _controller = TextEditingController();
  File mensajeJson = File('assets/data/conversa.json');
  File imagenJson = File('assets/data/imatge.json');

  void updateJsonFile(String type, String messageText, {File? imagen}) {
    if (type == "conversa") {
      // Read the existing JSON file
      File jsonFile = File('assets/data/conversa.json');
      String jsonContent = jsonFile.readAsStringSync();

      // Parse the existing JSON content
      Map<String, dynamic> jsonData = json.decode(jsonContent);

      // Update the "prompt" field with the new message
      jsonData['prompt'] = messageText;

      // Convert the updated data back to JSON
      String updatedJson = json.encode(jsonData);

      // Write the updated JSON back to the file
      jsonFile.writeAsStringSync(updatedJson);
    } else if (type == "imatge") {
      // Read the existing JSON file
      File jsonFile = File('assets/data/imatge.json');
      String jsonContent = jsonFile.readAsStringSync();

      // Parse the existing JSON content
      Map<String, dynamic> jsonData = json.decode(jsonContent);

      // encode the image to base64
      String base64Image = base64Encode(imagen!.readAsBytesSync());

      // Update the "images" field with the new message
      jsonData['images'] = [base64Image];

      // Convert the updated data back to JSON
      String updatedJson = json.encode(jsonData);

      // Write the updated JSON back to the file
      jsonFile.writeAsStringSync(updatedJson);
    }
  }

  void _sendMessage(
      AppData appData, String messageSender, String messageText) async {
    // Create a message object

    ChatMessage message = ChatMessage(text: messageText, sender: messageSender);
    ChatMessage messageBot = ChatMessage(text: "", sender: "Ollama");

    // Update UI with the new message
    setState(() {
      if (messageText.isNotEmpty) {
        appData.messages.insert(0, message);
        appData.messages.insert(0, messageBot);
      }
    });

    try {
      if (messageText.isNotEmpty) {
        updateJsonFile('conversa', messageText);

        // If the message is text, send it as 'conversa' type
        String result = await appData.loadHttpPostByChunks(
            'http://localhost:3000/data', mensajeJson, 'conversa', messageText);

        // Use 'result' as needed
        ChatMessage serverResponseMessage =
            ChatMessage(text: result, sender: "Ollama");

        //appData.messages.insert(0, serverResponseMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al enviar mensaje: $e");
      }
    }
  }

  // Función para seleccionar un archivo
  Future<File> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      return file;
    } else {
      throw Exception("No se ha seleccionado ningún archivo.");
    }
  }

  // Función para cargar el archivo seleccionado con una solicitud POST
  Future<void> uploadFile(AppData appData) async {
    try {
      File imagen = await pickFile();
      updateJsonFile('imatge', '', imagen: imagen);

      appData.load("POST",
          selectedFile: imagenJson, messageType: 'image', messageText: '');
    } catch (e) {
      if (kDebugMode) {
        print("Excepción (uploadFile): $e");
      }
    }
  }

  Widget _builderTextComposer(AppData appData) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 8.0), // Adjust the horizontal margin as needed
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20.0), // Set your desired border radius
        border: Border.all(
            color: const Color.fromARGB(
                255, 234, 213, 213)), // Add a border for better visibility
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (value) {
                _sendMessage(appData, "User", _controller.text);
                _controller.clear();
              },
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0), // Adjust padding as needed
                hintText: "Send a message",
                border: InputBorder.none, // Remove the default border
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () {
              // Enviar un GET para parar la respuesta
              appData.load("GET",
                  selectedFile: null, messageType: '', messageText: '');
            },
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              _sendMessage(appData, "User", _controller.text);
              _controller.clear();
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              uploadFile(appData);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppData appData = Provider.of<AppData>(context);

    String stringGet = "";
    if (appData.loadingGet && appData.dataGet == "") {
      stringGet = "Loading ...";
    } else if (appData.dataGet != null) {
      stringGet = "GET: ${appData.dataGet.toString()}";
    }

    String stringPost = "";
    if (appData.loadingPost) {
      stringPost = "Loading ...";
    } else if (appData.dataPost != null) {
      stringPost = "GET: ${appData.dataPost.toString()}";
    }

    String stringFile = "";
    if (appData.loadingFile) {
      stringFile = "Loading ...";
    } else if (appData.dataFile != null) {
      stringFile = "File: ${appData.dataFile}";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            "IetiChat",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(
                    left: 20, top: 20, right: 20, bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: const Color.fromARGB(255, 227, 240, 247),
                ),
                child: ListView.builder(
                  reverse: true,
                  padding: Vx.m8,
                  itemCount: appData.messages.length,
                  itemBuilder: (context, index) {
                    return appData.messages[index];
                  },
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(color: context.cardColor),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 20, end: 20, bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _builderTextComposer(appData),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
