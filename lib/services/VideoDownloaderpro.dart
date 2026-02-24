import 'dart:io';
import 'package:easysave3/services/download_controller.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/ActiveDownloadsPage.dart';
import '../screens/DownloadedFilesPage.dart';
import '../services/resumable_downloader.dart';
import 'active_download_manager.dart';
import 'package:marquee/marquee.dart';
import 'package:path/path.dart' as p;

class VideoDownloaderPro extends StatefulWidget {
  @override
  _VideoDownloaderPro createState() => _VideoDownloaderPro();
}

class _VideoDownloaderPro extends State<VideoDownloaderPro> {
  final _urlController = TextEditingController();
  bool isLoading = false;

  String? title;
  String? thumbnailUrl;
  List<MuxedStreamInfo>? muxedStreams;
  List<VideoStreamInfo>? videoStreams;
  AudioStreamInfo? audioStream;

  // لإدارة التنزيل مع دعم الاستئناف
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

  /// دالة جلب معلومات الفيديو من YouTube
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

  void _showFancyNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.blueGrey[800],
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            gradient: LinearGradient(

              colors: [Colors.teal[700]!, Colors.teal[700]!],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.downloading_rounded, color: Colors.white),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          left: 20,
          right: 20,
        ),
        duration: Duration(seconds: 3),
        elevation: 10,
        backgroundColor: Colors.transparent,
      ),
    );
  }


  /// بدء التنزيل باستخدام ResumableDownloader
  /// بدء التنزيل باستخدام ResumableDownloader مع مفتاح ثابت وامتداد صحيح
  void _startDownload(String url, String baseFileName, String uniqueKey) async {
    // افصل الاسم عن الامتداد
    final ext = baseFileName.contains('.')
        ? baseFileName.substring(baseFileName.lastIndexOf('.'))
        : '';
    final nameOnly = baseFileName.replaceAll(ext, '');

    // اجمع الاسم الموحد
    final uniqueFileName = '${nameOnly}_$uniqueKey$ext';

    _showFancyNotification('جاري إعداد التنزيل...');
    final savePath = await _getUniqueFilePath(uniqueFileName);

    final dl = ResumableDownloader();
    DownloadController().add(uniqueFileName, dl);
    _downloaders[uniqueFileName] = dl;
    _isDownloading[uniqueFileName] = true;
    _progress[uniqueFileName] = 0.0;

    ActiveDownloadManager().addDownload(uniqueFileName);

    try {
      await dl.download(
        url,
        savePath,
        onProgress: (received, total) {
          final p = received / total;
          setState(() => _progress[uniqueFileName] = p);
          ActiveDownloadManager().updateProgress(uniqueFileName, p);
        },
      );
      setState(() => _isDownloading[uniqueFileName] = false);
      ActiveDownloadManager().setDownloading(uniqueFileName, false);
      _showFancyNotification('انتهى تنزيل $baseFileName');
    } catch (e) {
      setState(() => _isDownloading[uniqueFileName] = false);
      ActiveDownloadManager().setDownloading(uniqueFileName, false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التنزيل: $baseFileName')),
      );
    }
  }




  Future<String> _getUniqueFilePath(String fileName) async {
    await Permission.storage.request();
    final customDir = Directory('/storage/emulated/0/Download/EasySave');
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }
    final ext = p.extension(fileName);
    final nameOnly = p.basenameWithoutExtension(fileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueName = '${nameOnly}_$timestamp$ext';
    return p.join(customDir.path, uniqueName);
  }

  /// حساب حجم الملف من بيانات الـ stream إن وجدت
  String _calculateFileSize(StreamInfo stream) {
    try {
      if (stream.size != null) {
        final bytes = stream.size.totalBytes;
        final mb = bytes / (1024 * 1024);
        return '${mb.toStringAsFixed(2)} MB';
      }
    } catch (_) {}
    return "N/A";
  }

  /// بطاقة التحميل تعرض صورة الفيديو، معلومات الدقة والحجم، وأزرار التنزيل والإيقاف والمعاينة والمشاركة
  Widget _buildDownloadTile(String url, String fileName, StreamInfo stream) {
    final uniqueKey = DateTime.now().millisecondsSinceEpoch.toString(); // مفتاح فريد
    final downloading = _isDownloading[uniqueKey] ?? false;
    final resolution = (stream is VideoStreamInfo) ? stream.qualityLabel : 'Audio';
    final fileSize = _calculateFileSize(stream);

    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        contentPadding: EdgeInsets.all(8),
        leading: thumbnailUrl != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            thumbnailUrl!,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        )
            : Icon(Icons.video_library, size: 60),
        title: Container(
          height: 24,
          child: Marquee(
            text: fileName,
            style: TextStyle(
              color:Colors.teal.withOpacity(0.9),

              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo-SemiBold',
            ),
            scrollAxis: Axis.horizontal,
            blankSpace: 40.0,
            velocity: 40.0,
            pauseAfterRound: Duration(seconds: 1),
            textDirection: TextDirection.rtl,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('  $resolution -  دقة '),
            SizedBox(height: 5),
            Text('  $fileSize -   الحجم  '),
            SizedBox(height: 6),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (!downloading)
              IconButton(
                icon: Icon(Icons.file_download),
                color:Colors.red.withOpacity(0.9),

                onPressed: () => _startDownload(url, fileName, uniqueKey),
                tooltip: 'تنزيل الملف',
              ),
          ],
        ),
      ),
    );
  }

  /// بانر ترويجي بخلفية صورة الفيديو مع نص مميز
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
        "Enhanced Tasks\nExplore more features",
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Pacifico',
          fontSize: 16,
        ),
      ),
    );
  }

  /// تصميم top bar مشابه لـ HomeScreen مع إعدادات وإعدادات الإعلانات إن وُجدت
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Enhanced ",
          style: TextStyle(
            color:Colors.teal.withOpacity(0.9),
            fontFamily: 'PoetsenOne',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(Icons.cloud_download),
          color:Colors.teal.withOpacity(0.9),

          tooltip: 'التحميلات الجارية',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ActiveDownloadsPage()),
            );
          },
        ),

        IconButton(
          icon: Icon(Icons.download_rounded),
          color:Colors.teal.withOpacity(0.9),

          tooltip: 'صفحة التحميلات',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DownloadedFilesPage()),
            );
          },
        ),

      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(245, 249, 250, 1),
      appBar: AppBar(

        backgroundColor: Color(0xFFF5F5F5),
        elevation: 1,
        title: _buildTopBar(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 22),

              // حقل الإدخال لجلب رابط الفيديو
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 600), // تحديد أقصى عرض لل responsiveness
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: TextField(
                            controller: _urlController,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              labelText: 'أدخل رابط YouTube',
                              labelStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontFamily: 'Cairo-SemiBold',
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.blueGrey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.blueGrey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color:Colors.teal.withOpacity(0.9), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              suffixIcon: Icon(Icons.link, color: Colors.blueGrey),
                              hintTextDirection: TextDirection.rtl,
                            ),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),

                        const SizedBox(width: 15),

                        ElevatedButton.icon(
                          label: Text(
                            'تحميل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.withOpacity(0.9),
                            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 3,
                            shadowColor: Colors.blue.withOpacity(0.3),
                          ),
                          onPressed: fetchVideoInfo,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              if (isLoading)
                Center(child: CircularProgressIndicator()),
              if (title != null) ...[
                _buildPromoBanner(),
                SizedBox(height: 12),
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: 16),
              // عرض بطاقات التحميل الخاصة بمصادر الفيديو المختلفة
              if (muxedStreams != null)
                ...muxedStreams!.map((s) {
                  final fileName = '${sanitizeFileName(title!)}_${s.qualityLabel}.mp4';
                  return _buildDownloadTile(s.url.toString(), fileName, s);
                }),
              if (videoStreams != null)
                ...videoStreams!.map((s) {
                  final fileName = '${sanitizeFileName(title!)}_${s.qualityLabel}.mp4';
                  return _buildDownloadTile(s.url.toString(), fileName, s);
                }),
              if (audioStream != null)
                _buildDownloadTile(
                  audioStream!.url.toString(),
                  '${sanitizeFileName(title!)}_audio.mp3',
                  audioStream!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
