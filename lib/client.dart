import 'dart:core';

class Client {
  String ip;
  String pseudo;
  DateTime entry;

  Client(this.ip, this.pseudo) : entry = DateTime.now();

  void setPseudo(String newPseudo) {
    pseudo = newPseudo;
  }
}

class Message {
  String message;
  Client client;
  DateTime dateTime;

  Message(this.message, this.client) : dateTime = DateTime.now();

  Map json() {
    return {'message': message, 'client': client.pseudo.toString(), 'dateTime': dateTime.toString()};
  }
}
