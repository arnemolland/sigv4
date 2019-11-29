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

    test('builds canonical uri', () {
      expect(
        Sigv4.buildCanonicalUri('http://x.com/[] '),
        'http://x.com/%5B%5D%20',
      );
    });

    test('builds credential scope', () {
      expect(
        Sigv4.buildCredentialScope(Sigv4.generateDatetime(), 'eu-west-1', 'api-service'),
        '${Sigv4.generateDatetime().substring(0, 8)}/eu-west-1/api-service/aws4_request',
      );
    });

    test('generates authorization headers', () {
      final method = 'POST';
      final path = 'path';
      final queryParams = {'key': 'value'};
      final headers = {'header': 'value'};
      final dateTime = DateTime(1998)
          .toUtc()
          .toString()
          .replaceAll(RegExp(r'\.\d*Z$'), 'Z')
          .replaceAll(RegExp(r'[:-]|\.\d{3}'), '')
          .split(' ')
          .join('T');

      final region = 'eu-west-1';
      final accessKey = 'accessKey';
      final secretKey = 'secretKey';
      final body = {'content': 'some_content'};
      final serviceName = 'api-service';

      final expected =
          'AWS4-HMAC-SHA256 Credential=accessKey/19971231/eu-west-1/api-service/aws4_request, SignedHeaders=header, Signature=d1fa7e984a159b4a0c22e2ac995397bc6066b8430b9ed07f4a43461d36f29894';

      final canonicalRequest =
          Sigv4.buildCanonicalRequest(method, path, queryParams, headers, body.toString());
      final hashedCanonicalRequest = Sigv4.hashCanonicalRequest(canonicalRequest);
      final credentialScope = Sigv4.buildCredentialScope(dateTime, region, serviceName);
      final stringToSign =
          Sigv4.buildStringToSign(dateTime, credentialScope, hashedCanonicalRequest);
      final signingKey = Sigv4.calculateSigningKey(secretKey, dateTime, region, serviceName);
      final signature = Sigv4.calculateSignature(signingKey, stringToSign);
      final result = Sigv4.buildAuthorizationHeader(accessKey, credentialScope, headers, signature);

      expect(
        result,
        expected,
      );
    });
  });
}
