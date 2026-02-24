import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadedFilesPage extends StatefulWidget {
  @override
  _DownloadedFilesPageState createState() => _DownloadedFilesPageState();
}

class _DownloadedFilesPageState extends State<DownloadedFilesPage> {
  List<FileSystemEntity> files = [];
  bool isListView = true; // حالة طريقة العرض
  final String downloadDirectory = '/storage/emulated/0/Download/EasySave';

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

  Future<void> _loadDownloadedFiles() async {
    await Permission.storage.request();
    final dir = Directory(downloadDirectory);
    if (await dir.exists()) {
      final list = await dir.list().toList();
      list.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified)); // ترتيب تنازلي حسب التاريخ
      setState(() => files = list.whereType<File>().toList());
    }
  }

  // دالة إنشاء عنصر الشبكة
  Widget _buildFileGridItem(File file) {
    final fileName = file.uri.pathSegments.last;
    final fileSize = _getFileSize(file);
    final modified = file.lastModifiedSync();
    final isVideo = fileName.toLowerCase().endsWith('.mp4');
    final isAudio = fileName.toLowerCase().endsWith('.mp3');

    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getFileColor(fileName),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isVideo ? Icons.videocam :
              isAudio ? Icons.audiotrack : Icons.insert_drive_file,
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              fileName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey[800],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${_formatDate(modified)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove_red_eye, size: 20),
                color: Colors.blue,
                onPressed: () => OpenFile.open(file.path),
              ),
              IconButton(
                icon: Icon(Icons.share, size: 20),
                color: Colors.green,
                onPressed: () => Share.shareXFiles([XFile(file.path)]),
              ),
            ],
          ),
        ],
      ),
    );
  }


  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes > 1073741824) {
        return '${(bytes / 1073741824).toStringAsFixed(1)} جيجابايت';
      }
      return '${(bytes / 1048576).toStringAsFixed(1)} ميجابايت';
    } catch (e) {
      return 'غير معروف';
    }
  }

  Widget _buildFileTile(File file) {
    final fileName = file.uri.pathSegments.last;
    final fileSize = _getFileSize(file);
    final modified = file.lastModifiedSync();
    final isVideo = fileName.toLowerCase().endsWith('.mp4');
    final isAudio = fileName.toLowerCase().endsWith('.mp3');

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getFileColor(fileName),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isVideo ? Icons.videocam :
            isAudio ? Icons.audiotrack : Icons.insert_drive_file,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Text(
          fileName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.grey[800],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'الحجم: $fileSize',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'آخر تعديل: ${_formatDate(modified)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.remove_red_eye,
              color: Colors.blue,
              onPressed: () => OpenFile.open(file.path),
              tooltip: 'معاينة',
            ),
            SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.share,
              color: Colors.green,
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
              tooltip: 'مشاركة',
            ),
          ],
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Color _getFileColor(String fileName) {
    if (fileName.toLowerCase().endsWith('.mp4')) return Colors.redAccent;
    if (fileName.toLowerCase().endsWith('.mp3')) return Colors.purpleAccent;
    return Colors.blueGrey;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('الملفات المحملة'),
        actions: [
          IconButton(
            icon: Icon(isListView ? Icons.grid_view : Icons.list),
            onPressed: () => setState(() => isListView = !isListView),
            tooltip: 'تغيير طريقة العرض',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDownloadedFiles,
          ),
        ],
      ),
      body: files.isEmpty
          ? Center(child: Text('لا توجد ملفات محملة'))
          : RefreshIndicator(
        onRefresh: _loadDownloadedFiles,
        child: isListView
            ? ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) => _buildFileTile(files[index] as File),
        )
            : GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
          ),
          itemCount: files.length,
          itemBuilder: (context, index) => _buildFileGridItem(files[index] as File),
        ),
      ),
    );
  }
}