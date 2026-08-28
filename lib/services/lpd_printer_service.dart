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
    bool isDuplex = true,
  }) async {
    final Socket socket = await Socket.connect(
      printerIp,
      port,
      timeout: const Duration(seconds: 8),
    );

    final responseStream = StreamIterator(socket);

    try {
      // Prepare bytes with hardware commands if duplexing is requested
      Uint8List finalBytes = fileBytes;
      if (isDuplex) {
        const String pjlHeader = '\x1b%-12345X@PJL\r\n'
            '@PJL SET DUPLEX=ON\r\n'
            '@PJL SET BINDING=LONGEDGE\r\n';
        const String pjlFooter = '\x1b%-12345X';

        final builder = BytesBuilder();
        builder.add(utf8.encode(pjlHeader));
        builder.add(fileBytes);
        builder.add(utf8.encode(pjlFooter));
        finalBytes = builder.toBytes();
      }

      // 1. Send Receive Printer Job command: \x02 + queueName + \n
      socket.add(utf8.encode('\x02$queueName\n'));
      await _readAck(responseStream);

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
      await _readAck(responseStream);

      socket.add(cfBytes);
      socket.add([0x00]);
      await _readAck(responseStream);

      // 3. Command: Receive Data File
      socket.add(
          utf8.encode('\x03${finalBytes.length} dfA$jobNum$hostName\n'));
      await _readAck(responseStream);

      socket.add(finalBytes);
      socket.add([0x00]);
      await _readAck(responseStream);
    } finally {
      await responseStream.cancel();
      await socket.close();
    }
  }

  Future<void> _readAck(StreamIterator<Uint8List> iterator) async {
    if (!await iterator.moveNext().timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    )) {
      throw Exception('LPD protocol error: No response from printer (timeout)');
    }

    final response = iterator.current;
    if (response.isEmpty || response[0] != 0x00) {
      throw Exception(
          'LPD protocol error from printer (ACK code: ${response.isEmpty ? 'none' : response[0]})');
    }
  }
}