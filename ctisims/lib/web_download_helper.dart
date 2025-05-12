// Import js_interop and web specific packages
import 'dart:js_interop';
import 'package:web/web.dart' as web;

// Web-safe download helper that uses js_interop instead of dart:html
class WebDownloadHelper {
  static void downloadFile(String url, String fileName) {
    // Create an anchor element using web package
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.setAttribute('download', fileName);
    anchor.click();
  }
}

// Mock for dart:html.AnchorElement to maintain API compatibility
class AnchorElement {
  AnchorElement({required this.href});
  
  final String href;
  late String download;
  
  void click() {
    WebDownloadHelper.downloadFile(href, download);
  }
}