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
  final List<ChatMessage> _messages = [];

  void _sendMessage() {
    ChatMessage _message = ChatMessage(text: _controller.text, sender: "user");

    setState(() {
      _messages.insert(0, _message);
    });

    _controller.clear();
  }

  // Return a custom button

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
      appData.load("POST", selectedFile: await pickFile());
    } catch (e) {
      if (kDebugMode) {
        print("Excepción (uploadFile): $e");
      }
    }
  }

  Widget _builderTextComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (value) {
              _sendMessage();
            },
            decoration: InputDecoration.collapsed(hintText: "Send a message"),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
            _sendMessage();
          },
        ),
      ],
    ).px64();
  }

  @override
  Widget build(BuildContext context) {
    AppData appData = Provider.of<AppData>(context);

    String stringGet = "";
    if (appData.loadingGet) {
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
          title: const Text("IetiChat"),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Flexible(
                child: ListView.builder(
                  reverse: true,
                  padding: Vx.m8,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _messages[index];
                    //return ListTile(
                    //  title: _messages[index],
                    //);
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(color: context.cardColor),
                child: _builderTextComposer(),
              ),
            ],
          ),
        ));
  }
}
