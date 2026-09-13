// lib/core/network/browser_url.dart
//
// Merapikan alamat di bilah browser. Di luar web tidak melakukan apa-apa.

export 'browser_url_stub.dart'
    if (dart.library.js_interop) 'browser_url_web.dart';
