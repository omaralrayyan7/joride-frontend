import 'package:flutter/material.dart';

import 'hyperpay_checkout_view_io.dart'
    if (dart.library.html) 'hyperpay_checkout_view_web.dart' as impl;

/// Renders HyperPay's hosted Copy&Pay checkout page in a WebView
/// (mobile/desktop) or an iframe (web).
///
/// [widgetUrl] comes straight from `ApiService.prepareHyperPayCheckout`
/// (backend HyperPayGateway E5.1) — it's the ready-to-load hosted
/// widget/redirect page, so this view just loads it as-is. It is null until
/// real HyperPay credentials are configured on the backend; callers should
/// check for that before constructing this widget (see
/// `HyperPayPaymentScreen`).
///
/// The backend confirms the actual payment outcome via webhook, not this
/// view — there is no result callback here.
class HyperPayCheckoutView extends StatelessWidget {
  final String widgetUrl;

  const HyperPayCheckoutView({super.key, required this.widgetUrl});

  @override
  Widget build(BuildContext context) => impl.buildHyperPayView(widgetUrl);
}
