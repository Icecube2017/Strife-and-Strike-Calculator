import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
// import 'package:sns_calculator/logger.dart';

class LoggerPage extends StatefulWidget {
  const LoggerPage({super.key});

  @override
  State<LoggerPage> createState() => _LoggerPageState();
}

class _LoggerPageState extends State<LoggerPage> {
  late Future<List<FileInfo>> _logFiles;

  @override
  void initState() {
    super.initState();
    _logFiles = _getLogFiles();
  }

  /// 获取 log 文件夹中的所有日志文件
  Future<List<FileInfo>> _getLogFiles() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${documentsDir.path}/log');

      if (!await logDir.exists()) {
        return [];
      }

      final files = await logDir.list().toList();
      final logFileInfos = <FileInfo>[];

      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.json')) {
          final stat = await entity.stat();
          logFileInfos.add(FileInfo(
            file: entity,
            name: entity.path.split('/').last,
            size: stat.size,
            modified: stat.modified,
          ));
        }
      }

      // 按修改时间倒序排列（最新的在前）
      logFileInfos.sort((a, b) => b.modified.compareTo(a.modified));
      return logFileInfos;
    } catch (e) {
      Logger().e('Error getting log files: $e');
      return [];
    }
  }

  /// 查看日志文件内容
  Future<void> _viewLogFile(FileInfo fileInfo) async {
    try {
      final content = await fileInfo.file.readAsString();
      final jsonList = jsonDecode(content) as List<dynamic>;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                // 标题栏
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    ),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fileInfo.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: '关闭',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // 日志内容区域
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: jsonList.length,
                    itemBuilder: (context, index) {
                      final item = jsonList[index];
                      final category = item['category'] ?? '游戏';
                      final message = item['message'] ?? '';
                      final timestamp = item['timestamp'] ?? '';

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: _getLogColor(category),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          '[$timestamp] [$category] $message',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontFamily: 'monospace',
                          ),
                          softWrap: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('读取日志文件失败: $e')),
      );
    }
  }

  /// 删除日志文件
  Future<void> _deleteLogFile(FileInfo fileInfo) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日志'),
        content: Text('确定要删除 ${fileInfo.name} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await fileInfo.file.delete();
                setState(() {
                  _logFiles = _getLogFiles();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已删除 ${fileInfo.name}')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除失败: $e')),
                );
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String category) {
    switch (category) {
      case '玩家':
        return Colors.blue[800]!;
      case '行动':
        return Colors.orange[800]!;
      case '技能':
        return Colors.purple[800]!;
      case '特质':
        return Colors.green[800]!;
      case '伤害':
        return Colors.red[800]!;
      case '治疗':
        return Colors.pinkAccent[200]!;
      case '状态':
        return Colors.yellow[800]!;
      case '属性':
        return Colors.blue[400]!;
      case '统计':
        return Colors.cyan[800]!;
      default:
        return Colors.grey[700]!;
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志管理'),
      ),
      body: FutureBuilder<List<FileInfo>>(
        future: _logFiles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('加载失败: ${snapshot.error}'),
            );
          }

          final logFiles = snapshot.data ?? [];

          if (logFiles.isEmpty) {
            return const Center(
              child: Text('暂无日志文件'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: logFiles.length,
            itemBuilder: (context, index) {
              final fileInfo = logFiles[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(fileInfo.name),
                  subtitle: Text(
                    '大小: ${_formatFileSize(fileInfo.size)} | 修改: ${fileInfo.modified.toString().split('.')[0]}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: '查看',
                        onPressed: () => _viewLogFile(fileInfo),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: '删除',
                        onPressed: () => _deleteLogFile(fileInfo),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 日志文件信息
class FileInfo {
  final File file;
  final String name;
  final int size;
  final DateTime modified;

  FileInfo({
    required this.file,
    required this.name,
    required this.size,
    required this.modified,
  });
}
