import 'package:chopper/chopper.dart';
import 'package:sigv4/sigv4.dart';

extension ChopperExtension on Request {
  Request sign(Sigv4Client client) {
    final signed = client.signedHeaders(
      url,
      method: method,
      query: parameters,
      headers: headers,
      body: this.body,
    );
    headers.addAll(signed);
    return this;
  }
}
