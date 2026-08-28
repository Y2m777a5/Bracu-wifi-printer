import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:bracu_wifi_printer/services/printer_utils.dart';

void main() {
  group('PrinterUtils Logic Tests', () {
    test('generateControlFile produces RFC 1179 compliant control string', () {
      final control = PrinterUtils.generateControlFile(
        hostName: 'TestHost',
        username: 'student',
        jobNum: '123',
        fileName: 'assignment.pdf',
      );

      expect(control, contains('HTestHost'));
      expect(control, contains('Pstudent'));
      expect(control, contains('fdfA123TestHost'));
      expect(control, contains('Nassignment.pdf'));
      expect(control.endsWith('\n'), isTrue);
    });

    test('generatePjlPrefix includes DUPLEX commands when enabled', () {
      final prefix = PrinterUtils.generatePjlPrefix(isDuplex: true);

      expect(prefix, contains('\x1b%-12345X@PJL\r\n'));
      expect(prefix, contains('@PJL SET DUPLEX=ON'));
      expect(prefix, contains('@PJL SET BINDING=LONGEDGE'));
    });

    test('generatePjlPrefix is empty when duplex is disabled', () {
      final prefix = PrinterUtils.generatePjlPrefix(isDuplex: false);
      expect(prefix, isEmpty);
    });

    test('wrapJpegInPdf generates valid A4 PDF header and image filter', () {
      final fakeJpeg = Uint8List.fromList([
        0xFF, 0xD8, // SOI
        0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, // APP0
        0xFF, 0xD9, // EOI
      ]);
      
      final pdfBytes = PrinterUtils.wrapJpegInPdf(fakeJpeg);
      final pdfText = latin1.decode(pdfBytes, allowInvalid: true);

      expect(pdfText, contains('%PDF-1.4'));
      expect(pdfText, contains('/MediaBox [0 0 595 842]'));
      expect(pdfText, contains('/Filter /DCTDecode'));
      expect(pdfText, contains('%%EOF'));
      
      // Verify xref table structure
      expect(pdfText, contains('xref\n0 6'));
      expect(pdfText, contains('0000000000 65535 f'));
    });

    test('wrapJpegInPdf extracts custom dimensions from JPEG header', () {
      // Fake JPEG with SOF0 (Start of Frame) containing dimensions: 100x200
      final fakeJpeg = Uint8List.fromList([
        0xFF, 0xD8,
        0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0xC8, 0x00, 0x64, 0x03, 0x01, 0x22, 0x00,
        0xFF, 0xD9,
      ]);
      
      final pdfBytes = PrinterUtils.wrapJpegInPdf(fakeJpeg);
      final pdfText = latin1.decode(pdfBytes, allowInvalid: true);

      // Verify dimensions were parsed: Width 100 (0x64), Height 200 (0xC8)
      expect(pdfText, contains('/Width 100'));
      expect(pdfText, contains('/Height 200'));
    });
  });
}
