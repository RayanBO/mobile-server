import 'dart:io';

class Client {
  String ip;
  String name;

  Client(this.ip, this.name);

  // Factory method to create a Client object from HttpRequest
  factory Client.fromRequest(HttpRequest request) {
    var connectionInfo = request.connectionInfo;
    var remoteAddress = connectionInfo?.remoteAddress;
    String clientIp = remoteAddress?.address ?? 'Unknown';
    String clientName = 'Client_${DateTime.now().millisecondsSinceEpoch}'; // Default name
    return Client(clientIp, clientName);
  }
}
