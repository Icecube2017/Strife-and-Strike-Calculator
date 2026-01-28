import 'package:flutter/foundation.dart';
import 'package:sns_calculator/core.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

/// 游戏日志条目
class GameLogEntry {
  final DateTime timestamp;
  final String message;
  final String category;

  GameLogEntry({
    required this.timestamp,
    required this.message,
    required this.category,
  });

  /// 格式化日志条目
  String toFormattedString() {
    return '[${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}] [$category] $message';
  }
}

/// 游戏日志管理器
class GameLogger extends ChangeNotifier {
  static final GameLogger _instance = GameLogger._internal();

  factory GameLogger() {
    return _instance;
  }

  GameLogger._internal();

  final List<GameLogEntry> _logs = [];
  static const int maxLogs = 1000; // 最多保存1000条日志
  static const String _logsFolder = 'log';
  late File _logsFile;
  bool _isInitialized = false;

  /// 生成日志文件名（格式：log-20260126.json）
  String _generateLogsFileName() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'log-$dateStr.json';
  }

  /// 获取所有日志
  List<GameLogEntry> get logs => List.unmodifiable(_logs);

  /// 初始化日志系统（从文件加载日志）
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${documentsDir.path}/$_logsFolder');
      
      // 创建 log 文件夹（如果不存在）
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      // 获取当前日期的日志文件
      _logsFile = File('${logDir.path}/${_generateLogsFileName()}');
      
      // 尝试从文件加载日志
      if (await _logsFile.exists()) {
        final content = await _logsFile.readAsString();
        final jsonList = jsonDecode(content) as List<dynamic>;
        
        for (var item in jsonList) {
          try {
            final entry = GameLogEntry(
              timestamp: DateTime.parse(item['timestamp'] as String),
              message: item['message'] as String,
              category: item['category'] as String,
            );
            _logs.add(entry);
          } catch (e) {
            // 忽略解析错误的日志条目
          }
        }
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      Logger().e('Failed to initialize GameLogger: $e');
      _isInitialized = true; // 即使失败也标记为已初始化
    }
  }

  /// 将日志保存到文件
  Future<void> _saveLogs() async {
    if (!_isInitialized) return;
    
    try {
      final jsonList = _logs.map((log) => {
        'timestamp': log.timestamp.toIso8601String(),
        'message': log.message,
        'category': log.category,
      }).toList();
      
      await _logsFile.writeAsString(
        jsonEncode(jsonList),
        flush: true,
      );
    } catch (e) {
      Logger().e('Failed to save game logs: $e');
    }
  }

  /// 添加日志
  void addLog(String message, {String category = '游戏'}) {
    final entry = GameLogEntry(
      timestamp: DateTime.now(),
      message: message,
      category: category,
    );

    _logs.add(entry);

    // 当日志超过最大数量时，删除最旧的日志
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }

    notifyListeners();
    
    // 保存日志到文件
    _saveLogs();
  }

  /// 添加玩家相关日志
  void addPlayerLog(String playerId, String action) {
    addLog('玩家 $playerId: $action', category: '玩家');
  }

  /// 添加行动相关日志
  void addActionLog(GameTurn gameTurn, String source, String target, int point, String cards, String detail) {
    addLog('回合${gameTurn.round} 轮次${gameTurn.turn} 额外${gameTurn.extra}，$source 对 $target 发起攻击，卡牌为 $cards，点数为 $point', category: '行动');
  }

  // 添加属性相关日志
  void addAttributeLog(GameTurn gameTurn, String playerId, String attribute, int value) {
    addLog('回合${gameTurn.round} 轮次${gameTurn.turn} 额外${gameTurn.extra}，玩家 $playerId 属性 $attribute: $value', category: '属性');
  }

  /// 添加状态相关日志
  void addStatusLog(GameTurn gameTurn, String playerId, String status, int intensity, int layer) {
    addLog('回合${gameTurn.round} 轮次${gameTurn.turn} 额外${gameTurn.extra}，玩家 $playerId 状态 $status: 层数 $layer，强度 $intensity', category: '状态');
  }

  /// 添加技能相关日志
  void addSkillLog(GameTurn gameTurn, String source, String target, String skill, String detail) {
    addLog('回合${gameTurn.round} 轮次${gameTurn.turn} 额外${gameTurn.extra}，$source 对 $target 使用技能 $skill: $detail', category: '技能');
  }

  // 添加特质相关日志
  void addTraitLog(GameTurn gameTurn, String source, String target, String trait, String detail) {
    addLog('回合${gameTurn.round} 轮次${gameTurn.turn} 额外${gameTurn.extra}，$source 对 $target 使用特质 $trait: $detail', category: '特质');
  }

  // 添加伤害相关日志
  void addDamageLog(GameTurn gameTurn, String source, String target, int damage, DamageType damageType, String detail) {
    addLog('回合${gameTurn.round} 轮次${gameTurn.turn} 额外${gameTurn.extra}，$source 对 $target 造成 $damage ($damageType) 点伤害', category: '伤害');
  }

  /// 添加治疗相关日志
  void addHealLog(GameTurn gameTurn, String source, String target, int heal) {
    addLog('回合${gameTurn.round} 轮次${gameTurn.turn} 额外${gameTurn.extra}，$source 对 $target 治疗 $heal 点生命值', category: '治疗');
  }

  // 添加统计相关日志
  void addStatisticsLog(GameTurn gameTurn, String playerId, String stat, int value) {
    addLog('回合${gameTurn.round} 轮次${gameTurn.turn} 额外${gameTurn.extra}，玩家 $playerId 统计 $stat: $value', category: '统计');
  }

  /// 清空所有日志
  void clearLogs() async {
    _logs.clear();
    notifyListeners();
    await _saveLogs();
  }

  /// 获取最近N条日志
  List<GameLogEntry> getRecentLogs(int count) {
    final startIndex = _logs.length > count ? _logs.length - count : 0;
    return _logs.sublist(startIndex);
  }
}
