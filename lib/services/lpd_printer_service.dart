import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class LpdPrinterService {
  final String printerIp;
  final int port;

  LpdPrinterService({
    this.printerIp = '10.10.0.50',
    this.port = 515,
  });

  /// Transmits document bytes over low-level LPD protocol (RFC 1179)
  Future<void> sendPrintJob({
    required Uint8List fileBytes,
    required String fileName,
    required String username,
    String queueName = 'raw',
  }) async {
    final Socket socket = await Socket.connect(
      printerIp,
      port,
      timeout: const Duration(seconds: 8),
    );

    try {
      // 1. Send Receive Printer Job command: \x02 + queueName + \n
      socket.add(utf8.encode('\x02$queueName\n'));
      await _readAck(socket);

      const String hostName = 'BRACU-Mobile';
      final String jobNum =
          '${DateTime.now().millisecondsSinceEpoch % 1000}'.padLeft(3, '0');

      // LPD Control File format
      final String controlFile =
          'H$hostName\nP$username\nfdfA$jobNum$hostName\nN$fileName\n';
      final Uint8List cfBytes = Uint8List.fromList(utf8.encode(controlFile));

      // 2. Command: Receive Control File
      socket.add(
          utf8.encode('\x02${cfBytes.length} cfA$jobNum$hostName\n'));
      await _readAck(socket);

      socket.add(cfBytes);
      socket.add([0x00]);
      await _readAck(socket);

      // 3. Command: Receive Data File
      socket.add(
          utf8.encode('\x03${fileBytes.length} dfA$jobNum$hostName\n'));
      await _readAck(socket);

      socket.add(fileBytes);
      socket.add([0x00]);
      await _readAck(socket);
    } finally {
      await socket.close();
    }
  }

  Future<void> _readAck(Socket socket) async {
    await socket.flush();
    final Uint8List response = await socket.first.timeout(
      const Duration(seconds: 5),
      onTimeout: () => Uint8List.fromList([0x01]),
    );

    if (response.isEmpty || response[0] != 0x00) {
      throw Exception(
          'LPD protocol error from printer (ACK code: ${response.isEmpty ? 'none' : response[0]})');
    }
  }
}