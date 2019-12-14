import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:http/http.dart';

import 'base_client.dart';
import 'sigv4.dart';

const _x_amz_date = 'x-amz-date';
const _x_amz_security_token = 'x-amz-security-token';
const _host = 'host';
const _authorization = 'Authorization';
const _default_content_type = 'application/json';
const _default_accept_type = 'application/json';

/// A client that stores secrets and configuration for AWS requests
/// signed with Signature Version 4. Required the following parameters:
/// - `keyId`: Your access key ID
/// - `accessKey`: Your secret access key
class Sigv4Client implements BaseSigv4Client {
  /// The region of the service(s) to be called.
  /// Defaults to `eu-west-1`
  String region;

  /// Your access key ID
  String keyId;

  /// Your secret access key
  String accessKey;

  /// An optional session token
  String sessionToken;

  /// The name of the service to be called.
  /// Defaults to `execute-api`
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
    this.serviceName = 'execute-api',
    this.region = 'eu-west-1',
    this.sessionToken,
    this.defaultContentType = _default_content_type,
    this.defaultAcceptType = _default_accept_type,
  })  : assert(keyId != null),
        assert(accessKey != null);

  /// Returns the path with encoded, canonical query parameters.
  /// This is __required__ by AWS.
  String canonicalUrl(String path, {Map<String, dynamic> query}) {
    return _generateUrl(path, query: query);
  }

  /// Generates SIGV4-signed headers.
  /// - `path`: The complete path of your request
  /// - `method`: The HTTP verb your request is using
  /// - `query`: Query parameters, if any. __required__ to be included if used
  /// - `headers`: Any additional headers. **DO NOT** add headers to your request after generating signed headers
  /// - `body`: The request body, if any
  Map<String, String> signedHeaders(
    String path, {
    String method = 'GET',
    Map<String, dynamic> query,
    Map<String, dynamic> headers,
    dynamic body,
    String dateTime,
  }) {
    /// Split the URI into segments
    final parsedUri = Uri.parse(path);

    /// The endpoint used
    final endpoint = '${parsedUri.scheme}://${parsedUri.host}';

    /// Format the `method` correctly
    method = method.toUpperCase();
    if (headers == null) {
      headers = {};
    }

    /// Set the `Content-Type header`
    if (headers['Content-Type'] == null) {
      headers['Content-Type'] = this.defaultContentType;
    }

    /// Set the `Accept` header
    if (headers['Accept'] == null) {
      headers['Accept'] = this.defaultAcceptType;
    }

    /// Set the `body`, if any
    if (body == null || method == 'GET') {
      body = '';
    } else {
      body = json.encode(body);
    }
    if (body == '') {
      headers.remove('Content-Type');
    }

    /// Sets or generate the `dateTime` parameter needed for the signature
    if (dateTime == null) {
      dateTime = Sigv4.generateDatetime();
    }
    headers[_x_amz_date] = dateTime;

    /// Sets the `host` header
    final endpointUri = Uri.parse(endpoint);
    headers[_host] = endpointUri.host;

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
    if (this.sessionToken != null) {
      headers[_x_amz_security_token] = this.sessionToken;
    }
    headers.remove(_host);

    return headers.cast<String, String>();
  }

  /// A wrapper that generates both the canonical path and
  /// signed headers and returns a [Request] object from [package:http](https://pub.dev/packages/http)
  Request request(
    String path, {
    String method = 'GET',
    Map<String, dynamic> query,
    Map<String, dynamic> headers,
    dynamic body,
    String dateTime,
  }) {
    /// Convert the path to a canonical path
    path = canonicalUrl(path, query: query);
    var request = Request(method, Uri.parse(path));
    var signed = Map<String, String>();

    signedHeaders(
      path,
      method: method,
      query: query,
      headers: headers,
      body: body,
      dateTime: dateTime,
    ).forEach((k, v) => signed.addAll({k: v}));

    /// Add the signed headers to the request
    request.headers.addAll(signed);

    /// Add the body to the request
    if (body != null) {
      request.body = jsonEncode(body);
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
    dynamic body,
    String dateTime,
  }) {
    final canonicalRequest = Sigv4.buildCanonicalRequest(method, path, query, headers, body);
    final hashedCanonicalRequest = Sigv4.hashCanonicalRequest(canonicalRequest);
    final credentialScope = Sigv4.buildCredentialScope(dateTime, this.region, this.serviceName);
    final stringToSign = Sigv4.buildStringToSign(dateTime, credentialScope, hashedCanonicalRequest);
    final signingKey =
        Sigv4.calculateSigningKey(this.accessKey, dateTime, this.region, this.serviceName);
    final signature = Sigv4.calculateSignature(signingKey, stringToSign);
    return Sigv4.buildAuthorizationHeader(this.keyId, credentialScope, headers, signature);
  }
}
