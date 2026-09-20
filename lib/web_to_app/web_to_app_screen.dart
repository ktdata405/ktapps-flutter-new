import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core_colors.dart';
import '../core_strings.dart';
import '../core_ui_utils.dart';
import '../core_constants.dart';

class WebToAppScreen extends StatefulWidget {
  const WebToAppScreen({super.key});

  @override
  State<WebToAppScreen> createState() => _WebToAppScreenState();
}

class _WebToAppScreenState extends State<WebToAppScreen> {
  final TextEditingController _urlController = TextEditingController();
  late final WebViewController _webViewController;
  bool _showPreview = false;
  bool _isLoading = false;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            ktShowCustomToast(context, 'Error loading preview');
          },
        ),
      );
  }

  void _handleConvert() {
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      ktShowCustomToast(context, KtStrings.invalidUrl);
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    setState(() {
      _currentUrl = url;
      _showPreview = true;
    });
    _webViewController.loadRequest(Uri.parse(url));
  }

  void _showDownloadOptions() {
    ktShowDetailsSheet(
      context: context,
      title: KtStrings.convertToApp,
      icon: Icons.app_shortcut,
      themeColor: ktPrimary,
      details: [
        {
          'label': 'PLATFORM',
          'value': 'Android',
          'isHighlight': true,
        },
        {
          'label': 'URL',
          'value': _currentUrl ?? _urlController.text,
        },
        {
          'label': 'STATUS',
          'value': 'Ready to Convert',
          'color': ktSuccess,
        },
      ],
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            ktShowCustomToast(context, 'Downloading Native APK...');
          },
          icon: const Icon(Icons.android, color: Colors.white),
          label: const Text(KtStrings.downloadNativeApk),
          style: ElevatedButton.styleFrom(
            backgroundColor: ktSuccess,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            ktShowCustomToast(context, 'Installing Web App...');
          },
          icon: const Icon(Icons.web, color: ktPrimary),
          label: const Text(KtStrings.installWebApp),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: ktPrimary),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ktBgDark : ktLightScaffoldBg,
      appBar: AppBar(
        title: const Text(
          KtStrings.convertToApp,
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [ktPrimary, ktSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildInputSection(isDark),
          Expanded(
            child: _showPreview ? _buildPreviewSection(isDark) : _buildEmptyState(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            KtStrings.enterUrl,
            style: TextStyle(
              color: isDark ? Colors.white70 : ktDarkText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            style: TextStyle(color: isDark ? Colors.white : ktDarkText, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: KtStrings.urlHint,
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
              prefixIcon: const Icon(Icons.link, color: ktPrimary),
              filled: true,
              fillColor: isDark ? Colors.black26 : ktGray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _handleConvert(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handleConvert,
              style: ElevatedButton.styleFrom(
                backgroundColor: ktPrimary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: ktPrimary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                KtStrings.convertToApp,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: isDark ? Colors.white.withOpacity(0.05) : ktGray50,
                child: Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, size: 18, color: ktPrimary),
                    const SizedBox(width: 12),
                    const Text(
                      KtStrings.webPreview,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const Spacer(),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: ktPrimary),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: WebViewWidget(controller: _webViewController),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: ktEditButton(
                  onPressed: _showDownloadOptions,
                  label: 'Proceed to Conversion',
                ),
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: ktPrimary),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ktPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.web_asset, size: 64, color: ktPrimary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'Enter a URL to see preview',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
