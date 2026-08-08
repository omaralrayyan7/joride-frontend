import 'dart:html' as web_html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Web implementation: renders HyperPay's hosted checkout page inside a
/// sandboxed iframe via `HtmlElementView`.
Widget buildHyperPayView(String widgetUrl) {
  final viewId = 'hyperpay-iframe-${DateTime.now().microsecondsSinceEpoch}';

  ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) {
    return web_html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..src = widgetUrl;
  });

  return HtmlElementView(viewType: viewId);
}
