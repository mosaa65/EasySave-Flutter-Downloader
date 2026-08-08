Viewed README.md:1-23

# 1. Project Overview

* **Project Name:** EasySave (easysave3)
* **Project Type:** Mobile Media Downloader & Management Application (Cross-Platform)
* **Business Domain:** Digital Media Processing & Social Media Utilities
* **Primary Purpose:** Provide high-speed media extraction (YouTube streams, Instagram Reels, Snapchat Stories), resumable HTTP range-based downloading, native background task queueing, local file vault management, and ad monetization controls.
* **Target Users:** Mobile users requiring offline media preservation and file management across Android and iOS devices.
* **Main Business Value:** Eliminates backend conversion server overhead by performing client-side stream resolution, prevents network bandwidth loss through HTTP Range pause/resume capabilities, and monetizes mobile utility applications via Google Mobile Ads.

---

# 2. Resume Summary (Very Important)

* Engineered a cross-platform mobile application using Flutter and Dart for multi-source media extraction, handling YouTube stream manifests (video/audio muxed, video-only 1080p–360p, MP3/M4A audio) and social media DOM structures.
* Built a resilient resumable download engine using `Dio` with HTTP Range headers (`bytes=X-`), enabling users to pause and resume multi-megabyte transfers without data corruption or loss.
* Designed a reactive state management layer utilizing Singleton patterns (`AdManager`, `ActiveDownloadManager`, `DownloadController`) and `Provider`/`ChangeNotifier` for real-time progress broadcasting and background queue execution via `flutter_downloader`.
* Integrated Google Mobile Ads SDK (AdMob) with automated 5-minute interstitial ad throttling, retry backoff logic, and persistent user configuration toggles via `SharedPreferences`.

---

# 3. Core Features

* **YouTube Stream Manifest Extraction:** Resolves YouTube video/audio streams across quality tiers (1080p, 720p, 480p, 360p) and extracts high-bitrate audio-only streams using `youtube_explode_dart`.
* **Social Media Scraper Engine:** Scrapes Instagram Reels and Snapchat Stories to extract direct MP4 video URLs from `window._sharedData` script tags and Regex patterns.
* **Resumable HTTP Range Downloader:** Implements HTTP Range byte transfers with pause, resume, and cancel token support via `Dio`.
* **Media Vault File Manager:** Scans and manages saved files in `/storage/emulated/0/Download/EasySave`, supporting list/grid views, file size/date formatting, native previews (`open_file`), and system cross-file sharing (`share_plus`).
* **Monetization & Privacy Settings:** Manages AdMob Banner, Interstitial, and Rewarded ads with user privacy controls and local preference storage.

---

# 4. Technical Stack

* **Programming Languages:** Dart (`^3.7.0`)
* **Mobile Framework:** Flutter SDK (`^3.7.0`)
* **Networking & HTTP:** `Dio` (`^5.8.0+1`), `http` (`^1.3.0`)
* **Media Extraction & Scraping:** `youtube_explode_dart` (`^2.3.10`), `html` (`^0.15.1`)
* **Downloader Engine & Storage:** `flutter_downloader` (`^1.12.0`), `path_provider` (`^2.1.5`), `flutter_cache_manager` (`^3.4.1`)
* **State Management & Architecture:** `Provider` (`^6.1.4`), `ChangeNotifier`, Singleton Pattern
* **Local Storage & Preferences:** `shared_preferences` (`^2.5.3`)
* **Media & OS Integration:** `open_file` (`^3.5.10`), `share_plus` (`^10.1.4`), `permission_handler` (`^11.4.0`)
* **Monetization:** `google_mobile_ads` (AdMob `^5.3.1`)
* **UI Libraries & Styling:** Material Design 3, `marquee` (`^2.3.0`), Google Fonts (`Cairo`, `PoetsenOne`, `Pacifico`, `ElMessiri`)
* **Build Tools & Development:** Flutter CLI, `flutter_lints` (`^5.0.0`), `flutter_launcher_icons` (`^0.13.1`)

---

# 5. Architecture Analysis

* **Overall Architecture Style:** Layered Feature-Based Mobile Architecture with Singleton Service Managers and Reactive Provider State Management.
* **Folder Organization:** 
  * `lib/screens`: UI screens and page layouts (`HomeScreen`, `ActiveDownloadsPage`, `DownloadedFilesPage`, `AdSettingsPage`).
  * `lib/services`: Service managers, download engines, scrapers, and state singletons (`ad_manager`, `active_download_manager`, `download_controller`, `resumable_downloader`, `InstagramDownloader`, `SnapchatDownloader`, `VideoDownloader*`).
  * `lib/main.dart`: Concurrency bootstrapping and application entry point.
* **Separation of Concerns:** Clear isolation between presentation views, network stream extraction, resumable transfer engines, OS background queues, and monetization state handlers.
* **Maintainability & Reusability:** Modular design allows straightforward addition of new media extraction services without impacting core downloading or UI vault modules.

---

# 6. Software Engineering Practices

