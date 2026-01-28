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
              child: Row(
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
            ),
            // 日志内容区域
            Expanded(
              child: Consumer<GameLogger>(
                builder: (context, gameLogger, child) {
                  final logs = gameLogger.logs;
                  return logs.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无日志',
                            style: TextStyle(color: Colors.grey, fontSize: 14.0),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8.0),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
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
