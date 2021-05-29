import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart';
import 'package:sigv4/sigv4.dart';

/// This sample contains several placeholders for otherwise secret keys
/// and values, and will not run before you provide valid values and
/// a valid endpoint.
void main() {
  final client = Sigv4Client(
    keyId: 'your_access_key_id',
    accessKey: 'your_access_key',
    region: 'eu-north-1',
    serviceName: 'execute-api',
  );

  // Some fictive endpoint
  final path = 'https://service.aws.com/endpoint/replace-this-placeholder';

  // Create the request
  var request = client.request(path);

  // GET request
  get(request.url, headers: request.headers);

  // A larger request
  final largeRequest = client.request(
    path,
    method: 'POST',
    query: {'key': 'value'},
    headers: {'header': 'value'},
    body: json.encode({'content': 'some-content'}),
  );

  // POST request
  post(
    largeRequest.url,
    headers: largeRequest.headers,
    body: largeRequest.body,
  );

  final query = {'key': 'value'};

  final url = Uri.parse(client.canonicalUrl(path, query: query));
  final headers = client.signedHeaders(
    path,
    query: query,
  );

  // GET request
  get(url, headers: headers);

  // Extensions on `http` Request objects
  Request('GET', Uri.parse(path)).sign(client);

  // Extensions on `dio` RequestOptions objects
  RequestOptions(method: 'GET', path: path).sign(client);
}
