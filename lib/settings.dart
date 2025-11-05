import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  // 道具设置
  // 破片水晶
  final List<String> endCrystalOptions = ['1', '2', '3', '4', '5', '6', '7', '8'];
  int _crystalMagic = 1;
  int _crystalSelf = 1;
  
  // 复合弓
  final List<String> bowOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  int _ammoCount = 1;
  
  // 后日谈
  List<String> _redstoneOptions = [];
  List<String> _redstonePlayerOptions = [];
  String _statusProlonged = '';
  String _playerProlonged = '';
  
  // 混乱力场
  final List<String> ascensionStairOptions = ['1', '2', '3', '4', '5', '6'];
  Map<String, int> _ascensionPoints = {};
  
  // 极光震荡
  final List<String> auroraOptions = ['1', '2'];
  Map<String, int> _auroraPoints = {};
  
  // 潘多拉魔盒
  final List<String> pandoraBoxOptions = ['1', '2', '3', '4', '5', '6'];
  int _pandoraPoint = 1;
  
  // 折射水晶
  final List<String> amethystOptions = ['1', '2'];
  int _amethystPoint = 1;
  
  // 攻击特效设置
  // 烛焱
  final List<String> lumenFlareOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  int _lumenFlarePoint = 1;
  
  // 障目
  final List<String> oculusVeilOptions = ['1', '2'];
  int _oculusVeilPoint = 1;
  
  // 防守特效设置
  // 蚀凛
  final List<String> erodeGelidOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  int _erodeGelidPoint = 1;

  // Getters
  int get crystalMagic => _crystalMagic;
  int get crystalSelf => _crystalSelf;
  int get ammoCount => _ammoCount;
  List<String> get redstoneOptions => _redstoneOptions;
  List<String> get redstonePlayerOptions => _redstonePlayerOptions;
  String get statusProlonged => _statusProlonged;
  String get playerProlonged => _playerProlonged;
  Map<String, int> get ascensionPoints => _ascensionPoints;
  Map<String, int> get auroraPoints => _auroraPoints;
  int get pandoraPoint => _pandoraPoint;
  int get amethystPoint => _amethystPoint;
  int get lumenFlarePoint => _lumenFlarePoint;
  int get oculusVeilPoint => _oculusVeilPoint;
  int get erodeGelidPoint => _erodeGelidPoint;

  // Setters with notifyListeners
  void setCrystalMagic(int value) {
    _crystalMagic = value;
    notifyListeners();
  }
  
  void setCrystalSelf(int value) {
    _crystalSelf = value;
    notifyListeners();
  }
  
  void setAmmoCount(int value) {
    _ammoCount = value;
    notifyListeners();
  }
  
  void setStatusProlonged(String value) {
    _statusProlonged = value;
    notifyListeners();
  }
  
  void setPlayerProlonged(String value) {
    _playerProlonged = value;
    notifyListeners();
    // 当玩家改变时，更新可选的状态列表
    updateRedstoneOptions();
  }
  
  void setAscensionPoints(Map<String, int> value) {
    _ascensionPoints = Map<String, int>.from(value);
    notifyListeners();
  }
  
  void setAuroraPoints(Map<String, int> value) {
    _auroraPoints = Map<String, int>.from(value);
    notifyListeners();
  }
  
  void setPandoraPoint(int value) {
    _pandoraPoint = value;
    notifyListeners();
  }
  
  void setAmethystPoint(int value) {
    _amethystPoint = value;
    notifyListeners();
  }
  
  void setLumenFlarePoint(int value) {
    _lumenFlarePoint = value;
    notifyListeners();
  }
  
  void setOculusVeilPoint(int value) {
    _oculusVeilPoint = value;
    notifyListeners();
  }
  
  void setErodeGelidPoint(int value) {
    _erodeGelidPoint = value;
    notifyListeners();
  }
  
  void setRedstonePlayerOptions(List<String> options) {
    _redstonePlayerOptions = List<String>.from(options);
    notifyListeners();
  }
  
  void updateRedstoneOptions() {
    // 这个方法应该在 CardSettingsDialogState 中调用时传入正确的选项
    notifyListeners();
  }
  
  void setRedstoneOptions(List<String> options) {
    _redstoneOptions = List<String>.from(options);
    notifyListeners();
  }
  
  // 初始化方法
  void initializePoints(List<String> playerIds) {
    _ascensionPoints = {};
    _auroraPoints = {};
    
    for (var playerId in playerIds) {
      _ascensionPoints[playerId] = 1;
      _auroraPoints[playerId] = 1;
    }
    notifyListeners();
  }
  
  // 重置所有设置
  void resetSettings() {
    _crystalMagic = 1;
    _crystalSelf = 1;
    _ammoCount = 1;
    _statusProlonged = '';
    _playerProlonged = '';
    _pandoraPoint = 1;
    _amethystPoint = 1;
    _lumenFlarePoint = 1;
    _oculusVeilPoint = 1;
    _erodeGelidPoint = 1;
    notifyListeners();
  }
}