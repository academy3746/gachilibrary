// ignore_for_file: avoid_print, prefer_collection_literals, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:gachilibrary/features/firebase/fcm_controller.dart';
import 'package:gachilibrary/features/webview/widgets/app_cookie_manager.dart';
import 'package:gachilibrary/features/webview/widgets/app_version_checker.dart';
import 'package:gachilibrary/features/webview/widgets/back_action_handler.dart';
import 'package:gachilibrary/features/webview/widgets/permission_manager.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScreen extends StatefulWidget {
  static String routeName = "/main";

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Initialize Main Page URL
  final String url = "https://celest.cafe24.com";

  /// Initialize Main Page Statement
  bool isInMainPage = true;

  /// Initialize Page Loading Indicator
  bool isLoading = true;

  /// Initialize WebView Controller
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  WebViewController? _viewController;

  /// Initialize Push Setting
  final MsgController _msgController = Get.put(MsgController());

  /// Import Cookie Manager
  AppCookieManager? _cookieManager;

  /// Import Back Action Handler
  late final BackActionHandler _backActionHandler;

  /// App ~ Web Server Communication
  JavascriptChannel _flutterWebviewProJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
      name: 'flutter_webview_pro',
      onMessageReceived: (JavascriptMessage message) async {
        Map<String, dynamic> jsonData = jsonDecode(message.message);

        if (jsonData['handler'] == 'webviewJavaScriptHandler') {

          if (jsonData['action'] == 'setUserId') {
            String userId = jsonData['data']['userId'];

            GetStorage().write('userId', userId);

            print("Communication Succeed: ${message.message}");

            String? fcmToken = await _msgController.getToken();

            if (fcmToken != null) {
              _viewController?.runJavascript("""
                tokenUpdate("$fcmToken")
              """);
            } else {
              print("Failed Message: ${message.message}");
            }
          }
        }

        setState(() {});
      },
    );
  }

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    /// 저장매체 접근 권한 요청
    StoragePermissionManager permissionManager =
        StoragePermissionManager(context);
    permissionManager.requestStoragePermission();

    /// App Version Check
    AppVersionCheck appVersionCheck = AppVersionCheck(context);
    appVersionCheck.getAppVersion();

    /// Initialize Cookies
    _cookieManager = AppCookieManager(url, url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return WillPopScope(
                onWillPop: () => _backActionHandler.onWillPop(),
                child: SafeArea(
                  child: WebView(
                    initialUrl: url,
                    javascriptMode: JavascriptMode.unrestricted,
                    javascriptChannels: <JavascriptChannel>[
                      _flutterWebviewProJavascriptChannel(context),
                    ].toSet(),
                    onWebResourceError: (error) {
                      print("Error Code: ${error.errorCode}");
                      print("Error Description: ${error.description}");
                    },
                    onWebViewCreated:
                        (WebViewController webviewController) async {
                      _controller.complete(webviewController);
                      _viewController = webviewController;
                      _backActionHandler =
                          BackActionHandler(context, _viewController, url);
                      bool hasCookies =
                          await _cookieManager?.hasCookies("PHPSESSID") ??
                              false;

                      webviewController.currentUrl().then((url) async {
                        /// Exit Application whether or not
                        if (url == "$url/main.php") {
                          setState(() {
                            isInMainPage = true;
                          });
                        } else {
                          setState(() {
                            isInMainPage = false;
                          });
                        }

                        /// Get Cookies from Web Server
                        await _cookieManager!.setCookies(
                          _cookieManager!.cookieValue,
                          _cookieManager!.domain,
                          _cookieManager!.cookieName,
                          _cookieManager!.url,
                        );

                        /// 1. GET Cookie Parameter through PHPSESSID
                        /// 2. Check Returned Cookie Parameters
                        /// 3. Direct to Main URL
                        if (hasCookies) {
                          _viewController?.loadUrl("${url}main.php");
                        } else {
                          _viewController?.loadUrl("$url");
                        }
                      });
                    },
                    onPageStarted: (String url) async {
                      print("현재 페이지: $url");
                      setState(() {
                        isLoading = true;
                      });
                    },
                    onPageFinished: (String url) async {
                      setState(() {
                        isLoading = false;
                      });
                    },
                    navigationDelegate: (NavigationRequest request) async {
                      if (request.url.startsWith("tel:")) {
                        if (await canLaunchUrl(Uri.parse(request.url))) {
                          await launchUrl(Uri.parse(request.url));
                        }

                        return NavigationDecision.prevent;
                      }

                      if (!request.url.contains(url)) {
                        if (await canLaunchUrl(Uri.parse(request.url))) {
                          await launchUrl(
                            Uri.parse(request.url),
                            mode: LaunchMode.externalApplication,
                          );
                        }

                        return NavigationDecision.prevent;
                      }

                      return NavigationDecision.navigate;
                    },
                    zoomEnabled: true,
                    gestureNavigationEnabled: true,
                    gestureRecognizers: Set()
                      ..add(
                        Factory<EagerGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      ),
                  ),
                ),
              );
            },
          ),
          isLoading
              ? const Center(
                  child: CircularProgressIndicator.adaptive(),
                )
              : Container(),
        ],
      ),
    );
  }
}
