import 'dart:io';
import 'package:dio/dio.dart';

class ResumableDownloader {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;
  bool _isPaused = false;
  String? _currentUrl;
  String? _currentSavePath;
  int _downloadedBytes = 0;
  Function(int, int)? _onProgressCallback;

  Future<void> download(
      String url,
      String savePath, {
        required void Function(int received, int total) onProgress,
      }) async {
    _currentUrl = url;
    _currentSavePath = savePath;
    _onProgressCallback = onProgress;
    _isPaused = false;

    final file = File(savePath);
    final dir = file.parent;

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _downloadedBytes = await _getExistingFileSize(file);

    try {
      final totalFileSize = await _getTotalFileSize(url);
      _validateFileSize(file, totalFileSize);

      _cancelToken = CancelToken();

      await _performDownload(
        url: url,
        savePath: savePath,
        file: file,
        totalFileSize: totalFileSize,
      );
    } on DioException catch (e) {
      _handleDownloadError(e);
    }
  }

  Future<int> _getExistingFileSize(File file) async {
    return file.existsSync() ? await file.length() : 0;
  }

  Future<int> _getTotalFileSize(String url) async {
    try {
      final response = await _dio.head(url);
      return int.parse(
        response.headers.value(HttpHeaders.contentLengthHeader) ?? '0',
      );
    } catch (_) {
      return 0;
    }
  }

  void _validateFileSize(File file, int totalFileSize) async {
    if (totalFileSize > 0 && _downloadedBytes > totalFileSize) {
      await file.delete();
      _downloadedBytes = 0;
    }
  }

  Future<void> _performDownload({
    required String url,
    required String savePath,
    required File file,
    required int totalFileSize,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        options: Options(
          headers: {HttpHeaders.rangeHeader: 'bytes=$_downloadedBytes-'},
        ),
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          // عند الإيقاف لا تعمل أي تحديث
          if (_cancelToken?.isCancelled == true) return;

          final totalReceived = _downloadedBytes + received;
          final calculatedTotal = totalFileSize > 0
              ? totalFileSize
              : _downloadedBytes + total;

          _onProgressCallback?.call(totalReceived, calculatedTotal);
        },
      );
      print('✅ Download completed: $savePath');
    } on DioException catch (e) {
      _handleDownloadError(e);
    }
  }


  void pause() {
    _isPaused = true;
    _cancelToken?.cancel('Paused by user');
    print('⏸️ Download paused');
  }

  Future<void> resume() async {
    if (_currentUrl == null || _currentSavePath == null) return;

    print('▶️ Resuming download...');
    await download(
      _currentUrl!,
      _currentSavePath!,
      onProgress: _onProgressCallback!,
    );
  }

  void _handleDownloadError(DioException e) {
    if (CancelToken.isCancel(e)) {
      print('⏸️ Download paused');
    } else {
      print('❌ Download error: ${e.message}');
      throw e;
    }
  }
}