* **SOLID Principles:** Single Responsibility Principle applied to downloader services (scrapers isolated from network transfer engines and UI screens).
* **DRY & KISS:** Centralized state singletons (`DownloadController`, `ActiveDownloadManager`) eliminate duplicate stream tracking across routes.
* **Clean Code & OOP:** Encapsulated `ResumableDownloader` class handling `Dio` cancel tokens, file size validations, and error callbacks.
* **Error Handling & Input Sanitization:** File name sanitization (`sanitizeFileName`) using Regex (`r'[\\/:*?"<>|]'`), HTTP response validation, and network socket/timeout exception handling (`SocketException`, `TimeoutException`).
* **Asynchronous Concurrency:** Parallel library initialization in `main.dart` using `Future.wait` for `FlutterDownloader`, permissions, and `MobileAds`.

---

# 7. Database Analysis

* **Database Engine:** No remote database server; local client-side key-value persistence via `SharedPreferences`.
* **Schema & Storage Organization:** Filesystem storage targeting public Android external directories (`/storage/emulated/0/Download/EasySave`). Active download states are maintained in-memory via reactive `ActiveDownloadInfo` models.
* **Migrations / ORM:** Not applicable / Not used.

---

# 8. Security Analysis

* **Authentication & Authorization:** Not applicable (Client-side utility app).
* **Input Sanitization & Validation:** File name sanitization against path traversal vulnerabilities; URL domain whitelisting (`youtube.com`, `youtu.be`, `instagram.com`, `story.snapchat.com`) before issuing GET requests.
* **Permission Management:** Runtime permission verification (`Permission.storage`, `Permission.manageExternalStorage`) protecting filesystem writes on Android 11+.
* **Secrets & Policy Protection:** Test device ID configuration restricted to debug mode (`kDebugMode`) to comply with AdMob policy constraints.

---

# 9. API Analysis

* **API Style:** Third-party web media endpoints and Google Mobile Ads SDK integration.
* **REST & Web Scraping:** Direct HTTP GET requests to YouTube stream manifests, Instagram post endpoints (`window._sharedData`), and Snapchat story DOM elements.
* **Error Handling:** Socket and timeout exception handling with automatic banner ad retries (3 retries with 30-second backoff).

---

# 10. Deployment & Infrastructure

* **Hosting & Target Platform:** Android APK & App Bundle targets (`flutter build apk`, `flutter build appbundle`).
* **Environment Variables:** `SharedPreferences` for runtime ad preference persistence; `AdManager` test unit IDs configured in code.
* **Build Process:** Flutter CLI build chain integrating Gradle for Android and CocoaPods for iOS.
* **CI/CD:** Not verified.

---

# 11. Development Quality

* **Code Organization:** High. Clean separation between UI screens, service singletons, and transfer engines.
* **Maintainability:** High. Decoupled media extraction logic allows adding new social media scrapers independently.
* **Readability & Consistency:** High. Descriptive variable names, structured error handling, custom font styling, and localized Arabic UI strings.
* **Reusability:** High. Reusable UI components (`_buildDownloadTile`, `_buildFileGridItem`) and modular service methods.

---

# 12. Engineering Competencies Demonstrated

* Cross-Platform Mobile Development (Flutter/Dart)
* Stream Manifest Resolution & Media Processing
* Resumable Network Protocol Engineering (HTTP Range Headers)
* Asynchronous Concurrency & Reactive State Management
* Mobile OS Storage Security & Permission Management
* Web Scraping & DOM/JSON Parsing
* Mobile App Monetization Architecture (AdMob)
* Software Architecture & Design Patterns (Singleton, Provider)

---

# 13. ATS Resume Keywords

* **Frameworks & Languages:** Flutter, Dart, Material Design 3
* **Networking & Protocols:** Dio, HTTP Range Headers, Resumable Downloads, Stream Parsing, REST APIs
* **State & Architecture:** Provider, ChangeNotifier, Singleton Pattern, Feature-Based Architecture
* **Libraries & Integration:** youtube_explode_dart, flutter_downloader, google_mobile_ads (AdMob), html, path_provider, permission_handler, shared_preferences, open_file, share_plus
* **Engineering Practices:** Asynchronous Programming, Web Scraping, RegEx, Input Sanitization, Error Handling, Concurrency

---

# 14. Suggested Resume Entry

**EasySave (Flutter Media Downloader)**
*Cross-Platform Mobile Application*
Engineered a high-performance cross-platform mobile downloader for offline video and audio media extraction across major social media platforms.

* Architected a multi-source media extraction system in Flutter/Dart supporting YouTube stream manifests (video/audio muxed, video-only, MP3/M4A), Instagram Reels, and Snapchat Stories.
* Developed a custom resumable download engine using `Dio` with HTTP Range headers (`bytes=X-`), allowing users to pause and resume multi-megabyte transfers across network interruptions.
* Built a reactive state management layer with Singleton services (`AdManager`, `ActiveDownloadManager`, `DownloadController`) and `Provider` for live byte-progress updates and background execution via `flutter_downloader`.
* Implemented Android 11+ storage permission compliance (`MANAGE_EXTERNAL_STORAGE`) and built an integrated file manager with list/grid view toggling, OS media previews, and native sharing.
* Integrated Google Mobile Ads SDK (AdMob) with automated 5-minute interstitial ad throttling and persistent user preference toggles via `SharedPreferences`.

**Technologies Used:** Flutter, Dart, Dio, Provider, youtube_explode_dart, flutter_downloader, google_mobile_ads, permission_handler, shared_preferences, Material Design 3.