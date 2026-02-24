import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:html/dom.dart' as parser;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class InstagramDownloader extends StatefulWidget {
  const InstagramDownloader({Key? key}) : super(key: key);

  @override
  _InstagramDownloaderState createState() => _InstagramDownloaderState();
}

class _InstagramDownloaderState extends State<InstagramDownloader> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _currentTaskId;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      _showError('⚠️ يرجى منح إذن التخزين');
    }
  }

  Future<String?> _extractVideoUrl(String html) async {
    try {
      final doc = parser.parse(html);
      final scripts = doc.getElementsByTagName('script');

      // البحث في window._sharedData
      final sharedDataScript = scripts.cast<parser.Element?>().firstWhere(
            (e) => e?.innerHtml?.contains('window._sharedData') ?? false,
        orElse: () => null,
      );

      if (sharedDataScript != null) {
        final jsonStr = sharedDataScript.innerHtml!
            .replaceFirst('window._sharedData = ', '')
            .replaceAll(';', '');

        try {
          final data = json.decode(jsonStr) as Map<String, dynamic>;
          return data['entry_data']?['PostPage']?[0]?['graphql']
          ?['shortcode_media']?['video_url'] as String?;
        } catch (e) {
          print('JSON parsing error: $e');
        }
      }

      // البحث باستخدام التعابير المنطقية
      final regex = RegExp(r'"video_url":"(.*?)"');
      final match = regex.firstMatch(html);

      return match?.group(1)?.replaceAll(r'\u0026', '&');
    } catch (e) {
      print('Error parsing HTML: $e');
      return null;
    }
  }

  Future<void> _downloadReel(String url) async {
    if (!url.contains('instagram.com')) {
      _showError('❌ الرابط غير صحيح');
      return;
    }

    if (_loading) return;

    setState(() => _loading = true);
    final client = http.Client();

    try {
      // 1. جلب محتوى الصفحة
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/91.0.4472.124 Safari/537.36',
          'Accept-Language': 'ar,en-US;q=0.9',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw 'فشل الاتصال (${response.statusCode})';
      }

      // 2. استخراج رابط الفيديو
      final videoUrl = await _extractVideoUrl(response.body);
      if (videoUrl == null || videoUrl.isEmpty) {
        throw 'لم يتم العثور على فيديو في الرابط';
      }

      // 3. التحضير لحفظ الملف
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/Instagram_Reels';
      await Directory(savePath).create(recursive: true);

      // 4. بدء التحميل
      _currentTaskId = await FlutterDownloader.enqueue(
        url: videoUrl,
        savedDir: savePath,
        fileName: 'reel_${DateTime.now().millisecondsSinceEpoch}.mp4',
        showNotification: true,
        openFileFromNotification: true,
        requiresStorageNotLow: true,
        headers: {'Referer': url},
      );

      if (_currentTaskId == null) throw 'فشل في بدء التحميل';

      _showSuccess('✅ جاري التحميل...');

    } on SocketException {
      _showError('❌ لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      _showError('⏱ تجاوز الوقت المحدد');
    } on http.ClientException catch (e) {
      _showError('🌐 خطأ الشبكة: ${e.message}');
    } catch (e) {
      _showError('⚠️ خطأ غير متوقع: ${e.toString()}');
    } finally {
      client.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ));
      }
      }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحميل ريلز إنستجرام'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'أدخل رابط الريلز',
                hintText: 'مثال: https://www.instagram.com/reel/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: _loading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.download),
              label: Text(_loading ? 'جاري التحميل...' : 'بدء التحميل'),
              onPressed: _loading ? null : () => _downloadReel(_controller.text),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}