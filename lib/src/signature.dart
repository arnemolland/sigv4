import 'package:crypto/crypto.dart';
import 'dart:convert' show utf8;

class Sigv4 {

  /// Signs the provided [key] and [message] with 
  static Digest sign(key, message) {
    var keyBytes = utf8.encode(key);
    var messageBytes = utf8.encode(message);
    var hmacSha256 = Hmac(sha256, keyBytes);
    var digest = hmacSha256.convert(messageBytes);
    return digest;
  }

  static Digest getSignatureKey(key, dateStamp, regionName, serviceName) {
    var kDate = sign(utf8.encode('AWS4$key'), dateStamp);
    var kRegion = sign(kDate, regionName);
    var kService = sign(kRegion, serviceName);
    var kSigning = sign(kService, 'aws4_request');
    return kSigning;
  }
}