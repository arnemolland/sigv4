import 'package:chopper/chopper.dart';
import 'package:sigv4/sigv4.dart';

extension ChopperExtension on Request {
  Request sign(Sigv4Client client) {
    final signed = client.signedHeaders(
      this.url,
      method: this.method,
      query: this.parameters,
      headers: this.headers,
      body: this.body,
    );
    this.headers.addAll(signed);
    return this;
  }
}
