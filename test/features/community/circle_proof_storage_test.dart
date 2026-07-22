import 'package:flutter_test/flutter_test.dart';

import 'package:sidepal/features/community/data/circle_proof_storage.dart';

void main() {
  group('imageExtensionFromPath', () {
    test('uses mime type when path has no extension', () {
      expect(
        imageExtensionFromPath('/tmp/image_picker_123', mimeType: 'image/png'),
        'png',
      );
    });

    test('parses path extension', () {
      expect(imageExtensionFromPath('/photos/proof.JPEG'), 'jpg');
    });

    test('defaults to jpg', () {
      expect(imageExtensionFromPath('/tmp/noext'), 'jpg');
    });
  });

  group('contentTypeForImageExtension', () {
    test('maps common types', () {
      expect(contentTypeForImageExtension('png'), 'image/png');
      expect(contentTypeForImageExtension('jpg'), 'image/jpeg');
    });
  });
}
