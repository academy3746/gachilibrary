import 'package:flutter/material.dart';
import 'package:gachilibrary/features/webview/widgets/confirm_button.dart';
import 'package:url_launcher/url_launcher.dart';

class KakaoChannel {
  final BuildContext context;

  KakaoChannel(this.context);

  void launchChannel(String url) async {
    final channelUrl = Uri.parse("https://pf.kakao.com/_TWxjxbxb");

    if (await canLaunchUrl(channelUrl)) {
      await launchUrl(channelUrl);
    } else {
      ConfirmButton(
        onPressed: () {
          Navigator.pop(context);
        },
        text: "유효하지 않은 카카오톡 채널입니다.",
      );
    }
  }
}