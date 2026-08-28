import 'dart:convert';
import 'dart:typed_data';

class PrinterUtils {
  static const String pjlHeader = '\x1b%-12345X@PJL\r\n';
  static const String pjlFooter = '\x1b%-12345X';

  /// Generates the LPD control file content
  static String generateControlFile({
    required String hostName,
    required String username,
    required String jobNum,
    required String fileName,
  }) {
    return 'H$hostName\nP$username\nfdfA$jobNum$hostName\nN$fileName\n';
  }

  /// Generates PJL directives for hardware control
  static String generatePjlPrefix({
    bool isDuplex = true,
  }) {
    if (!isDuplex) return '';
    return '$pjlHeader'
        '@PJL SET DUPLEX=ON\r\n'
        '@PJL SET BINDING=LONGEDGE\r\n';
  }

  /// Wraps raw JPEG bytes in a basic PDF 1.4 container for printer compatibility
  static Uint8List wrapJpegInPdf(Uint8List jpegBytes) {
    int width = 595;
    int height = 842;

    if (jpegBytes.length > 4) {
      for (int i = 0; i < jpegBytes.length - 8; i++) {
        if (jpegBytes[i] == 0xFF && (jpegBytes[i + 1] == 0xC0 || jpegBytes[i + 1] == 0xC2)) {
          height = (jpegBytes[i + 5] << 8) + jpegBytes[i + 6];
          width = (jpegBytes[i + 7] << 8) + jpegBytes[i + 8];
          break;
        }
      }
    }

    final obj1 = utf8.encode('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
    final obj2 = utf8.encode('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');
    final obj3 = utf8.encode('3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /XObject << /Im1 5 0 R >> >> >>\nendobj\n');
    final obj4Stream = utf8.encode('q 595 0 0 842 0 0 cm /Im1 Do Q\n');
    final obj4 = utf8.encode('4 0 obj\n<< /Length ${obj4Stream.length} >>\nstream\n${utf8.decode(obj4Stream)}endstream\nendobj\n');

    final header = utf8.encode('%PDF-1.4\n');
    
    final obj5Header = utf8.encode(
      '5 0 obj\n<< /Type /XObject /Subtype /Image /Width $width /Height $height /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${jpegBytes.length} >>\nstream\n',
    );
    final obj5Footer = utf8.encode('\nendstream\nendobj\n');

    final offset1 = header.length;
    final offset2 = offset1 + obj1.length;
    final offset3 = offset2 + obj2.length;
    final offset4 = offset3 + obj3.length;
    final offset5 = offset4 + obj4.length;
    final startXref = offset5 + obj5Header.length + jpegBytes.length + obj5Footer.length;

    final xrefStr = 'xref\n0 6\n0000000000 65535 f \n'
        '${offset1.toString().padLeft(10, '0')} 00000 n \n'
        '${offset2.toString().padLeft(10, '0')} 00000 n \n'
        '${offset3.toString().padLeft(10, '0')} 00000 n \n'
        '${offset4.toString().padLeft(10, '0')} 00000 n \n'
        '${offset5.toString().padLeft(10, '0')} 00000 n \n'
        'trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$startXref\n%%EOF\n';

    final builder = BytesBuilder(copy: false)
      ..add(header)
      ..add(obj1)
      ..add(obj2)
      ..add(obj3)
      ..add(obj4)
      ..add(obj5Header)
      ..add(jpegBytes)
      ..add(obj5Footer)
      ..add(utf8.encode(xrefStr));

    return builder.takeBytes();
  }

  /// Creates a valid, minimal A4 PDF containing a single blank page.
  /// Useful for testing or as a filler page.
  static Uint8List createLocalBlankPdf() {
    const pdfString = '''%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources <<>> >>
endobj
4 0 obj
<< /Length 23 >>
stream
0 0 0 rg 590 835 1 1 re f
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000227 00000 n 
trailer
<< /Size 5 /Root 1 0 R >>
startxref
299
%%EOF
''';
    return Uint8List.fromList(utf8.encode(pdfString));
  }
}
