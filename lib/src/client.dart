import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:http/http.dart';

import 'base_client.dart';
import 'sigv4.dart';

const _x_amz_date = 'x-amz-date';
const _x_amz_security_token = 'x-amz-security-token';
const _x_amz_content_sha256 = 'x-amz-content-sha256';
const _host = 'Host';
const _authorization = 'Authorization';
const _default_content_type = 'application/json';
const _default_accept_type = 'application/json';
const _unsigned_payload = 'UNSIGNED-PAYLOAD';
const _chunked_payload = 'STREAMING-AWS4-HMAC-SHA256-PAYLOAD';

/// A client that stores secrets and configuration for AWS requests
/// signed with Signature Version 4. Required the following parameters:
/// - `keyId`: Your access key ID
/// - `accessKey`: Your secret access key
class Sigv4Client implements BaseSigv4Client {
  /// The region of the service(s) to be called.
  String region;

  /// Your access key ID
  String keyId;

  /// Your secret access key
  String accessKey;

  /// An optional session token
  String sessionToken;

  /// The name of the service to be called.
  /// E.g. `s3`, `execute-api` etc.
  String serviceName;

  /// The default `Content-Type` header value.
  /// Defaults to `application/json`
  String defaultContentType;

  /// The deafult `Accept` header value.
  /// Defaults to `application/json`
  String defaultAcceptType;

  Sigv4Client({
    @required this.keyId,
    @required this.accessKey,
    @required this.serviceName,
    @required this.region,
    this.sessionToken,
    this.defaultContentType = _default_content_type,
    this.defaultAcceptType = _default_accept_type,
  })  : assert(keyId != null),
        assert(accessKey != null);

  /// Returns the path with encoded, canonical query parameters.
  /// This is __required__ by AWS.
  @override
  String canonicalUrl(String path, {Map<String, dynamic> query}) {
    return _generateUrl(path, query: query);
  }

  /// Generates SIGV4-signed headers.
  /// - `path`: The complete path of your request
  /// - `method`: The HTTP verb your request is using
  /// - `query`: Query parameters, if any. __required__ to be included if used
  /// - `headers`: Any additional headers. **DO NOT** add headers to your request after generating signed headers
  /// - `body`: An *encodable* object
  /// - `dateTime`: An AWS-compatible time string. You'll probably want to leave it blank.
  /// - `encoding`: The payload encoding. if any
  /// - `signPayload`: If the optional payload should be signed or unsigned
  @override
  Map<String, String> signedHeaders(
    String path, {
    String method = 'GET',
    Map<String, dynamic> query,
    Map<String, dynamic> headers,
    String body,
    String dateTime,
    String encoding,
    bool signPayload = true,
    bool chunked = false,
  }) {
    /// Split the URI into segments
    final parsedUri = Uri.parse(path);

    /// The endpoint used
    final baseUrl = '${parsedUri.scheme}://${parsedUri.host}';

    path = parsedUri.path;

    /// Format the `method` correctly
    method = method.toUpperCase();
    headers ??= {};

    if (encoding != null) {
      headers['Content-Encoding'] = encoding;
    }

    /// Set the `Content-Type header`
    if (headers['Content-Type'] == null) {
      headers['Content-Type'] = defaultContentType;
    }

    /// Set the `Accept` header
    if (headers['Accept'] == null) {
      headers['Accept'] = defaultAcceptType;
    }

    /// Set the `body`, if any
    if (body == null || method == 'GET') {
      body = '';
    } else {
      headers['Content-Length'] = utf8.encode(body).length.toString();
    }

    headers[_x_amz_content_sha256] =
        signPayload ? Sigv4.hashPayload(body) : _unsigned_payload;

    if (body == '') {
      headers.remove('Content-Type');
    }

    if (chunked) {
      headers['Content-Encoding'] = 'aws-chunked';
    }

    /// Sets or generate the `dateTime` parameter needed for the signature
    dateTime ??= Sigv4.generateDatetime();
    headers[_x_amz_date] = dateTime;

    /// Sets the `host` header
    final baseUri = Uri.parse(baseUrl);
    headers[_host] = baseUri.host;

    if (headers.containsKey('Transfer-Encoding') &&
        headers['Transfer-Encoding'] != 'identity') {
      //headers.remove('Content-Length');
    }

    if (headers.containsKey('Content-Encoding') &&
        headers['Content-Encoding'] == 'aws-chunked') {
      headers[_x_amz_content_sha256] = _chunked_payload;
    }

    /// Generates the `Authorization` headers
    headers[_authorization] = _generateAuthorization(
      method: method,
      path: path,
      query: query,
      headers: headers,
      body: body,
      dateTime: dateTime,
    );

    /// Adds the `x-amz-security-token` header if a session token is present
    if (sessionToken != null) {
      headers[_x_amz_security_token] = sessionToken;
    }
    headers.remove(_host);

    // Return only string values
    return headers.cast<String, String>();
  }

  /// A wrapper that generates both the canonical path and
  /// signed headers and returns a [Request] object from [package:http](https://pub.dev/packages/http)
  /// - `path`: The complete path of your request
  /// - `method`: The HTTP verb your request is using
  /// - `query`: Query parameters, if any. __required__ to be included if used
  /// - `headers`: Any additional headers. **DO NOT** add headers to your request after generating signed headers
  /// - `body`: An *encodable* object
  /// - `dateTime`: An AWS-compatible time string. You'll probably want to leave it blank.
  /// - `encoding`: The payload encoding. if any
  /// - `signPayload`: If the optional payload should be signed or unsigned
  @override
  Request request(
    String path, {
    String method = 'GET',
    Map<String, dynamic> query,
    Map<String, dynamic> headers,
    String body,
    String dateTime,
    String encoding,
    bool signPayload = true,
  }) {
    /// Converts the path to a canonical path
    path = canonicalUrl(path, query: query);
    var request = Request(method, Uri.parse(path));

    final signed = signedHeaders(
      path,
      method: method,
      query: query,
      headers: headers,
      body: body,
      dateTime: dateTime,
      signPayload: signPayload,
      encoding: encoding,
    );

    /// Adds the signed headers to the request
    request.headers.addAll(signed);

    /// Adds the body to the request
    if (body != null) {
      request.body = body;
    }

    return request;
  }

  String _generateUrl(String path, {Map<String, dynamic> query}) {
    var url = '$path';
    if (query != null) {
      final queryString = Sigv4.buildCanonicalQueryString(query);
      if (queryString != '') {
        url += '?$queryString';
      }
    }
    return url;
  }

  String _generateAuthorization({
    String method,
    String path,
    Map<String, dynamic> query,
    Map<String, dynamic> headers,
    String body,
    String dateTime,
  }) {
    final canonicalRequest =
        Sigv4.buildCanonicalRequest(method, path, query, headers, body);
    final hashedCanonicalRequest = Sigv4.hashPayload(canonicalRequest);
    final credentialScope =
        Sigv4.buildCredentialScope(dateTime, region, serviceName);
    final stringToSign = Sigv4.buildStringToSign(
        dateTime, credentialScope, hashedCanonicalRequest);
    final signingKey =
        Sigv4.calculateSigningKey(accessKey, dateTime, region, serviceName);
    final signature = Sigv4.calculateSignature(signingKey, stringToSign);
    return Sigv4.buildAuthorizationHeader(
        keyId, credentialScope, headers, signature);
  }
}
