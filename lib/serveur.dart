import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

import 'client.dart';

class Serveur extends StatefulWidget {
  Serveur({Key? key}) : super(key: key);

  @override
  _ServeurState createState() => _ServeurState();
}

class _ServeurState extends State<Serveur> {
  final List<String> _messagess = [];
  final List<String> _clientss = [];
  List<Client> clients = [];
  List<Message> messages = [];

  final int _port = 12345;
  late HttpServer _server;
  String _serverUrl = '';
  Stopwatch _stopwatch = Stopwatch();
  String _elapsedTime = '';
  String notyf = '';

  @override
  void initState() {
    super.initState();
    _startServer();
    _stopwatch.start();
    _startTimer();
  }

  void setNotify(String message) {
    setState(() {
      notyf = message;
    });
    print(notyf);

    Future.delayed(Duration(seconds: 20), () {
      setState(() {
        notyf = '';
      });
    });
  }

  void _startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      setState(() {
        _serverUrl = 'http://${_server.address.host}:$_port';
      });
      setNotify('Serveur démarré sur $_serverUrl');

      _server.listen((HttpRequest request) {
        if (request.method == 'GET') {
          _handleGetRequest(request);
        } else if (request.method == 'POST') {
          _handlePostRequest(request);
        }
      });
    } catch (e) {
      setNotify('Erreur lors du démarrage du serveur : $e');
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
      setNotify('Erreur lors de la réponse à la demande GET : $e');
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
      setNotify('Error while loading client.html: $e');
      request.response.statusCode = HttpStatus.notFound;
    } finally {
      request.response.close();
    }
  }

  void _handleGetRequest_json(HttpRequest request) async {
    List ms = [];
    messages.forEach((m) {
      ms.add(m.json());
    });
    try {
      // Renvoyer une réponse contenant les messages et les clients connectés
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(json.encode({'messages': ms}));
    } catch (e) {
      setNotify('Erreur lors de la réponse à la demande GET : $e');
      request.response.statusCode = HttpStatus.internalServerError;
    } finally {
      request.response.close();
    }
  }

  String getIpClient(connectionInfo) {
    var remoteAddress = connectionInfo?.remoteAddress;
    String clientIp = '';
    if (remoteAddress != null) {
      clientIp = remoteAddress.address;
    } else {
      setNotify('Erreur: Adresse IP du client non disponible.');
    }
    return clientIp;
  }

  void _handlePostRequest(HttpRequest request) async {
    try {
      String content = await utf8.decoder.bind(request).join();
      Map<String, dynamic> data = json.decode(content);
      String type = data['type'] ?? '';
      String pseudo = data['pseudo'] ?? '';
      String message = data['message'] ?? '';
      var connectionInfo = await request.connectionInfo;
      var ipClient = getIpClient(connectionInfo);
      print('POST $data');

      switch (type) {
        case 'init':
          print('POST : Init');
          clients.add(Client(ipClient.toString(), pseudo.toString()));
          break;
        case 'pseudo':
          print('POST : Pseudo');
          setState(() {
            clients.forEach((client) {
              if (client.ip == ipClient) {
                client.setPseudo(pseudo);
              }
            });
          });
          break;
        default: // message
          // _messages.add(message);
          print('POST : Message');
          setState(() {
            clients.forEach((client) {
              if (client.ip == ipClient) {
                messages.add(Message(message, client));
              }
            });
          });
      }
    } catch (e) {
      setNotify('Erreur lors de la réception du message : $e');
    } finally {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        // ..write(json.encode({'messages': _messages, 'clients': _clients}));
        ..write(json.encode({'type': 'Okok'}));
      request.response.close();
    }
  }

  void _startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
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
        title: const Text('BO Serveur'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _serverUrl.isNotEmpty
                  ? 'Serveur démarré sur : $_serverUrl'
                  : 'Démarrage du serveur en cours...',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              'Temps écoulé: $_elapsedTime',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              'Log : $notyf',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            Column(
              children: clients.map((c) {
                return Text('Client : ${c.ip} | pseudo : ${c.pseudo}');
              }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                        'Client: ${messages[index].client.pseudo} | ${messages[index].client.ip}'),
                    subtitle: Text('Message: ${messages[index].message}'),
                    leading:
                        Text('date: ${messages[index].dateTime.toString()}'),
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
