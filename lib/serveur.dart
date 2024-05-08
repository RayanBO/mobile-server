import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

class Serveur extends StatefulWidget {
  Serveur({Key? key}) : super(key: key);

  @override
  _ServeurState createState() => _ServeurState();
}

class _ServeurState extends State<Serveur> {
  final List<String> _messages = [];
  final List<String> _clients = [];
  final int _port = 12345;
  late HttpServer _server;
  String _serverUrl = '';
  Stopwatch _stopwatch = Stopwatch();
  String _elapsedTime = '';

  @override
  void initState() {
    super.initState();
    _startServer();
    _stopwatch.start();
    _startTimer();
  }

  void _startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      setState(() {
        _serverUrl = 'http://${_server.address.host}:$_port';
      });
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

  void _handleGetRequest(HttpRequest request) async {
    try {
      var params = request.uri.queryParameters;
      if (params.containsKey('type')) {
        _handleGetRequest_json(request);
      } else {
        _handleGetRequest_html(request);
      }
    } catch (e) {
      print('Erreur lors de la réponse à la demande GET : $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.close();
    }
  }

  void _handleGetRequest_html(HttpRequest request) async {
    try {
      String content = await rootBundle.loadString('assets/client.html');
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(content);
    } catch (e) {
      print('Error while loading client.html: $e');
      request.response.statusCode = HttpStatus.notFound;
    } finally {
      request.response.close();
    }
  }

  void _handleGetRequest_json(HttpRequest request) async {
    try {
      // Renvoyer une réponse contenant les messages et les clients connectés
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(json.encode({'messages': _messages, 'clients': _clients}));
    } catch (e) {
      print('Erreur lors de la réponse à la demande GET : $e');
      request.response.statusCode = HttpStatus.internalServerError;
    } finally {
      request.response.close();
    }
  }

  void _handlePostRequest(HttpRequest request) async {
    try {
      String content = await utf8.decoder.bind(request).join();
      Map<String, dynamic> data = json.decode(content);

      // Stocker le message et l'information client
      String message = data['message'];
      _messages.add(message);

      var connectionInfo = await request.connectionInfo;
      var remoteAddress = connectionInfo
          ?.remoteAddress; 
      if (remoteAddress != null) {
        String clientIp = remoteAddress.address;
        _clients.add(clientIp);
      } else {
        print('Erreur: Adresse IP du client non disponible.');
      }

      print('Message reçu : $message');
    } catch (e) {
      print('Erreur lors de la réception du message : $e');
    } finally {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(json.encode({'messages': _messages, 'clients': _clients}));
      request.response.close();
    }
  }

  void _startTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = _formatDuration(_stopwatch.elapsed);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Chat Server'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _serverUrl.isNotEmpty
                  ? 'Serveur démarré sur : $_serverUrl'
                  : 'Démarrage du serveur en cours...',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              'Temps écoulé: $_elapsedTime',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _clients.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Client: ${_clients[index]}'),
                    subtitle: Text('Message: ${_messages[index]}'),
                  );
                },
              ),
            ),
          ],
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