// ignore_for_file: avoid_print, prefer_collection_literals
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:package_info/package_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

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
  final WebviewCookieManager cookieManager = WebviewCookieManager();
  final String cookieValue = "cookieValue";
  final String domain = "celest.cafe24.com";
  final String cookieName = "cookieName";

  /// 저장매체 접근 권한 요청
  void _requestStoragePermission() async {
    PermissionStatus status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      PermissionStatus result =
          await Permission.manageExternalStorage.request();
      if (!result.isGranted) {
        print('Permission denied by user');
      } else {
        print('Permission has submitted.');
      }
    }
  }

  /// Store Direction
  void _getAppVersion(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    print("User Device App Version: $version");

    /// Version Management (Manually)
    const String androidVersion = "1.0.6";
    const String iosVersion = "2.1.0";

    if ((Platform.isAndroid && version != androidVersion) ||
        (Platform.isIOS && version != iosVersion)) {

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("앱 업데이트 정보"),
            content: const Text("앱 버전이 최신이 아닙니다.\n업데이트를 위해 마켓으로 이동하시겠습니까?"),
            actions: [
              TextButton(
                onPressed: () async {
                  if (Platform.isAndroid) {
                    final Uri playStoreUri = Uri.parse(
                        "market://details?id=kr.beaversoft.gachilibrary");
                    if (await canLaunchUrl(playStoreUri)) {
                      await launchUrl(playStoreUri);
                    } else {
                      throw "Can not launch $playStoreUri";
                    }
                  } else if (Platform.isIOS) {
                    final Uri appStoreUri = Uri.parse(
                        "https://apps.apple.com/app/치매북스/id1557576686");
                    if (await canLaunchUrl(appStoreUri)) {
                      await launchUrl(appStoreUri);
                    } else {
                      throw "Can not launch $appStoreUri";
                    }
                  }

                  if (!mounted) return;

                  Navigator.of(context).pop();
                },
                child: const Text("확인"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("취소"),
              ),
            ],
          );
        },
      );
    }
  }

  /// 카카오톡 채널 Direction (Link to built-in web browser)
  void launchURL(String url) async {
    final channelUrl = Uri.parse("https://pf.kakao.com/_TWxjxbxb");

    if (await canLaunchUrl(channelUrl)) {
      await launchUrl(channelUrl);
    } else {
      print("Can not launch $channelUrl");
    }
  }

  /// 뒤로 가기 Action
  Future<bool> _onWillPop() async {
    if (_viewController == null) {
      return false;
    }

    final currentUrl = await _viewController?.currentUrl();

    if (currentUrl == "$url/main.php") {
      if (!mounted) return false;
      return showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("앱을 종료하시겠습니까?"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  print("앱이 포그라운드에서 종료되었습니다.");
                },
                child: const Text("확인"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  print("앱이 종료되지 않았습니다.");
                },
                child: const Text("취소"),
              ),
            ],
          );
        },
      ).then((value) => value ?? false);
    } else if (await _viewController!.canGoBack() && _viewController != null) {
      _viewController!.goBack();
      print("이전 페이지로 이동하였습니다.");

      isInMainPage = false;
      return false;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) WebView.platform = AndroidWebView();
    _requestStoragePermission();
    _getAppVersion(context);
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
                onWillPop: _onWillPop,
                child: SafeArea(
                  child: WebView(
                    initialUrl: url,
                    javascriptMode: JavascriptMode.unrestricted,
                    onWebResourceError: (error) {
                      print("Error Code: ${error.errorCode}");
                      print("Error Description: ${error.description}");
                    },
                    onWebViewCreated: (WebViewController webviewController) async {
                      _controller.complete(webviewController);
                      _viewController = webviewController;

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
                        await cookieManager.getCookies(null);

                        await cookieManager.setCookies([
                          Cookie(cookieName, cookieValue)
                            ..domain = domain
                            ..expires = DateTime.now().add(
                              const Duration(
                                days: 90,
                              ),
                            )
                            ..httpOnly = false
                        ]);
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
                        launchURL(request.url);
                        return NavigationDecision.prevent;
                      }

                      return NavigationDecision.navigate;
                    },
                    zoomEnabled: true,
                    gestureNavigationEnabled: true,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                      Factory<EagerGestureRecognizer>(
                              () => EagerGestureRecognizer())
                    ].toSet(),
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
