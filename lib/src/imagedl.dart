import 'dart:typed_data';

import 'package:http/http.dart' as http;

class Image {
  final String mimetype;
  final Uint8List binary;
  Image(this.mimetype, this.binary);
  
  @override
  String toString() {
    return "<$mimetype>";
  }
}

Future<Image> downloadImage(String url) async {
  var response = await http.get(Uri.parse(url));
  var type = response.headers["content-type"] ??
      response.headers["Content-Type"] ??
      "";
  return Image(type, response.bodyBytes);
}