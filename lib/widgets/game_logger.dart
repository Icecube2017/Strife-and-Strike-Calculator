import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_calculator/logger.dart';

/// 游戏日志窗口
class GameLoggerWindow extends StatefulWidget {
  const GameLoggerWindow({super.key});

  @override
  State<GameLoggerWindow> createState() => _GameLoggerWindowState();
}

class _GameLoggerWindowState extends State<GameLoggerWindow> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void didUpdateWidget(GameLoggerWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 自动滚动到底部
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '游戏日志',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                            tooltip: '清空日志',
                            onPressed: () {
                              final gameLogger = GameLogger();
                              gameLogger.clearLogs();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: '关闭',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // 筛选栏
                  Row(                    
                    children: [
                      /*const Text(
                        '筛选:',
                        style: TextStyle(color: Colors.white, fontSize: 14.0),
                      ),*/
                      const SizedBox(width: 8.0),
                      
                      // 开始时间筛选
                      Column(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.access_time, color: Colors.white70, size: 16.0),
                            label: Text(
                              _startTime == null
                                  ? '开始时间'
                                  : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:${_startTime!.second.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12.0),
                            ),
                            onPressed: () async {
                              final now = DateTime.now();
                              final pickedStart = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_startTime ?? now),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Colors.blue,
                                        onPrimary: Colors.white,
                                        surface: Color(0xFF424242),
                                        onSurface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedStart != null) {
                                final startDateTime = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  pickedStart.hour,
                                  pickedStart.minute,
                                );
                                setState(() {
                                  _startTime = startDateTime;
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 8.0),
                          // 结束时间筛选
                          TextButton.icon(
                            icon: const Icon(Icons.access_time, color: Colors.white70, size: 16.0),
                            label: Text(
                              _endTime == null
                                  ? '结束时间'
                                  : '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:${_endTime!.second.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12.0),
                            ),
                            onPressed: () async {
                              final now = DateTime.now();
                              final pickedEnd = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_endTime ?? now),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Colors.blue,
                                        onPrimary: Colors.white,
                                        surface: Color(0xFF424242),
                                        onSurface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedEnd != null) {
                                final endDateTime = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  pickedEnd.hour,
                                  pickedEnd.minute,
                                );
                                setState(() {
                                  _endTime = endDateTime;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      // 类型筛选
                      Column(
                        children: [
                          DropdownButton<String>(
                            value: _selectedCategory,
                            hint: const Text(
                              '选择类型',
                              style: TextStyle(color: Colors.white70, fontSize: 12.0),
                            ),
                            dropdownColor: Colors.grey[800],
                            style: const TextStyle(color: Colors.white, fontSize: 12.0),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('全部类型'),
                              ),
                              ..._getCategories().map((category) => DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                          const SizedBox(width: 8.0),
                          // 清除筛选
                          //if (_startTime != null || _endTime != null ||_selectedCategory != null)
                            TextButton.icon(
                              icon: const Icon(Icons.clear, color: Colors.white70, size: 16.0),
                              label: const Text(
                                '清除筛选',
                                style: TextStyle(color: Colors.white70, fontSize: 12.0),
                              ),
                              onPressed: (_startTime != null || _endTime != null ||_selectedCategory != null)
                              ? () {
                                setState(() {
                                  _selectedCategory = null;
                                  _startTime = null;
                                  _endTime = null;
                                });
                              } 
                              : null,
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 日志内容区域
            Expanded(
              child: Consumer<GameLogger>(
                builder: (context, gameLogger, child) {
                  final allLogs = gameLogger.logs;
                  final filteredLogs = _filterLogs(allLogs);
                  return filteredLogs.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无匹配日志',
                            style: TextStyle(color: Colors.grey, fontSize: 14.0),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8.0),
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 2.0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: _getLogColor(log.category),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                log.toFormattedString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.0,
                                  fontFamily: 'monospace',
                                ),
                                softWrap: true,
                              ),
                            );
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<GameLogEntry> _filterLogs(List<GameLogEntry> logs) {
    return logs.where((log) {
      // 类型筛选
      if (_selectedCategory != null && log.category != _selectedCategory) {
        return false;
      }
      // 时间范围筛选
      if (_startTime != null && _endTime != null) {
        final logTime = TimeOfDay.fromDateTime(log.timestamp);
        final startTime = TimeOfDay.fromDateTime(_startTime!);
        final endTime = TimeOfDay.fromDateTime(_endTime!);
        
        // 将时间转换为分钟进行比较
        final logMinutes = logTime.hour * 60 + logTime.minute;
        final startMinutes = startTime.hour * 60 + startTime.minute;
        final endMinutes = endTime.hour * 60 + endTime.minute;
        
        if (logMinutes < startMinutes || logMinutes > endMinutes) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<String> _getCategories() {
    return [
      '玩家',
      '行动',
      '技能',
      '特质',
      '伤害',
      '治疗',
      '状态',
      '属性',
      '统计',
    ];
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
