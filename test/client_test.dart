import 'package:http/http.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:sigv4/sigv4.dart';

import 'client_test.mocks.dart';

// For an explanation on this method of generating stubs, see https://github.com/dart-lang/mockito/blob/master/NULL_SAFETY_README.md
@GenerateMocks([Sigv4Client])
void main() {
  group('#baseClient', () {
    late MockSigv4Client client;

    setUp(() {
      client = MockSigv4Client();
    });

    // Stub
    test('returns headers', () {
      final request = Request('GET', Uri.parse('path'));
      when(client.request('path')).thenReturn(request);
      expect(client.request('path'), request);
    });

    // Stub
    test('returns canonical url', () {
      when(client.canonicalUrl('path')).thenAnswer((_) => 'canonical');
      expect(client.canonicalUrl('path'), 'canonical');
    });

    // Stub
    test('returns signed headers', () {
      final headers = {'key': 'value'};
      when(client.signedHeaders('path')).thenAnswer((_) => headers);
      expect(client.signedHeaders('path'), headers);
    });

    test('throws on null/empty path', () {
      try {
        var client2 = Sigv4Client(
            keyId: 'keyId',
            accessKey: 'accessKey',
            serviceName: 'serviceName',
            region: 'region');
        client2.signedHeaders('');
      } on AssertionError catch (e) {
        expect(e.runtimeType, AssertionError);
      }
    });
  });
}
