import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'printer_utils.dart';

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
    String queueName = 'secure',
    bool isDuplex = true,
  }) async {
    final Socket socket = await Socket.connect(
      printerIp,
      port,
      timeout: const Duration(seconds: 8),
    );

    final responseStream = StreamIterator(socket);

    try {
      // 1. Process document data
      Uint8List processedBytes = fileBytes;
      if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) {
        processedBytes = PrinterUtils.wrapJpegInPdf(fileBytes);
      }

      // 2. Apply PJL hardware commands if requested
      Uint8List finalBytes = processedBytes;
      if (isDuplex) {
        final prefix = PrinterUtils.generatePjlPrefix(isDuplex: true);
        final builder = BytesBuilder();
        builder.add(utf8.encode(prefix));
        builder.add(processedBytes);
        builder.add(utf8.encode(PrinterUtils.pjlFooter));
        finalBytes = builder.toBytes();
      }

      // 3. Initiate LPD Protocol: Send Receive Printer Job command
      socket.add(utf8.encode('\x02$queueName\n'));
      await _readAck(responseStream);

      const String hostName = 'BRACU-Mobile';
      final String jobNum = '${DateTime.now().millisecondsSinceEpoch % 1000}'.padLeft(3, '0');

      // 4. Send LPD Control File
      final String controlFile = PrinterUtils.generateControlFile(
        hostName: hostName,
        username: username,
        jobNum: jobNum,
        fileName: fileName,
      );
      final Uint8List cfBytes = Uint8List.fromList(utf8.encode(controlFile));

      socket.add(utf8.encode('\x02${cfBytes.length} cfA$jobNum$hostName\n'));
      await _readAck(responseStream);

      socket.add(cfBytes);
      socket.add([0x00]);
      await _readAck(responseStream);

      // 5. Send LPD Data File
      socket.add(utf8.encode('\x03${finalBytes.length} dfA$jobNum$hostName\n'));
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
