import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mobile/desktop implementation: loads HyperPay's hosted checkout page
/// directly into a native WebView.
Widget buildHyperPayView(String widgetUrl) {
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(widgetUrl));

  return WebViewWidget(controller: controller);
}
