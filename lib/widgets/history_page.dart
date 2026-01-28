import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

class HistoryPage extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSaveSelected;

  const HistoryPage({
    super.key,
    this.onSaveSelected,
  });

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<SaveFile> saveFiles = [];
  bool isLoading = true;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadSaveFiles();
  }

  /// 从 saves 目录加载所有存档文件
  Future<void> _loadSaveFiles() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final savesDir = Directory('${documentsDir.path}/saves');

      if (!await savesDir.exists()) {
        setState(() {
          saveFiles = [];
          isLoading = false;
        });
        return;
      }

      final files = savesDir.listSync();
      final jsonFiles = files
          .where((file) => file.path.endsWith('.json'))
          .cast<File>()
          .toList();

      // 按修改时间倒序排列（最新的在前）
      jsonFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      final List<SaveFile> loadedSaves = [];
      for (var file in jsonFiles) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content);
          loadedSaves.add(SaveFile(
            filename: file.path.split('/').last.replaceAll('.json', ''),
            filePath: file.path,
            timestamp: json['timestamp'] ?? '',
            historyLength: (json['history'] as List?)?.length ?? 0,
            lastModified: file.lastModifiedSync(),
          ));
        } catch (e) {
          _logger.w('Failed to parse save file: ${file.path}, error: $e');
        }
      }

      setState(() {
        saveFiles = loadedSaves;
        isLoading = false;
      });
    } catch (e) {
      _logger.e('Failed to load save files: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载存档列表失败: $e')),
      );
    }
  }

  /// 删除指定的存档文件
  Future<void> _deleteSaveFile(SaveFile saveFile) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除存档'),
          content: Text('确定要删除存档 "${saveFile.filename}" 吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final file = File(saveFile.filePath);
                  if (await file.exists()) {
                    await file.delete();
                    await _loadSaveFiles(); // 重新加载列表
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已删除存档: ${saveFile.filename}')),
                    );
                  }
                } catch (e) {
                  _logger.e('Failed to delete save file: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e')),
                  );
                }
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// 加载存档并返回保存的数据
  /// 返回值为 {currentHistoryIndex, history, timestamp}，用于在 InfoPage 中恢复
  Future<Map<String, dynamic>?> _loadSaveData(SaveFile saveFile) async {
    try {
      
      final file = File(saveFile.filePath);
      if (!await file.exists()) {
        throw Exception('存档文件不存在: ${saveFile.filePath}');
      }

      final content = await file.readAsString();    
      final json = jsonDecode(content) as Map<String, dynamic>;

      // 验证必要字段
      if (!json.containsKey('history') || !json.containsKey('currentHistoryIndex')) {
        throw Exception('存档数据结构不完整: 缺少必要字段');
      }

      return json;
    } catch (e) {
      _logger.e('Failed to load save data: $e', error: e, stackTrace: StackTrace.current);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏存档'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : saveFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('暂无存档', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadSaveFiles,
                        child: const Text('刷新'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: saveFiles.length,
                  itemBuilder: (context, index) {
                    final saveFile = saveFiles[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(saveFile.filename),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '时间: ${saveFile.timestamp.isEmpty ? '未知' : saveFile.timestamp}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '历史记录数: ${saveFile.historyLength}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '最后修改: ${saveFile.lastModified.toString().split('.').first}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Tooltip(
                                message: '加载此存档',
                                child: IconButton(
                                  icon: const Icon(Icons.download, color: Colors.green),
                                  onPressed: () async {
                                    try {
                                      final saveData = await _loadSaveData(saveFile);                                      
                                      if (saveData != null) {
                                        if (widget.onSaveSelected != null) {
                                          widget.onSaveSelected!(saveData);
                                        }
                                      } else {
                                        _logger.w('Save data is null, not loading');
                                      }
                                    } catch (e) {
                                      _logger.e('Error in load button: $e', error: e, stackTrace: StackTrace.current);
                                      if (mounted) {
                                        try {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('加载错误: $e')),
                                          );
                                        } catch (snackBarError) {
                                          _logger.e('Failed to show snackbar: $snackBarError');
                                        }
                                      }
                                    }
                                  },
                                ),
                              ),
                              Tooltip(
                                message: '删除此存档',
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteSaveFile(saveFile),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSaveFiles,
        tooltip: '刷新存档列表',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

/// 存档文件的数据类
class SaveFile {
  final String filename;
  final String filePath;
  final String timestamp;
  final int historyLength;
  final DateTime lastModified;

  SaveFile({
    required this.filename,
    required this.filePath,
    required this.timestamp,
    required this.historyLength,
    required this.lastModified,
  });
}
