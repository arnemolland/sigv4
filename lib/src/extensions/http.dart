import 'package:http/http.dart';
import 'package:sigv4/sigv4.dart';

extension HttpExtension on Request {
  Request sign(Sigv4Client client) {
    final signed = client.signedHeaders(
      this.url.path,
      method: this.method,
      query: this.url.queryParameters,
      headers: this.headers,
      body: this.body,
    );

    this.headers.addAll(signed);
    return this;
  }
}
