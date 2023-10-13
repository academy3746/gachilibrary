// ignore_for_file: avoid_print, prefer_collection_literals
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:gachilibrary/features/webview/widgets/app_version_checker.dart';
import 'package:gachilibrary/features/webview/widgets/back_action_handler.dart';
import 'package:gachilibrary/features/webview/widgets/kakao_channel.dart';
import 'package:gachilibrary/features/webview/widgets/permission_manager.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../firebase/fcm_controller.dart';
import '../webview/widgets/app_cookie_manager.dart';

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

  /// Import Kakao Channel Direction
  late final KakaoChannel _kakaoChannel;

  /// Import Back Action Handler
  late final BackActionHandler _backActionHandler;

  /// Get User Token from Firebase Server
  Future<String?> _getPushToken() async {
    return await _msgController.getToken();
  }

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) WebView.platform = AndroidWebView();

    _getPushToken();

    /// 저장매체 접근 권한 요청
    StoragePermissionManager permissionManager =
        StoragePermissionManager(context);
    permissionManager.requestStoragePermission();

    /// App Version Check
    AppVersionCheck appVersionCheck = AppVersionCheck(context);
    appVersionCheck.getAppVersion();

    /// Initialize Cookies
    _cookieManager = AppCookieManager(url, url);

    /// Initialize Kakao Channel URL
    _kakaoChannel = KakaoChannel(context);
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
                          await _cookieManager?.hasCookies("token") ?? false;

                      /// Exit Application whether or not
                      webviewController.currentUrl().then((url) async {
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
                        await _cookieManager?.setCookies(
                          _cookieManager!.cookieValue,
                          _cookieManager!.domain,
                          _cookieManager!.cookieName,
                          _cookieManager!.url,
                        );

                        /// Check Maintained Cookies Statement
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

                      if (request.url
                          .startsWith("https://pf.kakao.com/_TWxjxbxb")) {
                        _kakaoChannel.launchChannel(url);
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
