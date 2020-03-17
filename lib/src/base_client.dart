import 'package:http/http.dart';

abstract class BaseSigv4Client {
  Request request(
    String path, {
    String method,
    Map<String, dynamic> query,
    Map<String, dynamic> headers,
    String body,
    String dateTime,
  });

  Map<String, dynamic> signedHeaders(
    String path, {
    String method,
    Map<String, dynamic> query,
    Map<String, dynamic> headers,
    String body,
    String dateTime,
  });

  String canonicalUrl(String path, {Map<String, dynamic> query});
}
