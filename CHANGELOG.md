# Changelog

## 4.1.0

- Remove content-length from request-to-sign. This may have unintended side-effects for some AWS APIs, which is why the minor version is bumped.
- Bump dependencies

## 4.0.0

- Fixed invalid tyes in signed headers

### **BREAKING CHANGES:**

- `body` is now a `String` value for both `request()` and `signedHeaders()` in `Sigv4Client`

## 3.1.2

- Fixed incorrect string for non-payload S3 requests ([@jfrsbg](https://github.com/jfrsbg))

## 3.1.1

- Added `signPayload` and `encoding` parameters to support S3 signed payloads

## 3.1.0

- `service` and `region` parameters are now required

## 3.0.0+1

- External image reference in readme

## 3.0.0

- Added/clarified documentation
- Added extensions for `http`, `dio` and `chopper`

### **BREAKING CHANGES**

Renamed some parameters to be more consistent with AWS's documentation

- `accessKey` => `keyId`
- `secretKey` => `accessKey`

## 2.1.0+2

- Removed too complex signature text (dependent on current datetime)

## 2.1.0+1

- Formatting

## 2.1.0

- Fixed request headers type mismatch
- Added tests

## 2.0.1

- Fixed non-string query parameter type errors
- Tweaked readme

## 2.0.0

### **BREAKING CHANGES:**

- Removed Sigv4Request, only Sigv4Client is needed
- Exposed methods for building headers and canonical path independently
- Exposed a wrapper method that returns a `http` Request object

- Added documentation and README

## 1.0.0

- Initial version
