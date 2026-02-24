import 'package:easysave3/services/download_controller.dart';
import 'package:flutter/material.dart';
import '../services/active_download_manager.dart';

class ActiveDownloadsPage extends StatefulWidget {
  @override
  _ActiveDownloadsPageState createState() => _ActiveDownloadsPageState();
}

class _ActiveDownloadsPageState extends State<ActiveDownloadsPage> {
  @override
  void initState() {
    super.initState();
    ActiveDownloadManager().addListener(_update);
  }

  @override
  void dispose() {
    ActiveDownloadManager().removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final downloads = ActiveDownloadManager().downloads;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,

        title: Text('التحميلات الجارية'),
        actions: [
          if (downloads.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_forever),
              onPressed: _clearCompletedDownloads,
              tooltip: 'حذف المكتملة',
            ),
        ],
      ),
      body: downloads.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        itemCount: downloads.length,
        itemBuilder: (context, index) => _buildDownloadItem(downloads[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('لا توجد تحميلات حالية',
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(ActiveDownloadInfo download) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _buildFileIcon(download),
        title: Text(
          download.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            LinearProgressIndicator(value: download.progress),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(download.progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12),
                ),
                if (download.lastUpdated != null)
                  Text(
                    'آخر تحديث: ${_formatTime(download.lastUpdated!)}',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(download.isDownloading ? Icons.pause : Icons.play_arrow,
                  color: _getActionColor(download)),
              onPressed: () {
                if (download.isDownloading) {
                  DownloadController().pause(download.fileName);
                } else {
                  DownloadController().resume(download.fileName);
                }
                ActiveDownloadManager().toggleDownload(download.fileName);
              },
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red[300]),
              onPressed: () => ActiveDownloadManager().removeDownload(download.fileName),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getActionColor(ActiveDownloadInfo download) {
    if (download.progress >= 1.0) return Colors.teal.withOpacity(0.9);
    return download.isDownloading ? Colors.blue : Colors.orange;
  }

  Widget _buildFileIcon(ActiveDownloadInfo download) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getActionColor(download).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        download.progress >= 1.0 ? Icons.check_circle : Icons.file_download,
        color: _getActionColor(download),
      ),
    );
  }

  void _clearCompletedDownloads() {
    final manager = ActiveDownloadManager();
    manager.downloads
        .where((d) => d.progress >= 1.0)
        .toList()
        .forEach((d) => manager.removeDownload(d.fileName));
  }

}