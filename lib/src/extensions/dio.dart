import 'package:dio/dio.dart';
import 'package:sigv4/sigv4.dart';

extension DioExtension on RequestOptions {
  RequestOptions sign(Sigv4Client client) {
    final signed = client.signedHeaders(
      '${this.baseUrl}${this.path}',
      method: this.method,
      query: this.queryParameters,
      headers: this.headers,
      body: this.data,
    );

    this.headers.addAll(signed);
    return this;
  }
}
