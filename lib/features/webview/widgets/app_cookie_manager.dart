// ignore_for_file: avoid_print

import 'dart:io';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class AppCookieManager {
  final WebviewCookieManager _cookieManager = WebviewCookieManager();
  final String _cookieValue = "cookieValue";
  final String _domain;
  final String _cookieName = "cookieName";
  final String _url;

  AppCookieManager(
    this._url,
    this._domain,
  );

  /// Getter
  String get cookieValue => _cookieValue;

  String get domain => _domain;

  String get cookieName => _cookieName;

  String get url => _url;

  Future<void> setCookies(
      String cookieValue, String domain, String cookieName, String url) async {
    await _cookieManager.getCookies(url);

    await _cookieManager.setCookies([
      Cookie(cookieName, cookieValue)
        ..domain = domain
        ..expires = DateTime.now().add(
          const Duration(
            days: 90,
          ),
        )
        ..httpOnly = false
    ]);

    var debugCookie = await _cookieManager.getCookies(url);
    print("Load Cookie Info: $debugCookie");
  }
}
