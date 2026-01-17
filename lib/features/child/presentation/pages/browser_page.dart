import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:safebrowser/core/services/webview_safety_manager.dart';
import 'package:safebrowser/features/parent/data/models/child_profile_model.dart';
import 'package:safebrowser/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:safebrowser/features/child/presentation/widgets/pin_lock_screen.dart';

class BrowserPage extends StatefulWidget {
  final String? initialUrl;
  final ChildProfile? childProfile;
  const BrowserPage({Key? key, this.initialUrl, this.childProfile}) : super(key: key);

  @override
  _BrowserPageState createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  final WebViewSafetyManager _safetyManager = WebViewSafetyManager();
  
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  bool isLoading = false;
  bool isSecure = true;

  @override
  void initState() {
    super.initState();
    url = widget.initialUrl ?? "https://www.google.com";
    urlController.text = url;
  }

  void _requestExit() {
    if (widget.childProfile == null) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinLockScreen(
          requiredPin: widget.childProfile!.pin,
          onPinVerified: (pin) {
            Navigator.of(context).pop(); // Clear PIN screen
            Navigator.of(context).pop(); // Exit Browser
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _requestExit();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: _requestExit,
          ),
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: "Search or enter URL",
                prefixIcon: Icon(
                  isSecure ? Icons.lock : Icons.lock_open,
                  size: 18,
                  color: isSecure ? Colors.green : Colors.orange,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              onSubmitted: (value) {
                var uri = Uri.parse(value);
                if (uri.scheme.isEmpty) {
                  uri = Uri.parse("https://www.google.com/search?q=$value");
                }
                webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(uri.toString())));
              },
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: () => webViewController?.reload(),
            ),
          ],
        ),
        body: Column(
          children: [
            progress < 1.0
                ? LinearProgressIndicator(value: progress, minHeight: 2)
                : const SizedBox(height: 2),
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    key: webViewKey,
                    initialUrlRequest: URLRequest(url: WebUri(url)),
                    initialOptions: _safetyManager.webViewOptions,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                      _safetyManager.initialize(controller);
                      
                      // Set context for logging
                      if (widget.childProfile != null) {
                        final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
                        if (authNotifier.user != null) {
                          _safetyManager.setContext(
                            parentId: authNotifier.user!.uid,
                            childId: widget.childProfile!.id,
                          );
                        }
                      }
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                        isSecure = url?.scheme == 'https';
                        isLoading = true;
                      });
                    },
                    onLoadStop: (controller, url) async {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                        isLoading = false;
                      });
                      
                      // Trigger safety analysis
                      if (url != null) {
                        final title = await controller.getTitle() ?? "";
                        _safetyManager.analyzePageContent(controller, url, title);
                      }
                    },
                    onProgressChanged: (controller, progress) {
                      setState(() {
                        this.progress = progress / 100;
                      });
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      // Pre-load URL analysis
                      final uri = navigationAction.request.url;
                      if (uri != null) {
                        // Note: In a full implementation, we'd block here if analyzeUrl fails
                        debugPrint("Navigating to: $uri");
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                  ),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => webViewController?.goBack(),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => webViewController?.goForward(),
              ),
              IconButton(
                icon: const Icon(Icons.shield_outlined, color: Colors.blue),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SafeBrowse Protection Active')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  // Show history
                },
              ),
              IconButton(
                icon: const Icon(Icons.tab),
                onPressed: () {
                  // Show tabs
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
