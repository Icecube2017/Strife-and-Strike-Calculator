import 'package:flutter/foundation.dart';

class HistoryProvider with ChangeNotifier {
  List<String> _history = [];
  int currentIndex = -1;
  final int _maxHistorySize = 100;

  List<String> get history => _history;
  int get currentHistoryIndex => currentIndex;
  int get maxHistorySize => _maxHistorySize;

  // 保存当前游戏状态到历史记录
  void saveCurrentStateToHistory(String currentState) {
    // 如果当前不是在历史记录的最新位置，删除后续的历史记录
    if (currentIndex < _history.length - 1) {
      _history = _history.sublist(0, currentIndex + 1);
    }

    // 添加新状态到历史记录
    _history.add(currentState);
    currentIndex++;

    // 限制历史记录数量
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
      currentIndex--;
    }

    notifyListeners();
  }

  // 回到上一个游戏状态
  void undo() {
    if (currentIndex > 0) {
      currentIndex--;
      notifyListeners();
    }
  }

  // 重做到下一个游戏状态
  void redo() {
    if (currentIndex < _history.length - 1) {
      currentIndex++;
      notifyListeners();
    }
  }

  // 访问历史状态中的任意数据
  String getStateAt(int index) {
    if (index >= 0 && index < _history.length) {
      return _history[index];
    }
    throw Exception('Invalid index: $index');
  }

  // 获取当前状态
  String? getCurrentState() {
    if (currentIndex >= 0 && currentIndex < _history.length) {
      return _history[currentIndex];
    }
    return null;
  }

  // 重置历史记录
  void resetHistory() {
    _history.clear();
    currentIndex = -1;
    notifyListeners();
  }

  // 设置历史记录（用于加载保存的游戏）
  void setHistory(List<String> history, int currentIndex) {
    _history = List<String>.from(history);
    this.currentIndex = currentIndex;
    notifyListeners();
  }
}