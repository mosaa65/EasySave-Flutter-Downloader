import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoDownloader extends StatefulWidget {
  @override
  _VideoDownloaderState createState() => _VideoDownloaderState();
}

class _VideoDownloaderState extends State<VideoDownloader> {
  final _urlController = TextEditingController();
  bool isLoading = false;
  String? downloadedFilePath;

  // بيانات الفيديو
  String? title;
  String? thumbnailUrl;
  List<MuxedStreamInfo>? muxedStreams;
  List<VideoStreamInfo>? videoStreams;
  AudioStreamInfo? audioStream;

  // خريطة لتخزين taskId لكل ملف (باستخدام اسم الملف كمفتاح)
  Map<String, String> taskIds = {};

  /// دالة لجلب معلومات الفيديو من YouTube
  Future<void> fetchVideoInfo() async {
    final url = _urlController.text.trim();

    if (!url.contains("youtube.com") && !url.contains("youtu.be")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("الرجاء إدخال رابط YouTube صالح")),
      );
      return;
    }

    setState(() => isLoading = true);
    final yt = YoutubeExplode();

    try {
      var video = await yt.videos.get(url);
      var manifest = await yt.videos.streamsClient.getManifest(video.id);
      setState(() {
        title = video.title;
        thumbnailUrl = video.thumbnails.highResUrl;
        // استخدام القنوات المدمجة إن وجدت، وإلا نستخدم فيديو فقط مع الصوت
        if (manifest.muxed.isNotEmpty) {
          muxedStreams = manifest.muxed.toList();
          videoStreams = null;
          audioStream = null;
        } else {
          muxedStreams = null;
          videoStreams = manifest.video.toList();
          audioStream = manifest.audioOnly.withHighestBitrate();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء جلب الفيديو")),
      );
    } finally {
      yt.close();
      setState(() => isLoading = false);
    }
  }

  /// دالة التنزيل بعد تعديلها لتخزين taskId
  Future<void> downloadFile(String url, String fileName) async {
    final directory = Directory('/storage/emulated/0/Download/EasySave');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: directory.path,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true,
    );

    if (taskId != null) {
      taskIds[fileName] = taskId;
      setState(() {
        downloadedFilePath = '${directory.path}/$fileName';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تم بدء التنزيل")),
      );
    }
  }

  /// دالة فتح الملف المحمّل
  void openDownloadedFile() {
    if (downloadedFilePath != null) {
      OpenFile.open(downloadedFilePath);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeTitle = title ?? "";
    return Scaffold(
      appBar: AppBar(
        title: Text("YouTube Downloader"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // حقل إدخال رابط الفيديو
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: "الصق رابط YouTube",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: fetchVideoInfo,
              child: Text("جلب معلومات الفيديو"),
            ),
            if (isLoading) ...[
              SizedBox(height: 20),
              Center(child: CircularProgressIndicator()),
            ],
            if (title != null) ...[
              SizedBox(height: 20),
              if (thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(thumbnailUrl!),
                ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      safeTitle,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: safeTitle));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("تم نسخ العنوان")),
                      );
                    },
                  ),
                ],
              ),
            ],
            // قسم تحميل فيديو+صوت إن وُجدت القنوات المدمجة
            if (muxedStreams != null && title != null) ...[
              SizedBox(height: 20),
              Text("تحميل فيديو + صوت:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...muxedStreams!.map((s) => Card(
                margin: EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.movie),
                  title: Text("الجودة: ${s.qualityLabel}"),
                  subtitle: Text("${s.size.totalMegaBytes.toStringAsFixed(2)} MB"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => downloadFile(
                            s.url.toString(), "${safeTitle}_${s.qualityLabel}.mp4"),
                        child: Text("تحميل"),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.pause),
                        onPressed: () {
                          final id = taskIds["${safeTitle}_${s.qualityLabel}.mp4"];
                          if (id != null) FlutterDownloader.pause(taskId: id);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.play_arrow),
                        onPressed: () {
                          final id = taskIds["${safeTitle}_${s.qualityLabel}.mp4"];
                          if (id != null) FlutterDownloader.resume(taskId: id);
                        },
                      ),
                    ],
                  ),
                ),
              )),
            ],
            // قسم تحميل فيديو فقط
            if (videoStreams != null && videoStreams!.isNotEmpty && title != null) ...[
              SizedBox(height: 20),
              Text("تحميل فيديو فقط:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...videoStreams!.map((s) => Card(
                margin: EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.video_library),
                  title: Text("الجودة: ${s.qualityLabel}"),
                  subtitle: Text("${s.size.totalMegaBytes.toStringAsFixed(2)} MB"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => downloadFile(
                            s.url.toString(), "${safeTitle}_${s.qualityLabel}.mp4"),
                        child: Text("تحميل"),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.pause),
                        onPressed: () {
                          final id =
                          taskIds["${safeTitle}_${s.qualityLabel}.mp4"];
                          if (id != null) FlutterDownloader.pause(taskId: id);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.play_arrow),
                        onPressed: () {
                          final id =
                          taskIds["${safeTitle}_${s.qualityLabel}.mp4"];
                          if (id != null) FlutterDownloader.resume(taskId: id);
                        },
                      ),
                    ],
                  ),
                ),
              )),
            ],
            // قسم تحميل الصوت فقط
            if (audioStream != null && title != null) ...[
              SizedBox(height: 20),
              Text("تحميل صوت فقط:", style: TextStyle(fontWeight: FontWeight.bold)),
              Card(
                child: ListTile(
                  leading: Icon(Icons.music_note),
                  title: Text(
                      "معدل البت: ${audioStream!.bitrate.kiloBitsPerSecond} kbps"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => downloadFile(audioStream!.url.toString(),
                            "${safeTitle}_audio.mp3"),
                        child: Text("تحميل MP3"),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.pause),
                        onPressed: () {
                          final id = taskIds["${safeTitle}_audio.mp3"];
                          if (id != null) FlutterDownloader.pause(taskId: id);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.play_arrow),
                        onPressed: () {
                          final id = taskIds["${safeTitle}_audio.mp3"];
                          if (id != null) FlutterDownloader.resume(taskId: id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // زر فتح الملف المُحمّل (إن وجد)
            if (downloadedFilePath != null) ...[
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: openDownloadedFile,
                child: Text("فتح الملف المحمّل"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
