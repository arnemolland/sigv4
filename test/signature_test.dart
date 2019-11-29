import 'package:sigv4/sigv4.dart';
import 'package:test/test.dart';

void main() {
  group('#signatures', () {
    Map<String, dynamic> queryParameters;
    Map<String, dynamic> headers;

    setUp(() {
      queryParameters = {'key': 'value', 'number': 123};
      headers = {'x-auth': 'some_token', 'version': 1008};
    });
    test('builds canonical query parameters', () {
      expect(Sigv4.buildCanonicalQueryString(queryParameters), 'key=value&number=123');
    });

    test('signs headers', () {
      expect(Sigv4.buildCanonicalSignedHeaders(headers), 'version;x-auth');
    });

    test('builds canonical headers', () {
      expect(Sigv4.buildCanonicalHeaders(headers), 'version:1008\nx-auth:some_token\n');
    });

    test('build canonical uri', () {
      expect(
        Sigv4.buildCanonicalUri('http://x.com/[] '),
        'http://x.com/%5B%5D%20',
      );
    });
  });
}
