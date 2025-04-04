# Dark Mode Implementation Guide

This document describes how dark mode is implemented in the CTIS IMS application and how to maintain it for future development.

## Overview

Dark mode functionality is provided through a `ThemeProvider` class that uses Flutter's `ChangeNotifier` pattern to propagate theme changes throughout the app. The app uses custom `AppThemes` to define styling for both light and dark modes.

## Key Files

- `themes/Theme_provider.dart` - Contains the ThemeProvider class for managing dark mode state
- `themes/app_themes.dart` - Contains theme definitions for both light and dark modes
- `main.dart` - Configures the MaterialApp with theme settings

## How to Use Dark Mode in New Pages

When creating new pages or components, follow these guidelines to ensure dark mode works properly:

1. **Import the ThemeProvider**
```dart
import 'package:provider/provider.dart';
import 'themes/Theme_provider.dart';
```

2. **Access Theme State in Widgets**
```dart
final themeProvider = Provider.of<ThemeProvider>(context);
final isDark = themeProvider.isDarkMode;
```

3. **Add the Toggle Button to AppBar**
```dart
appBar: AppBar(
  title: const Text('Page Title'),
  actions: [
    IconButton(
      icon: Icon(
        isDark ? Icons.dark_mode : Icons.light_mode,
        color: Colors.grey,
      ),
      tooltip: 'Toggle Dark Mode',
      onPressed: () {
        themeProvider.toggleTheme();
      },
    ),
  ],
),
```

4. **Use Theme-Aware Colors**
Instead of hardcoding colors, use theme-aware alternatives:

```dart
// Avoid:
final textColor = Colors.black;

// Better:
final textColor = Theme.of(context).textTheme.bodyLarge?.color;

// Or for conditional styles:
final textColor = isDark ? Colors.white : Colors.black;
```

5. **For Dialogs and Modals**
When creating dialogs or modals, make sure to pass the dark mode state:

```dart
final dialogBgColor = isDark ? Colors.grey[850] : Colors.white;

showDialog(
  context: context,
  builder: (context) {
    return AlertDialog(
      backgroundColor: dialogBgColor,
      title: Text("Title", style: TextStyle(color: textColor)),
      // ...
    );
  }
);
```

## Troubleshooting

If you notice inconsistencies in dark mode:

1. Check if the page is properly importing and using the ThemeProvider
2. Ensure no hardcoded colors are being used for backgrounds, text, or components
3. For custom components, ensure they accept and respond to the theme changes
4. When using DropdownButton or similar widgets, set the `dropdownColor` property

## Best Practices

1. Use Theme.of(context) for colors when possible
2. For custom or complex components, use the isDark boolean from ThemeProvider
3. Avoid hardcoding colors in styles
4. Test both light and dark modes when making UI changes
5. Use the predefined themes in app_themes.dart for consistency 