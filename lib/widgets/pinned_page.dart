import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sns_calculator/assets.dart';

enum PinnedType {
  character,
  card,
  skill,
  status,
}

class PinnedProvider with ChangeNotifier {
  final Map<PinnedType, List<dynamic>> _pinnedMap = {
    PinnedType.character: [],
    PinnedType.card: [],
    PinnedType.skill: [],
    PinnedType.status: [],
  };

  List<dynamic> getPinnedList(PinnedType type) => _pinnedMap[type]!;

  // 检查某卡片是否已固定
  bool isPinned(PinnedType type, dynamic item) {
    // 按实体唯一标识判断（这里用name，你可替换为id等唯一字段）
    return _pinnedMap[type]!.any((pinnedItem) => _getItemKey(pinnedItem) == _getItemKey(item));
  }

  // 固定卡片：加入对应类型集合
  void pinItem(PinnedType type, dynamic item) {
    if (!isPinned(type, item)) {
      _pinnedMap[type]!.add(item);
      notifyListeners(); // 通知所有监听页面重绘
    }
  }

  // 取消固定：从对应类型集合移除
  void unpinItem(PinnedType type, dynamic item) {
    _pinnedMap[type]!.removeWhere((pinnedItem) => _getItemKey(pinnedItem) == _getItemKey(item));
    notifyListeners(); // 通知所有监听页面重绘
  }

  // 切换固定状态：点击按钮时调用（一键切换）
  void togglePin(PinnedType type, dynamic item) {
    isPinned(type, item) ? unpinItem(type, item) : pinItem(type, item);
  }

  // 清空某类型所有固定卡片
  void clearPinned(PinnedType type) {
    _pinnedMap[type]!.clear();
    notifyListeners();
  }

  // 私有方法：获取实体的唯一标识
  String _getItemKey(dynamic item) {
    // 按不同实体类返回唯一key
    if (item is CharacterInfo) return item.id;
    if (item is CardInfo) return item.id;
    if (item is SkillInfo) return item.id;
    if (item is StatusInfo) return item.id;
    return item.toString();
  }
}