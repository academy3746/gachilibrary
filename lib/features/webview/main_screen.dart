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
  /// URL 초기화
  final String url = "https://celest.cafe24.com";

  /// 인덱스 페이지 초기화
  bool isInMainPage = true;

  /// Page Loading Indicator 초기화
  bool isLoading = true;

  /// 웹뷰 컨트롤러 초기화
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  WebViewController? _viewController;

  /// Import Cookie Manager
  AppCookieManager? cookieManager;

  /// Push Setting 초기화
  final MsgController _msgController = Get.put(MsgController());

  /// Get User Token
  Future<String?> _getPushToken() async {
    return await _msgController.getToken();
  }

  /// Import Kakao Channel Direction
  late final KakaoChannel _kakaoChannel;

  /// Import Back Action Handler
  late final BackActionHandler _backActionHandler;

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
    cookieManager = AppCookieManager(url);

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

                        /// Cookie Management
                        await cookieManager?.setCookies(
                          cookieManager!.cookieValue,
                          cookieManager!.domain,
                          cookieManager!.cookieName,
                          cookieManager!.url,
                        );
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
