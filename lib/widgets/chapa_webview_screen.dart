import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';

/// Full-screen in-app WebView that loads Chapa's hosted checkout page.
///
/// Pops `true`  → user reached the return URL (payment likely succeeded)
/// Pops `false` → user closed the sheet manually (may or may not have paid)
///
/// Either way the caller should re-check `GET /payments/:id/status`
/// — the backend webhook is the source of truth.
class ChapaWebViewScreen extends StatefulWidget {
  /// The `checkout_url` returned by POST /payments/init
  final String checkoutUrl;

  /// Any URL starting with this will be treated as "payment finished".
  /// Leave null to auto-detect from `checkout_url` hostname.
  final String? returnUrlPrefix;

  /// Optional header info (e.g. plan label + price)
  final String? title;
  final String? subtitle;

  const ChapaWebViewScreen({
    super.key,
    required this.checkoutUrl,
    this.returnUrlPrefix,
    this.title,
    this.subtitle,
  });

  @override
  State<ChapaWebViewScreen> createState() => _ChapaWebViewScreenState();
}

class _ChapaWebViewScreenState extends State<ChapaWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _pageError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (!mounted) return;
            setState(() {
              _progress = p;
              if (p < 100) _pageError = false;
            });
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _progress = 0;
              _pageError = false;
              _errorMessage = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _progress = 100);
          },
          onWebResourceError: (err) {
            if (!mounted) return;
            // Ignore minor asset errors on Chapa's page
            if (err.isForMainFrame != true) return;
            setState(() {
              _pageError = true;
              _errorMessage = err.description;
            });
          },
          onNavigationRequest: (request) {
            // ── Detect "payment finished" ──
            // Whenever the WebView tries to leave Chapa's domain
            // (i.e. go to your return_url), pop with success.
            if (_isReturnUrl(request.url)) {
              if (mounted) Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  /// True when the URL means "checkout finished".
  ///
  /// Detection order:
  ///   1. Custom `returnUrlPrefix` if provided
  ///   2. `barter://payment/return` (the deep link)
  ///   3. Any `https://payment-success-delivery.netlify.app/*`
  ///   4. Any URL that is NOT checkout.chapa.co / api.chapa.co
  bool _isReturnUrl(String url) {
    // Direct match with caller-provided prefix
    final prefix = widget.returnUrlPrefix;
    if (prefix != null && url.startsWith(prefix)) return true;

    // Deep-link scheme
    if (url.startsWith('barter://')) return true;

    // Netlify success page (default return_url)
    if (url.startsWith('https://payment-success-delivery.netlify.app')) {
      return true;
    }

    // Any other hostname that isn't part of Chapa's checkout infra
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host;
    if (host.isEmpty) return false;
    const chapaHosts = {
      'checkout.chapa.co',
      'api.chapa.co',
      'chapa.co',
      'js.chapa.co',
      'fonts.googleapis.com',
      'fonts.gstatic.com',
    };
    return !chapaHosts.contains(host) && !host.endsWith('.chapa.co');
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    // User is exiting the payment flow without finishing
    if (mounted) Navigator.of(context).pop(false);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            if (_pageError)
              _buildError()
            else
              WebViewWidget(controller: _controller),
            if (_progress < 100 && !_pageError)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 2.5,
                  backgroundColor: AppColors.primaryLight,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(false),
        tooltip: 'Cancel payment',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title ?? 'Complete payment',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              widget.subtitle!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Lock icon so user knows this is secure
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                'Chapa',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load checkout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _pageError = false;
                  _errorMessage = null;
                });
                _controller.loadRequest(Uri.parse(widget.checkoutUrl));
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}