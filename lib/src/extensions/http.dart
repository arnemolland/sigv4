import 'package:http/http.dart';
import 'package:sigv4/sigv4.dart';

extension HttpExtension on Request {
  Request sign(Sigv4Client client) {
    final signed = client.signedHeaders(
      url.path,
      method: method,
      query: url.queryParameters,
      headers: headers,
      body: body,
    );

    headers.addAll(signed);
    return this;
  }
}
