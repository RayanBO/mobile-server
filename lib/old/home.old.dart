import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  final int _port = 12345;
  late HttpServer _server;
  String _serverUrl = '';

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  void _startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _serverUrl = 'http://${_server.address.host}:$_port';
      print('Serveur démarré sur $_serverUrl');
      setState(() {});
      _server.listen((HttpRequest request) {
        if (request.method == 'GET') {
          _handleGetRequest(request);
        } else if (request.method == 'POST') {
          _handlePostRequest(request);
        }
      });
    } catch (e) {
      print('Erreur lors du démarrage du serveur : $e');
    }
  }

  void _handleGetRequest(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(_buildChatUI());
    request.response.close();
  }

  String _buildChatUI() {
    return '''
    <!DOCTYPE html>
    <html>
      <head>
        <title>Chat</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
      </head>
      <body>
        <h1>Chat</h1>
        <div id="messages"></div>
        <input type="text" id="messageInput">
        <button onclick="sendMessage()">Send</button>
        <script>
          function sendMessage() {
            var message = document.getElementById('messageInput').value;
            var xhr = new XMLHttpRequest();
            xhr.open('POST', '/', true);
            xhr.setRequestHeader('Content-Type', 'application/json');
            xhr.send(JSON.stringify({message: message}));
            document.getElementById('messageInput').value = '';
          }

          setInterval(getMessages, 1000);

          function getMessages() {
            var xhr = new XMLHttpRequest();
            xhr.onreadystatechange = function() {
              if (xhr.readyState == 4 && xhr.status == 200) {
                var messages = JSON.parse(xhr.responseText);
                var messagesHtml = '';
                for (var i = 0; i < messages.length; i++) {
                  messagesHtml += '<p>' + messages[i] + '</p>';
                }
                document.getElementById('messages').innerHTML = messagesHtml;
              }
            };
            xhr.open('GET', '/', true);
            xhr.send();
          }
        </script>
      </body>
    </html>
    ''';
  }

  void _handlePostRequest(HttpRequest request) async {
    try {
      String content = await utf8.decoder.bind(request).join();
      Map<String, dynamic> data = json.decode(content);
      String message = data['message'];
      _messages.add(message);
      print('Message reçu : $message');
    } catch (e) {
      print('Erreur lors de la réception du message : $e');
    } finally {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(json.encode(_messages));
      request.response.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Chat Server'),
      ),
      body: Center(
        child: Text(
          _serverUrl.isNotEmpty
              ? 'Serveur démarré sur : $_serverUrl'
              : 'Démarrage du serveur en cours...',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _server.close();
    super.dispose();
  }
}
