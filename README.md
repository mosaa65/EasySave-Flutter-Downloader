<div align="center">

# 📥 EasySave App
**A powerful and versatile media downloader application built with Flutter.**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

</div>

## 📖 About The Project

**EasySave** is a comprehensive mobile application designed to simplify the process of downloading media (videos and images) from various social media platforms, including Instagram, Snapchat, YouTube, and more. 

Built with **Flutter** and **Dart**, it features a sleek user interface, robust background downloading capabilities, and seamless ad monetization integration.

### ✨ Key Features

- 🚀 **Multi-Platform Support:** Download content from Instagram, Snapchat, YouTube, and generic web videos.
- ⏬ **Background & Resumable Downloads:** Utilizing `flutter_downloader` to ensure downloads continue even when the app is minimized.
- 📁 **Download Management:** Track active downloads and easily manage/view downloaded files.
- 🌓 **Theming:** Full support for System-based Light and Dark modes.
- 💰 **Monetization:** Integrated with Google Mobile Ads (AdMob) for banner and interstitial ads.
- 🔒 **Permissions Handling:** Robust storage permission management, including Android 11+ `MANAGE_EXTERNAL_STORAGE`.

---

## 🛠️ Tech Stack & Dependencies

- **Framework:** [Flutter](https://flutter.dev/) (SDK: ^3.7.0)
- **Language:** Dart
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Networking/HTTP:** [Dio](https://pub.dev/packages/dio), [Http](https://pub.dev/packages/http)
- **Downloading engine:** [flutter_downloader](https://pub.dev/packages/flutter_downloader)
- **Ads Integration:** [google_mobile_ads](https://pub.dev/packages/google_mobile_ads)
- **Local Storage:** [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Permissions:** [permission_handler](https://pub.dev/packages/permission_handler)
- **YouTube Extraction:** [youtube_explode_dart](https://pub.dev/packages/youtube_explode_dart)

---

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

- Flutter SDK (version ^3.7.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions installed
- A physical Android device or an Emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/EasySave-App.git
   ```

2. **Navigate to the project directory**
   ```bash
   cd EasySave-App
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Running on Android specific configuration

Ensure that you have set up the appropriate AdMob App ID in your `android/app/src/main/AndroidManifest.xml` under the `<meta-data>` tag as required by the `google_mobile_ads` package.

---

## 📁 Project Structure

```
lib/
├── screens/
│   ├── HomeScreen.dart             # Main dashboard
│   ├── ActiveDownloadsPage.dart    # Tracking ongoing downloads
│   ├── DownloadedFilesPage.dart    # Gallery/Manager for saved files
│   └── AdSettingsPage.dart         # Ad configurations
├── services/
│   ├── InstagramDownloader.dart    # IG download logic
│   ├── SnapchatDownloader.dart     # Snapchat logic
│   ├── VideoDownloader*.dart       # Generic / Pro video downloaders
│   ├── ad_manager.dart             # Google AdMob handler
│   ├── active_download_manager.dart# Provider for download states
│   └── resumable_downloader.dart   # Resumable download engine
└── main.dart                       # App entry point & initialization
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
Feel free to check the [issues page](https://github.com/your-username/EasySave-App/issues).

---
*If you find this project useful, consider giving it a ⭐️!*
