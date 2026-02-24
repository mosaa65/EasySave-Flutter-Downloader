import 'package:easysave3/services/resumable_downloader.dart';

class DownloadController {
  static final DownloadController _instance = DownloadController._internal();
  factory DownloadController() => _instance;
  DownloadController._internal();

  final Map<String, ResumableDownloader> _downloaders = {};

  void add(String fileName, ResumableDownloader downloader) {
    _downloaders[fileName] = downloader;
  }

  void pause(String fileName) {
    _downloaders[fileName]?.pause();
  }

  void resume(String fileName) {
    _downloaders[fileName]?.resume();
  }

  void remove(String fileName) {
    _downloaders.remove(fileName);
  }

  bool has(String fileName) => _downloaders.containsKey(fileName);
}
