import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:intl/intl.dart';
import 'dart:convert' show utf8;
import 'package:convert/convert.dart' show hex;

class Sigv4 {
  final String access_key;
  final String secret_key;

  Sigv4({this.access_key, this.secret_key});

  /// Signs the provided [key] and [message] with hmac(sha256) and returns the digest
  Digest sign(key, message) {
    var keyBytes = utf8.encode(key);
    var messageBytes = utf8.encode(message);
    var hmacSha256 = Hmac(sha256, keyBytes);
    var digest = hmacSha256.convert(messageBytes);
    return digest;
  }

  /// Generates the signature key from [key], [dateStamp], [regionName] and [serviceName] params,
  ///  and returns the digets.
  Digest getSignatureKey(key, dateStamp, regionName, serviceName) {
    var kDate = sign(utf8.encode('AWS4$key'), dateStamp);
    var kRegion = sign(kDate, regionName);
    var kService = sign(kRegion, serviceName);
    var kSigning = sign(kService, 'aws4_request');
    return kSigning;
  }

  Map<String, String> getHeaders(
      {@required String method,
      @required String service,
      @required String host,
      @required String region,
      @required String endpoint,
      @required String request_parameters,
      String canonical_uri = '/'}) {
    var t = DateTime.now();
    var formatter = DateFormat.yMd();
    var amzdate = t.toUtc().toIso8601String();
    var datestamp = formatter.format(t);

    /// Create the canonical query string. In a [GET] request,
    /// request parameters are in the query string. Query string values
    /// must be URL-encoded (space=%20). The parameters must be sorted
    /// by name.
    var canonical_querystring = request_parameters;

    /// Create the canonical headers and signed headers. Header names
    /// must be trimmed and lowecase, and sorted in code point order from
    /// low to high. [signed_headers] is the list of headers that are
    /// being included as part of the signing process. For requests that
    /// use query strings, only 'host' is included in the signed headers.
    var canonical_headers = 'host:$host\nx-amz-date:$amzdate\n';
    var signed_headers = 'host;x-amz-date';
    var payload_hash = hex.encode(sha256.convert(utf8.encode('')).bytes);

    var canonical_request =
        '$method\n$canonical_uri\n$canonical_querystring\n$canonical_headers\n$signed_headers\n$payload_hash';

    /// Match the algorithm to the hashin algorithm used, either [SHA-1] or [SHA-256]
    /// as used here.
    var algorithm = 'AWS-HMAC-SHA256';
    var credential_scope = '$datestamp/$region/$service/aws4_request';

    var string_to_sign =
        '$algorithm\n$amzdate\n$credential_scope\n${hex.encode(sha256.convert(utf8.encode(canonical_request)).bytes)}';

    /// Create the signing key using the function [getSignatureKey()].
    var signing_key = getSignatureKey(secret_key, datestamp, region, service);
    var hmacSha56 = Hmac(sha256, signing_key.bytes);

    /// Sign [string_to_sign] using the signing key
    var signature =
        hex.encode(hmacSha56.convert(utf8.encode(string_to_sign)).bytes);

    /// Add signing information to the request. Create authorization
    /// header and add to request headers
    var auth_header =
        '$algorithm Credential=$access_key/$credential_scope, SignedHeaders=$signed_headers, Signature=$signature';
    var headers = {'x-amz-date': amzdate, 'Authorization': auth_header};

    return headers;
  }
}
