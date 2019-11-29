# Changelog

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
