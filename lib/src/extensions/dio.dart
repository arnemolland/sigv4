import 'package:dio/dio.dart';
import 'package:sigv4/sigv4.dart';

extension DioExtension on RequestOptions {
  RequestOptions sign(Sigv4Client client) {
    final signed = client.signedHeaders(
      '$baseUrl$path',
      method: method,
      query: queryParameters,
      headers: headers,
      body: data,
    );

    headers.addAll(signed);
    return this;
  }
}
