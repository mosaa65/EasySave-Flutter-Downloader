import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;


class SnapchatDownloader extends StatefulWidget {
  @override
  _SnapchatDownloaderState createState() => _SnapchatDownloaderState();
}

class _SnapchatDownloaderState extends State<SnapchatDownloader> {
  final _controller = TextEditingController();

  Future<void> downloadSnap(String url) async {
    if (!url.contains("https://story.snapchat.com")) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("رابط غير مدعوم")));
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      final document = parser.parse(response.body);
      final videoUrl = RegExp('"video":{"url":"(.*?)"')
          .firstMatch(document.outerHtml)
          ?.group(1)
          ?.replaceAll(r'&', '&');
      if (videoUrl != null) {
        await downloadFile(videoUrl, "snap_video.mp4");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("لم يتم العثور على الفيديو")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل التحميل")));
    }
  }

  Future<void> downloadFile(String url, String fileName) async {
    final directory = Directory('/storage/emulated/0/Download/EasySave');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    await FlutterDownloader.enqueue(
      url: url,
      savedDir: directory.path,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true,
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم بدء التحميل")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Snapchat Downloader")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: "رابط Snapchat", border: OutlineInputBorder()),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => downloadSnap(_controller.text.trim()),
            child: Text("تحميل الفيديو"),
          ),
        ]),
      ),
    );
  }
}