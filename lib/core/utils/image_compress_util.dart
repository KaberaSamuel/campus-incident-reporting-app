import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<Uint8List?> compressImageBytes(Uint8List input) {
  return FlutterImageCompress.compressWithList(
    input,
    minWidth: 1280,
    minHeight: 1280,
    quality: 75,
    format: CompressFormat.jpeg,
  );
}
