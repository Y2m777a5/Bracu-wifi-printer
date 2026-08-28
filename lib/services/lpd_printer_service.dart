import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class LpdPrinterService {
  final String printerIp;
  final int port;

  LpdPrinterService({
    this.printerIp = '10.10.0.50', // BRACU Campus Print Queue IP
    this.port = 515,               // Standard LPD TCP Port
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

      // Generate job identifier metadata
      final String hostName = 'BRACU-Mobile';
      final String jobNum =
          '${DateTime.now().millisecondsSinceEpoch % 1000}'.padLeft(3, '0');

      // LPD Control File format (H=host, P=user, N=filename, f=datafile)
      final String controlFile =
          'H$hostName\nP$username\nfdfA$jobNum$hostName\nN$fileName\n';
      final Uint8List cfBytes = Uint8List.fromList(utf8.encode(controlFile));

      // 2. Command: Receive Control File (\x02 + size + space + cfA... + \n)
      socket.add(
          utf8.encode('\x02${cfBytes.length} cfA$jobNum$hostName\n'));
      await _readAck(socket);

      // Send Control File content followed by zero byte
      socket.add(cfBytes);
      socket.add([0x00]);
      await _readAck(socket);

      // 3. Command: Receive Data File (\x03 + size + space + dfA... + \n)
      socket.add(
          utf8.encode('\x03${fileBytes.length} dfA$jobNum$hostName\n'));
      await _readAck(socket);

      // Send Data File payload followed by zero byte
      socket.add(fileBytes);
      socket.add([0x00]);
      await _readAck(socket);
    } finally {
      await socket.close();
    }
  }

  Future<void> _readAck(Socket socket) async {
    await socket.flush();
    final List<int> response = await socket.first.timeout(
      const Duration(seconds: 5),
      onTimeout: () => [0x01],
    );

    if (response.isEmpty || response[0] != 0x00) {
      throw Exception(
          'LPD protocol error from printer (ACK code: ${response.isEmpty ? 'none' : response[0]})');
    }
  }
}
