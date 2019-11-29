import 'package:http/http.dart';
import 'package:sigv4/src/client.dart';

void main() {
  final client = Sigv4Client(
    accessKey: 'your_access_key',
    secretKey: 'your_secret_key',
  );

  // Create the request
  final request = client.request('https://service.aws.com/endpoint');

  // GET request
  get(request.url, headers: request.headers);

  // A larger request
  final largeRequest = client.request(
    'https://service.aws.com/endpoint',
    method: 'POST',
    queryParameters: {'key': 'value'},
    headers: {'header': 'value'},
    body: {'content': 'some-content'},
  );

  // POST request
  post(largeRequest.url, headers: largeRequest.headers, body: largeRequest.body);

  final path = 'https://service.aws.com/endpoint';
  final queryParameters = {'key': 'value'};

  final url = client.canonicalUrl(path, queryParameters: queryParameters);
  final headers = client.signedHeaders(
    path,
    queryParameters: queryParameters,
  );

  // GET request
  get(url, headers: headers);
}
