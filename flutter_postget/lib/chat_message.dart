import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({Key? key, required this.text, required this.sender})
      : super(key: key);

  final String text;
  final String sender;

  // Método para crear una instancia de ChatMessage con un texto actualizable
  ChatMessage withText(String newText) {
    return ChatMessage(key: key, sender: sender, text: newText);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Añadido aquí
      children: [
        Container(
          margin: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            child: Text(sender[0]),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sender,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                margin: const EdgeInsets.only(top: 1.0),
                child: Text(
                  text,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
