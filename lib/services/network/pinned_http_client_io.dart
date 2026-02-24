import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// PEM-encoded TLS certificate chain for api.unsplash.com.
//
// Include every certificate from the leaf cert up to (and including) the root CA,
// concatenated in order. Keep the previous cert alongside the new one during the
// rotation window so existing installs don't break mid-cycle.
//
// To regenerate (run once per cert rotation, typically every 1–2 years):
//
//   openssl s_client -connect api.unsplash.com:443 -showcerts \
//     < /dev/null 2>/dev/null \
//     | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ { print }' \
//     > unsplash_chain.pem
//
// Paste the content of unsplash_chain.pem into the string below.
// Certificate chain last fetched: 2026-02-24. Rotate when the leaf cert expires (2027-01-13).
const _kUnsplashCertPem = '''
-----BEGIN CERTIFICATE-----
MIIGZjCCBU6gAwIBAgIQARkfUg7BiQWRf4Nrpou5kzANBgkqhkiG9w0BAQsFADBY
MQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEuMCwGA1UE
AxMlR2xvYmFsU2lnbiBBdGxhcyBSMyBEViBUTFMgQ0EgMjAyNSBRNDAeFw0yNTEy
MTIwMjAwMzFaFw0yNzAxMTMwMjAwMzBaMBkxFzAVBgNVBAMMDioudW5zcGxhc2gu
Y29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApp2roPfwyroytW7+
5kyiP+NgobuP8+//5HgcJXD+hyUa6xxyaiZHv4PEfkYnglUdyRvbTfrA6H1QAi1G
aX8aKzOEXY/Enj3I8ycsDL/oxD4y5vROO0DPdIfKPkKEp/8oHwDTBgAJFhsKtGGp
XdI0FXt67WL9r1FyPs/UhXQQrhew24rGRD0yDXyKSmuWa+ARCQzG6LE6lVdRmfb0
VA+nT75lWi9GANSJoLCAkatVRr85vf+TdunMrsfc7BoMhxU7hDEiuk2ZJGxGT/xo
LOQ8vbqYvYJ37WGq6Dy+M+AZRLOXWgTAWH7Uw3Ny4ZCHRxUZJ0RyyKugpqnAhas6
EW9VGQIDAQABo4IDaTCCA2UwGQYDVR0RBBIwEIIOKi51bnNwbGFzaC5jb20wDgYD
VR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNV
HQ4EFgQUnzHO6cleu/LdWu0Oqo/fJRqWRlUwVwYDVR0gBFAwTjAIBgZngQwBAgEw
QgYKKwYBBAGgMgoBAzA0MDIGCCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxz
aWduLmNvbS9yZXBvc2l0b3J5LzAMBgNVHRMBAf8EAjAAMIGeBggrBgEFBQcBAQSB
kTCBjjBABggrBgEFBQcwAYY0aHR0cDovL29jc3AuZ2xvYmFsc2lnbi5jb20vY2Ev
Z3NhdGxhc3IzZHZ0bHNjYTIwMjVxNDBKBggrBgEFBQcwAoY+aHR0cDovL3NlY3Vy
ZS5nbG9iYWxzaWduLmNvbS9jYWNlcnQvZ3NhdGxhc3IzZHZ0bHNjYTIwMjVxNC5j
cnQwHwYDVR0jBBgwFoAUsEOeMHD23v1UHhI6HeD3Ycv7IMcwSAYDVR0fBEEwPzA9
oDugOYY3aHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9jYS9nc2F0bGFzcjNkdnRs
c2NhMjAyNXE0LmNybDCCAYUGCisGAQQB1nkCBAIEggF1BIIBcQFvAHUATGPcmOWc
HauI9h6KPd6uj6tEozd7X5uUw/uhnPzBviYAAAGbEEnWZAAABAMARjBEAiAGFCjj
sRzPDeoqx2OBKGoX6GbiSh13Ebl5KG5G+wzDZAIgNg2HKEBq1be4Uks4lSqnSQ+4
vngMp+z2JpkapROx/AcAdgAcn2gs6frwRWlQ+BuWiofd2zIQ2EzmyLLjglJKxM9Z
nwAAAZsQSdboAAAEAwBHMEUCIQDBXiV6aAvHf+JCSdpakU14Qi/o7oztbLyUkdJ0
olRD+AIgAnMNdPAMohhvgsV5Y/UaqRipYDQXFuhkf8Pt530iJIQAfgCOykcLrN5q
86IGsKR6hLdG/h/Gv5U+JeabTuQCSPPG6AAAAZsQSdqKAAgAAAUAAHCQDgQDAEcw
RQIgEdT53s1mJ3bcmeG6sm2dXRDfi2voGaPacUalWiqBS5wCIQChccUtITxk3hJo
VjKplI0L9qBUyaWA955YJ6pDMeroDzANBgkqhkiG9w0BAQsFAAOCAQEAPx56Y6vA
GzPBRLTOAHxmHLJFozU/uAKY0Cgy4y5IxM61YV0Pi+ZvVkQlpDJ4Ep/v7d3t4Blf
NkGz10H3Lc8wmNmikJFSd6VyTXldNAKn505hsjpSi9wvI0N6cgDY0jNzhlsV97xz
C9VCM/QsZg0Kiwx6xxuQgku9wLm1g3/7Q/vSYkK7hF2+CFBeQHh+HzzDZHCKbsZF
Y9fga7pOCDkJwpBQIYl7ZJyrD4p0W/S49bNnApS7+BXXIiUdBcvb9C3RskiZaZA6
rO23yrQWq6y6Vkots87cW0x80OtwR8DNNv07j+3MKy4bad9HZyLqQd5HAd41J54i
yK3bzVvUfVFGXg==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIEkDCCA3igAwIBAgIRAIPahqsOMbGdjwOl7dW9vWYwDQYJKoZIhvcNAQELBQAw
TDEgMB4GA1UECxMXR2xvYmFsU2lnbiBSb290IENBIC0gUjMxEzARBgNVBAoTCkds
b2JhbFNpZ24xEzARBgNVBAMTCkdsb2JhbFNpZ24wHhcNMjUwNzE2MDMwNjM1WhcN
MjcwNzE2MDAwMDAwWjBYMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2ln
biBudi1zYTEuMCwGA1UEAxMlR2xvYmFsU2lnbiBBdGxhcyBSMyBEViBUTFMgQ0Eg
MjAyNSBRNDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMxqPHokJx19
u/UzIIDj3xVbvZUVaaYagOIlNGQ9bI6v6ftebJuQmHEIhz0p2gqxVfWSjRsJ3AJR
xZc/3Ay08xjL0fYTFWdiF86X6yXwmkpv3MkhhqfQKrbWfv+2Tf6Hf9lrtR6//Cuj
OBNvRe/qcryl/HfN+u+n+YGTkT397id+feK5qQg5YoJbkBnjeKHt2HOxtJYxfggT
YSE/zS0CKzfEL0ttYO0cBRycopII5bSgfOEpicA/JqLNimyVQFfL+T10arNK6LW4
uiPfWhHsxGtlb7Hml9yNd+8Os3jBTrz+Do8EDwcYbKG4efC9PL4ZR8Pop0uDGaaU
kI5buvF6tjMCAwEAAaOCAV8wggFbMA4GA1UdDwEB/wQEAwIBhjAdBgNVHSUEFjAU
BggrBgEFBQcDAQYIKwYBBQUHAwIwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
FgQUsEOeMHD23v1UHhI6HeD3Ycv7IMcwHwYDVR0jBBgwFoAUj/BLf6guRSSuTVD6
Y5qL3uLdG7wwewYIKwYBBQUHAQEEbzBtMC4GCCsGAQUFBzABhiJodHRwOi8vb2Nz
cDIuZ2xvYmFsc2lnbi5jb20vcm9vdHIzMDsGCCsGAQUFBzAChi9odHRwOi8vc2Vj
dXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9yb290LXIzLmNydDA2BgNVHR8ELzAt
MCugKaAnhiVodHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL3Jvb3QtcjMuY3JsMCEG
A1UdIAQaMBgwCAYGZ4EMAQIBMAwGCisGAQQBoDIKAQMwDQYJKoZIhvcNAQELBQAD
ggEBALJnnt6rIjXwl6+6W0XrYYuSF91baTVFiFLKG7I8YBEhiLBsYL4juDZcyWtB
Pvw1zHZHYWRC//ruG6diKB/hxeIfOU563a3dP0ct8GGakGL7Q/nKleSoEWjnabNO
PeH4brw+ZgbRz7VBPXv+6y+P+1qqwUrvLmgawPRW4HYMQ65TXnKh7O7lN/SacDbZ
53J0YTNPy4JLQoK/gqGFmPiHOLbLre/F4gblRnsRmDY6Ow10Cv+6+a/ktWzmSioK
oeU4gGL5XuXhBJFv8kkJkgLNSotWuE/r/izVYXzcaI6e2hgwnA6AB2e2vCJmS1ow
ZqY63DngXSg4Vs9JR97+KjaDGu0=
-----END CERTIFICATE-----
''';

// Creates an [http.Client] that is pinned to api.unsplash.com's certificate.
//
// When [_kUnsplashCertPem] is empty (development / CI) the function falls back
// to standard system-CA validation so tests and builds can succeed before the
// production certificate is embedded.
http.Client createPinnedHttpClient() {
  if (_kUnsplashCertPem.isEmpty) {
    return http.Client();
  }

  // Remove all system-trusted CAs so only our pinned chain is trusted.
  // Any certificate not in this chain will trigger badCertificateCallback,
  // which we hard-reject — effectively enforcing the pin.
  final context = SecurityContext(withTrustedRoots: false)
    ..setTrustedCertificatesBytes(_kUnsplashCertPem.codeUnits);

  return IOClient(
    HttpClient(context: context)
      ..badCertificateCallback = (_, _, _) => false,
  );
}
