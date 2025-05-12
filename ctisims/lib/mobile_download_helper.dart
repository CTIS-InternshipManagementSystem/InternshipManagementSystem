// Mobile-specific download helper that serves as a compatibility layer
// This is used with conditional imports to maintain consistent API

// AnchorElement mock for mobile platform
class AnchorElement {
  AnchorElement({required this.href});
  
  final String href;
  late String download;
  
  // No-op for mobile platforms
  void click() {
    // Mobile platforms use direct file download methods
    // File download is handled in the main code for mobile
  }
}