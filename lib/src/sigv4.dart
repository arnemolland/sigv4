import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

const _aws_sha_256 = 'AWS4-HMAC-SHA256';
const _aws4_request = 'aws4_request';
const _aws4 = 'AWS4';

class Sigv4 {
  /// Generates a date string compliant with the `AWS Signature V4` standard
  static String generateDatetime() {
    return DateTime.now()
        .toUtc()
        .toString()
        .replaceAll(RegExp(r'\.\d*Z$'), 'Z')
        .replaceAll(RegExp(r'[:-]|\.\d{3}'), '')
        .split(' ')
        .join('T');
  }

  /// Creates a SHA256 hash from the given `value` byte array
  static List<int> hash(List<int> value) {
    return sha256.convert(value).bytes;
  }

  /// Encodes the given `value` byte array with the Hex Codec
  static String hexEncode(List<int> value) {
    return hex.encode(value);
  }

  /// Signs the given `message` with the given `key` using [HMAC]
  static List<int> sign(List<int> key, String message) {
    Hmac hmac = Hmac(sha256, key);
    Digest dig = hmac.convert(utf8.encode(message));
    return dig.bytes;
  }

  /// Hex-encodes a SHA256 hash of the given canonical request string, `request`
  static String hashCanonicalRequest(String request) {
    return hexEncode(hash(utf8.encode(request)));
  }

  /// Encodes the given string to a canonical URI
  static String buildCanonicalUri(String uri) {
    return Uri.encodeFull(uri);
  }

  /// Builds a canonical query string from the given `query` parameters
  static String buildCanonicalQueryString(Map<String, dynamic> query) {
    if (query == null) {
      return '';
    }

    final List<String> sortedQuery = [];
    query.forEach((key, value) {
      sortedQuery.add(key.toString());
    });
    sortedQuery.sort();

    final List<String> canonicalQueryStrings = [];
    sortedQuery.forEach((key) {
      canonicalQueryStrings
          .add('$key=${Uri.encodeComponent(query[key].toString())}');
    });

    return canonicalQueryStrings.join('&');
  }

  /// Builds a canonical header string from the given `headers`
  static String buildCanonicalHeaders(Map<String, dynamic> headers) {
    final List<String> sortedKeys = [];
    headers.forEach((property, _) {
      sortedKeys.add(property);
    });

    var canonicalHeaders = '';
    sortedKeys.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    sortedKeys.forEach((property) {
      canonicalHeaders +=
          '${property.toLowerCase()}:${headers[property].toString()}\n';
    });

    return canonicalHeaders;
  }

  /// Builds a signed canonical header string from the given `headers`
  static String buildCanonicalSignedHeaders(Map<String, dynamic> headers) {
    final List<String> sortedKeys = [];
    headers.forEach((property, _) {
      sortedKeys.add(property.toLowerCase());
    });
    sortedKeys.sort();

    return sortedKeys.join(';');
  }

  /// Builds the complete canonical string to sign
  static String buildStringToSign(
      String datetime, String credentialScope, String hashedCanonicalRequest) {
    return '$_aws_sha_256\n$datetime\n$credentialScope\n$hashedCanonicalRequest';
  }

  /// Builds the required credential scope
  static String buildCredentialScope(
      String datetime, String region, String service) {
    return '${datetime.substring(0, 8)}/$region/$service/$_aws4_request';
  }

  /// Builds a canonical string containing a complete request
  static String buildCanonicalRequest(
    String method,
    String path,
    Map<String, dynamic> query,
    Map<String, dynamic> headers,
    String payload,
  ) {
    List<String> canonicalRequest = [
      method,
      buildCanonicalUri(path),
      buildCanonicalQueryString(query),
      buildCanonicalHeaders(headers),
      buildCanonicalSignedHeaders(headers),
      hexEncode(hash(utf8.encode(payload))),
    ];
    return canonicalRequest.join('\n');
  }

  /// Builds the `Authorization` headers
  static String buildAuthorizationHeader(String accessKey,
      String credentialScope, Map<String, dynamic> headers, String signature) {
    return _aws_sha_256 +
        ' Credential=' +
        accessKey +
        '/' +
        credentialScope +
        ', SignedHeaders=' +
        buildCanonicalSignedHeaders(headers) +
        ', Signature=' +
        signature;
  }

  /// Builds the key to use for signing
  static List<int> calculateSigningKey(
      String secretKey, String datetime, String region, String service) {
    return sign(
        sign(
            sign(
                sign(utf8.encode('$_aws4$secretKey'), datetime.substring(0, 8)),
                region),
            service),
        _aws4_request);
  }

  /// Builds a Hex-encoded signature with the given `signingKey`and `stringToSign`
  static String calculateSignature(List<int> signingKey, String stringToSign) {
    return hexEncode(sign(signingKey, stringToSign));
  }
}
