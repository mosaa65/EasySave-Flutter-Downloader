import 'package:flutter/material.dart';

class ActiveDownloadInfo {
  final String fileName;
  double progress;
  bool isDownloading;
  DateTime? lastUpdated;

  ActiveDownloadInfo({
    required this.fileName,
    this.progress = 0.0,
    this.isDownloading = true,
  }) : assert(progress >= 0.0 && progress <= 1.0);

  void toggle() {
    isDownloading = !isDownloading;
  }
}

class ActiveDownloadManager extends ChangeNotifier {
  static final ActiveDownloadManager _instance = ActiveDownloadManager._internal();
  factory ActiveDownloadManager() => _instance;
  ActiveDownloadManager._internal();

  final List<ActiveDownloadInfo> _downloads = [];

  List<ActiveDownloadInfo> get downloads => List.unmodifiable(_downloads);

  void addDownload(String fileName) {
    // بدال ما يولّد معرف ثاني، خليه يخزن اللي أنت مرسله فقط
    _downloads.add(ActiveDownloadInfo(fileName: fileName));
    notifyListeners();
  }


  void updateProgress(String fileName, double progress) {
    final index = _downloads.indexWhere((d) => d.fileName == fileName);
    if (index == -1) return;

    _downloads[index].progress = progress.clamp(0.0, 1.0);
    _downloads[index].lastUpdated = DateTime.now();
    notifyListeners();
  }

  void setDownloading(String fileName, bool downloading) {
    final index = _downloads.indexWhere((d) => d.fileName == fileName);
    if (index == -1) return;

    _downloads[index].isDownloading = downloading;
    notifyListeners();
  }

  void toggleDownload(String fileName) {
    final index = _downloads.indexWhere((d) => d.fileName == fileName);
    if (index == -1) return;

    _downloads[index].toggle();
    notifyListeners();
  }

  void removeDownload(String fileName) {
    _downloads.removeWhere((d) => d.fileName == fileName);
    notifyListeners();
  }

}