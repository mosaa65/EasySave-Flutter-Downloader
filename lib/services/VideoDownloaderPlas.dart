import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/resumable_downloader.dart';

class VideoDownloaderPlas extends StatefulWidget {
  @override
  _VideoDownloaderPlasState createState() => _VideoDownloaderPlasState();
}

class _VideoDownloaderPlasState extends State<VideoDownloaderPlas> {

  final _urlController = TextEditingController();
  bool isLoading = false;

  String? title;
  String? thumbnailUrl;
  List<MuxedStreamInfo>? muxedStreams;
  List<VideoStreamInfo>? videoStreams;
  AudioStreamInfo? audioStream;

  final Map<String, ResumableDownloader> _downloaders = {};
  final Map<String, double> _progress = {};
  final Map<String, bool> _isDownloading = {};

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  // دالة جلب معلومات الفيديو
  Future<void> fetchVideoInfo() async {
    final url = _urlController.text.trim();
    if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء إدخال رابط YouTube صالح')),
      );
      return;
    }

    setState(() => isLoading = true);
    final yt = YoutubeExplode();

    try {
      final video = await yt.videos.get(url);
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      setState(() {
        title = video.title;
        thumbnailUrl = video.thumbnails.highResUrl;
        muxedStreams = manifest.muxed.toList();
        videoStreams = manifest.video.toList();
        audioStream = manifest.audioOnly.isNotEmpty
            ? manifest.audioOnly.withHighestBitrate()
            : null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء جلب معلومات الفيديو')),
      );
    } finally {
      yt.close();
      setState(() => isLoading = false);
    }
  }

  // إنشاء مسار حفظ الملف
  Future<String> _getSavePath(String fileName) async {
    await Permission.storage.request();
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }

    final customDir = Directory('/storage/emulated/0/Download/EasySave');
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }
    return '${customDir.path}/$fileName';
  }

  // بدء التنزيل مع استخدام ResumableDownloader
  void _startDownload(String url, String fileName) async {
    final savePath = await _getSavePath(fileName);

    if (File(savePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الملف موجود بالفعل: $fileName')),
      );
      return;
    }

    final dl = ResumableDownloader();
    _downloaders[fileName] = dl;
    _isDownloading[fileName] = true;
    _progress[fileName] = 0.0;

    try {
      await dl.download(
        url,
        savePath,
        onProgress: (received, total) {
          setState(() {
            _progress[fileName] = received / total;
          });
        },
      );
      setState(() => _isDownloading[fileName] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتهى تنزيل $fileName')),
      );
    } catch (e) {
      setState(() => _isDownloading[fileName] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التنزيل: $fileName')),
      );
    }
  }

  void _pauseDownload(String fileName) {
    _downloaders[fileName]?.pause();
    setState(() => _isDownloading[fileName] = false);
  }

  void _resumeDownload(String url, String fileName) async {
    final savePath = await _getSavePath(fileName);
    setState(() => _isDownloading[fileName] = true);
    _downloaders[fileName]?.download(
      url,
      savePath,
      onProgress: (received, total) {
        setState(() {
          _progress[fileName] = received / total;
        });
      },
    );
  }

  // الدالة لحساب حجم الملف (إن كانت بيانات الحجم موجودة داخل stream)
  String _calculateFileSize(StreamInfo stream) {
    try {
      // نفترض أن الخاصية available وتحتوي على إجمالي البايتات
      if (stream.size != null) {
        final bytes = stream.size.totalBytes;
        final mb = bytes / (1024 * 1024);
        return '${mb.toStringAsFixed(2)} MB';
      }
    } catch (_) {}
    return "N/A";
  }

  // بطاقة التحميل مع تصميم أنيق تعرض صورة الفيديو ومعلومات إضافية
  Widget _buildDownloadTile(String url, String fileName, StreamInfo stream) {
    final prog = _progress[fileName] ?? 0.0;
    final downloading = _isDownloading[fileName] ?? false;
    final resolution = (stream is VideoStreamInfo) ? stream.qualityLabel : 'Audio';
    final fileSize = _calculateFileSize(stream);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        contentPadding: EdgeInsets.all(8),
        // عرض صورة الفيديو بدلاً من أي شعار ثابت
        leading: thumbnailUrl != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(thumbnailUrl!, width: 60, height: 60, fit: BoxFit.cover),
        )
            : Icon(Icons.video_library, size: 60),
        title: Text(
          fileName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('دقة: $resolution  • الحجم: $fileSize'),
            SizedBox(height: 6),
            LinearProgressIndicator(value: prog),
            SizedBox(height: 4),
            Text('${(prog * 100).toStringAsFixed(1)}٪'),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (!downloading)
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () => _startDownload(url, fileName),
              ),
            if (downloading)
              IconButton(
                icon: Icon(Icons.pause),
                onPressed: () => _pauseDownload(fileName),
              ),
            if (!downloading && prog > 0 && prog < 1)
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => _resumeDownload(url, fileName),
              ),
            if (prog == 1)
              IconButton(
                icon: Icon(Icons.open_in_new),
                onPressed: () async {
                  final path = await _getSavePath(fileName);
                  OpenFile.open(path);
                },
              ),
          ],
        ),
      ),
    );
  }

  // تصميم بانر خاص يظهر صورة الفيديو مع نص "Discount 50%\nlearn more..."
  Widget _buildPromoBanner() {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        image: thumbnailUrl != null
            ? DecorationImage(
          image: NetworkImage(thumbnailUrl!),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        )
            : null,
      ),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.all(20),
      child: Text(
        "Discount 50%\nlearn more...",
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Pacifico',
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('YouTube Downloader Pro 🎗️')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // حقل الإدخال لجلب رابط الفيديو
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'الصق رابط YouTube',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: fetchVideoInfo,
              child: Text('جلب معلومات الفيديو'),
            ),
            if (isLoading) ...[
              SizedBox(height: 20),
              Center(child: CircularProgressIndicator()),
            ],
            if (title != null) ...[
              SizedBox(height: 20),
              // عرض البانر الترويجي بصورة الفيديو مع النص الثابت
              _buildPromoBanner(),
              SizedBox(height: 10),
              Text(
                title!,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
            SizedBox(height: 16),
            // عرض خيارات التحميل للـ muxed streams
            if (muxedStreams != null)
              ...muxedStreams!.map((s) {
                final fileName = '${sanitizeFileName(title!)}_${s.qualityLabel}.mp4';
                return _buildDownloadTile(s.url.toString(), fileName, s);
              }),
            // عرض خيارات التحميل للفيديوهات فقط
            if (videoStreams != null)
              ...videoStreams!.map((s) {
                final fileName = '${sanitizeFileName(title!)}_${s.qualityLabel}.mp4';
                return _buildDownloadTile(s.url.toString(), fileName, s);
              }),
            // عرض خيار التحميل للصوت فقط
            if (audioStream != null)
              _buildDownloadTile(
                audioStream!.url.toString(),
                '${sanitizeFileName(title!)}_audio.mp3',
                audioStream!,
              ),
          ],
        ),
      ),
    );
  }
}
/*import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Downloader with resume support
class ResumableDownloader {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;
  int _downloadedBytes = 0;
  Function(int, int)? _onProgress;
  String? _currentUrl;
  String? _currentPath;

  /// Start or resume download
  Future<void> download(
      String url,
      String savePath, {
        required void Function(int received, int total) onProgress,
      }) async {
    _currentUrl = url;
    _currentPath = savePath;
    _onProgress = onProgress;
    _downloadedBytes = await _getExistingSize(savePath);
    _cancelToken = CancelToken();

    // Ensure directory exists
    final file = File(savePath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    // Get total file size
    final totalSize = await _getTotalSize(url);

    try {
      await _dio.download(
        url,
        savePath,
        options: Options(
          headers: {HttpHeaders.rangeHeader: 'bytes=$_downloadedBytes-'},
        ),
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          final downloaded = _downloadedBytes + received;
          final full = totalSize > 0 ? totalSize : _downloadedBytes + total;
          _onProgress?.call(downloaded, full);
        },
      );
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e)) {
        rethrow;
      }
    }
  }

  Future<int> _getExistingSize(String path) async {
    final file = File(path);
    return file.existsSync() ? await file.length() : 0;
  }

  Future<int> _getTotalSize(String url) async {
    try {
      final response = await _dio.head(url);
      return int.parse(
        response.headers.value(HttpHeaders.contentLengthHeader) ?? '0',
      );
    } catch (_) {
      return 0;
    }
  }

  void pause() {
    _cancelToken?.cancel();
  }
}

/// Widget for downloading YouTube videos and audio without conversion
class VideoDownloaderPlas extends StatefulWidget {
  @override
  _VideoDownloaderPlasState createState() => _VideoDownloaderPlasState();
}

class _VideoDownloaderPlasState extends State<VideoDownloaderPlas> {
  final _urlCtrl = TextEditingController();
  bool _loading = false;

  String? _title;
  String? _thumbUrl;
  List<MuxedStreamInfo>? _muxed;
  List<VideoStreamInfo>? _videos;
  AudioOnlyStreamInfo? _audio;

  final Map<String, ResumableDownloader> _downloaders = {};
  final Map<String, double> _progress = {};
  final Map<String, bool> _isDownloading = {};

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  String sanitize(String name) => name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  /// Fetch video + audio info, filter for highest bitrate M4A
  Future<void> fetchVideoInfo() async {
    final url = _urlCtrl.text.trim();
    if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء إدخال رابط YouTube صالح')),
      );
      return;
    }
    setState(() => _loading = true);
    final yt = YoutubeExplode();
    try {
      final video = await yt.videos.get(url);
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      // muxed (video+audio)
      _muxed = manifest.muxed.toList();
      // video-only streams
      _videos = manifest.video.toList();
      // audio-only: pick highest bitrate M4A
      final audios = manifest.audioOnly
          .where((s) => s.container.name.toLowerCase() == 'm4a')
          .toList();
      if (audios.isNotEmpty) {
        audios.sort((a, b) => b.bitrate.compareTo(a.bitrate));
        _audio = audios.first;
      }
      setState(() {
        _title = video.title;
        _thumbUrl = video.thumbnails.highResUrl;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء جلب معلومات الفيديو')),
      );
    } finally {
      yt.close();
      setState(() => _loading = false);
    }
  }

  Future<String> _getSavePath(String fileName) async {
    await Permission.storage.request();
    if (Platform.isAndroid &&
        await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    final dir = Directory('/storage/emulated/0/Download/EasySave');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return '${dir.path}/$fileName';
  }

  void _startDownload(String url, String fileName) async {
    final path = await _getSavePath(fileName);
    if (File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الملف موجود بالفعل: $fileName')),
      );
      return;
    }
    final downloader = ResumableDownloader();
    _downloaders[fileName] = downloader;
    _isDownloading[fileName] = true;
    _progress[fileName] = 0.0;
    try {
      await downloader.download(
        url,
        path,
        onProgress: (received, total) {
          setState(() {
            _progress[fileName] = received / total;
          });
        },
      );
      setState(() => _isDownloading[fileName] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('انتهى تنزيل $fileName')),
      );
    } catch (_) {
      setState(() => _isDownloading[fileName] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التنزيل: $fileName')),
      );
    }
  }

  Widget _buildDownloadTile(String url, String fileName, StreamInfo stream) {
    final prog = _progress[fileName] ?? 0.0;
    final downloading = _isDownloading[fileName] ?? false;
    final size = stream.size != null
        ? '${(stream.size!.totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB'
        : 'N/A';
    final label = stream is VideoStreamInfo ? stream.qualityLabel : 'Muxed';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: ListTile(
        contentPadding: EdgeInsets.all(8),
        leading: _thumbUrl != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
          Image.network(_thumbUrl!, width: 60, height: 60, fit: BoxFit.cover),
        )
            : Icon(Icons.video_library, size: 60),
        title: Text(
          fileName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label • $size'),
            SizedBox(height: 6),
            LinearProgressIndicator(value: prog),
            SizedBox(height: 4),
            Text('${(prog * 100).toStringAsFixed(1)}٪'),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (!downloading)
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () => _startDownload(url, fileName),
              ),
            if (downloading)
              IconButton(
                icon: Icon(Icons.pause),
                onPressed: () {
                  _downloaders[fileName]?.pause();
                  setState(() => _isDownloading[fileName] = false);
                },
              ),
            if (!downloading && prog > 0 && prog < 1)
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => _startDownload(url, fileName),
              ),
            if (prog == 1)
              IconButton(
                icon: Icon(Icons.open_in_new),
                onPressed: () async {
                  final p = await _getSavePath(fileName);
                  OpenFile.open(p);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Tile for audio-only download
  Widget _buildAudioTile(String url, String title, AudioOnlyStreamInfo s) {
    final ext = s.container.name.toLowerCase();
    final fileName = '${sanitize(title)}_${s.bitrate.kiloBitsPerSecond}kbps.$ext';
    return _buildDownloadTile(url, fileName, s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('YouTube Downloader Pro 🎗️')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                labelText: 'الصق رابط YouTube',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: fetchVideoInfo,
              child: Text('جلب معلومات الفيديو'),
            ),
            if (_loading) ...[
              SizedBox(height: 20),
              Center(child: CircularProgressIndicator()),
            ],
            if (_title != null) ...[
              SizedBox(height: 20),
              if (_thumbUrl != null)
                Image.network(_thumbUrl!, height: 180, fit: BoxFit.cover),
              SizedBox(height: 10),
              Text(
                _title!,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
            ],
            if (_muxed != null)
              for (var m in _muxed!)
                _buildDownloadTile(
                  m.url.toString(),
                  '${sanitize(_title!)}_${m.qualityLabel}.mp4',
                  m,
                ),
            if (_videos != null)
              for (var v in _videos!)
                _buildDownloadTile(
                  v.url.toString(),
                  '${sanitize(_title!)}_${v.qualityLabel}.mp4',
                  v,
                ),
            if (_audio != null)
              _buildAudioTile(
                _audio!.url.toString(),
                _title!,
                _audio!,
              ),
          ],
        ),
      ),
    );
  }
}
*/