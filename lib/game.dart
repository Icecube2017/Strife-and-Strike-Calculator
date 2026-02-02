import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:sns_calculator/history.dart';
import 'package:sns_calculator/logger.dart';
import 'dart:convert';
import 'assets.dart';
import 'core.dart';
import 'record.dart';

// 全局状态效果
class GlobalCountdown{
  // 达摩克利斯之剑
  int damocles = 0;
  int reinforcedDamocles = 0;
  // 失乐园
  int eden = 0;
  int reinforcedEden = 0;
  // 额外回合
  int extraTurn = 0;
  // 反重力
  int antiGravity = 0;
  // 高淼【轻捷妙手】
  String deftTouchSkill = '';
  String deftTouchTarget = '';
}

class Character{
  String id;
  int maxHealth, attack, defence, maxMove, moveRegen, regenType, regenTurn;
  int health = 0, armor = 0, movePoint = 0, cardCount = 2, maxCard = 6, actionTime = 0;
  int damageReceivedTotal = 0, damageDealtTotal = 0, damageDealtRound = 0, damageReceivedRound = 0,
  damageReceivedTurn = 0, damageDealtTurn = 0;
  int cureReceivedTotal = 0, cureDealtTotal = 0, cureReceivedRound = 0, cureDealtRound = 0,
  cureReceivedTurn = 0, cureDealtTurn = 0;
  bool isDead = false;
  Map<String, List<dynamic>> status = {}, hiddenStatus = {};
  Map<String, int> skill = {}, skillStatus = {};

  Character(this.id, this.maxHealth, this.attack, this.defence, this.movePoint, 
  this.maxMove, this.moveRegen, this.regenType, this.regenTurn){
    health = maxHealth;
  }

  bool hasStatus(String stat){
    return status.keys.contains(stat);
  }

  int getStatusIntensity(String stat){
    try{
      var statusData = status[stat];
      if (statusData != null && statusData.isNotEmpty) {
        return (statusData[0] as num).toInt();
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  int getStatusLayer(String stat){
    try{
      var statusData = status[stat];
      if (statusData != null && statusData.length > 1) {
        return (statusData[1] as num).toInt();
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  int getStatusIntData(String stat){
    try{
      var statusData = status[stat];
      if (statusData != null && statusData.length > 3) {
        return (statusData[3] as num).toInt();
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }
  
  int getHiddenStatusIntensity(String stat){ 
    try{
      var statusData = hiddenStatus[stat];
      if (statusData != null && statusData.isNotEmpty) {
        return (statusData[0] as num).toInt();
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  int getHiddenStatusLayer(String stat){ 
    try{
      var statusData = hiddenStatus[stat];
      if (statusData != null && statusData.length > 1) {
        return (statusData[1] as num).toInt();
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  int getHiddenStatusIntData(String stat){ 
    try{
      var statusData = hiddenStatus[stat];
      if (statusData != null && statusData.length > 3) {
        return (statusData[3] as num).toInt();
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  bool hasHiddenStatus(String stat){ 
    return hiddenStatus.keys.contains(stat);
  }
}

final Character emptyCharacter = Character('empty', 131072, 0, 0, 0, 0, 0, 0, 0);

class Game extends ChangeNotifier{
  String id;
  GameType gameType;
  GameState gameState = GameState.waiting;
  List<String> gameSequence = [];
  Map<String, Character> players = {};
  var playerDied = {};
  Map<int, Set<String>> teams = {};
  int playerCount = 0, playerDiedCount = 0, turn = 0, round = 1, teamCount = 0, extra = 0;

  

  List<GameTurn> gameTurnList = [];
  GlobalCountdown countdown = GlobalCountdown();
  final Logger _logger = Logger(printer: PrettyPrinter(), output: MultiOutput([ConsoleOutput()]));

  final AssetsManager assets = AssetsManager();
  Map<String, dynamic>? langMap;
  Map<String, dynamic>? skillCooldown;
  Map<String, dynamic>? statusData;
  Map<String, dynamic>? tagData;

  RecordProvider? _recordProvider;
  HistoryProvider? _historyProvider;
  GameLogger? _gameLogger;

  Game(this.id, this.gameType){
    players['empty'] = emptyCharacter;
    _initializeAssets();
  }

  Future<void> _initializeAssets() async {
    await assets.loadData();
    langMap = assets.langMap;
    skillCooldown = assets.skillData;
    statusData = assets.statusData;
    tagData = assets.tagData;
  }

  // 设置RecordProvider
  void setRecordProvider(RecordProvider recordProvider){
    _recordProvider = recordProvider;
  }

  // 设置HistoryProvider
  void setHistoryProvider(HistoryProvider historyProvider){
    _historyProvider = historyProvider;
  }

  void setGameLogger(GameLogger logger){
    _gameLogger = logger;
  }

  GameTurn getGameTurn() {
    return GameTurn(round: round, turn: turn, extra: extra);
  }

  GameTurn getPreviousGameTurn() {
    return gameTurnList.length > 2 ? gameTurnList[gameTurnList.length - 2] : getGameTurn();
  }

  void clearGame(){
    players.clear();
    gameSequence.clear();
    playerDied.clear();
    teams.clear();
    playerCount = 0;
    turn = 0;
    round = 1;
    teamCount = 0;
    gameTurnList.clear();
    countdown = GlobalCountdown();
    gameState = GameState.waiting;
    players['empty'] = emptyCharacter;
  }


  void addPlayer(Character character){
    players[character.id] = character;
    gameSequence.add(character.id);
    playerCount++;
  }

  void removePlayer(Character character){
    players.remove(character.id);
    gameSequence.remove(character.id);
    // 从所有队伍中移除该玩家
    for (var entry in teams.entries){
      entry.value.remove(character.id);
    }
    playerCount--;
  }

  bool isCharacterInGame(String charaId){ 
    if (!players.containsKey(charaId)) return false;
    return !players[charaId]!.isDead;
  }

  /// 添加一个队伍并返回队伍 id
  int addTeam(){
    teamCount += 1;
    teams[teamCount] = <String>{};
    return teamCount;
  }

  /// 删除指定队伍
  void removeTeam(int teamId){
    if (teams.containsKey(teamId)){
      teams.remove(teamId);
      // 更新计数（保持为现有队伍数量）
      teamCount = teams.length;
    }
  }

  /// 将玩家加入队伍
  void addPlayerToTeam(int teamId, String playerId){
    if (!players.containsKey(playerId)) return;
    // 从其它队伍移除
    for (var entry in teams.entries){
      entry.value.remove(playerId);
    }
    teams.putIfAbsent(teamId, () => <String>{});
    teams[teamId]!.add(playerId);
  }

  /// 从队伍移除玩家
  void removePlayerFromTeam(int teamId, String playerId){
    if (teams.containsKey(teamId)){
      teams[teamId]!.remove(playerId);
    }
  }

  /// 获取某玩家所在队伍 id（若未在队伍则返回 null）
  int? getPlayerTeam(String playerId){
    for (var e in teams.entries){
      if (e.value.contains(playerId)) return e.key;
    }
    return null;
  }

  /// 判断两个玩家是否是队友
  bool isTeammate (String source, String target) { 
    return source != target && getPlayerTeam(source) == getPlayerTeam(target) && gameType == GameType.team && source != 'empty' && target != 'empty';
  }

  // 判断两个玩家是否是敌人
  bool isEnemy (String source, String target) { 
    return source != target && (gameType == GameType.single || (getPlayerTeam(source) != getPlayerTeam(target) && gameType == GameType.team)) && source != 'empty' && target != 'empty';
  }

  /// 切换游戏类型
  void toggleGameType(){
    var types = GameType.values;
    int idx = types.indexOf(gameType);
    idx = (idx + 1) % types.length;
    gameType = types[idx];
    refresh();
  }

  void addAttribute(String charaId, AttributeType type, int value){
    Character chara = players[charaId]!; 
    int attValue = value;
    if(type == AttributeType.health){
      attValue = chara.health + attValue > chara.maxHealth ? chara.maxHealth - chara.health : attValue;
      chara.health += attValue;
    }
    else if(type == AttributeType.maxhp){      
      chara.maxHealth += attValue;
      //chara.health = chara.health > chara.maxHealth ? chara.maxHealth : chara.health;
    }
    else if(type == AttributeType.attack){chara.attack += attValue;}
    else if(type == AttributeType.defence){chara.defence += attValue;}
    else if(type == AttributeType.armor){
      chara.armor += attValue;
      // 沈姝华【纯洁之爱】
      if (isCharacterInGame(langMap!['shen_shuhua']) && chara.armor == 0) {
        castTrait(langMap!['shen_shuhua'], [langMap!['shen_shuhua']], langMap!['innocent_love'], {'type': 1});
      }
    }
    else if(type == AttributeType.movepoint){
      attValue = chara.movePoint + attValue > chara.maxMove ? chara.maxMove - chara.movePoint : attValue;
      attValue = chara.movePoint + attValue < 0 ? -chara.movePoint : attValue;
      chara.movePoint += attValue;
      // 云津【云系祝乐】
      if (charaId == langMap!['clouddamp']) {
        castTrait(charaId, [charaId], langMap!['celestial_joy'], {'type': 2, 'movepoint': -attValue});
      }
    }
    else if(type == AttributeType.maxmove){chara.maxMove += attValue;}
    else if(type == AttributeType.card){
      attValue = chara.cardCount + attValue < 0 ? -chara.cardCount : attValue; 
      chara.cardCount += attValue;
    }
    else if(type == AttributeType.maxcard){chara.maxCard += attValue;}
    else if(type == AttributeType.dmgdealt) {chara.damageDealtTotal += attValue; chara.damageDealtRound += attValue; chara.damageDealtTurn += attValue;}
    else if(type == AttributeType.dmgreceived) {chara.damageReceivedTotal += attValue; chara.damageReceivedRound += attValue; chara.damageReceivedTurn += attValue;}
    else if(type == AttributeType.curdealt) {chara.cureDealtTotal += attValue; chara.cureDealtRound += attValue; chara.cureDealtTurn += attValue;}
    else if(type == AttributeType.curreceived) {chara.cureReceivedTotal += attValue; chara.cureReceivedRound += attValue; chara.cureReceivedTurn += attValue;}
    if ({AttributeType.armor, AttributeType.attack, AttributeType.defence, AttributeType.movepoint, AttributeType.card, 
    AttributeType.maxhp, AttributeType.maxmove, AttributeType.maxcard}.contains(type)) {
      _gameLogger!.addAttributeLog(getGameTurn(), charaId, type.name, attValue);
    }    
    refresh();
  }

  void addStatus(String charaId, String status, int intensity, int layer){
    Character chara = players[charaId]!;
    bool isImmune = false;
    List<int> statusDataOld = [chara.getStatusIntensity(status), chara.getStatusLayer(status)];
    if (chara.hasStatus(langMap!['gugu'])) {
      isImmune = true;
    }
    if (chara.hasHiddenStatus('babel')){
      isImmune = true;
    }
    // 科亚特尔【拟造“伊甸园”】
    if (chara.hasStatus(langMap!['sanctify']) && statusData![status][0] == 1) {
      isImmune = true;
      // chara.status[langMap!['sanctify']]![1] -= 1;
      modifyStatusLayer(charaId, langMap!['sanctify'], -1);
      if (chara.getStatusLayer(langMap!['sanctify']) == 0) {
        removeStatus(charaId, langMap!['sanctify']);
      }
    }
    // 茵竹【自勉】
    if (charaId == langMap!['chinro'] && status == langMap!['dissociated']) {
      List<bool> isImmuneRef = [isImmune];
      castTrait(charaId, [charaId], langMap!['self_encouragement'], {'type': 1, 'isImmuneRef': isImmuneRef});
      isImmune = isImmuneRef[0];
    }
    // 时雨【寒冰血脉】
    if (charaId == langMap!['shigure'] && {langMap!['frozen'], langMap!['frost']}.contains(status)){
      List<bool> isImmuneRef = [isImmune];
      castTrait(charaId, [charaId], langMap!['icy_blood'], {'type': 0, 'isImmuneRef': isImmuneRef});
      isImmune = isImmuneRef[0];
    }
    // 红烬【烈焰之体】
    if (charaId == langMap!['ember'] && {langMap!['frozen'], langMap!['frost']}.contains(status)){
      List<bool> isImmuneRef = [isImmune];
      castTrait(charaId, [charaId], langMap!['conflagration_avatar'], {'type': 0, 'isImmuneRef': isImmuneRef});
      isImmune = isImmuneRef[0];
    }
    // 阿波菲斯【毁灭暗影】
    if (charaId == langMap!['apophis'] && status == langMap!['nightmare']) {
      isImmune = true;
    }
    if (!isImmune) {
      try {
        if (status == langMap!['teroxis']) {
          if(chara.getStatusIntensity(langMap!['teroxis']) + intensity <= 5){
            chara.status[status]![0] += intensity;
            addAttribute(charaId, AttributeType.attack, 5 * intensity);
          }
          else{
            chara.status[status]![0] = 5;
            addAttribute(charaId, AttributeType.attack, 5 * (5 - chara.getStatusIntensity(langMap!['teroxis'])));
          }   
        }
        else if (status == langMap!['soul_flare']) {
          chara.status[status]![0] += intensity;
        }
        else {
          chara.status[status]![1] += layer;
        }        
      }
      catch (e) {
        chara.status[status] = [intensity, layer, playerCount, 0];
        if (status == langMap!['frost']) {
          addAttribute(charaId, AttributeType.attack, -4 * chara.getStatusIntensity(langMap!['frost']));
        }
        else if (status == langMap!['exhausted']) {
          chara.status[langMap!['exhausted']]![3] = (chara.attack / 2).toInt();
          addAttribute(charaId, AttributeType.attack, -chara.getStatusIntData(langMap!['exhausted']));
        }
        else if (status == langMap!['strength']) {
          addAttribute(charaId, AttributeType.attack, 5 * chara.getStatusIntensity(langMap!['strength']));
        }
        else if (status == langMap!['teroxis']) {
          addAttribute(charaId, AttributeType.attack, 5 * intensity);
        }
        else if (status == langMap!['lumen_flare']) {
          addAttribute(charaId, AttributeType.attack, 5);
        }
        else if (status == langMap!['erode_gelid']) {
          addAttribute(charaId, AttributeType.defence, 5);
        }
        else if (status == langMap!['grind']) {
          chara.status[langMap!['grind']]![3] = 2;
          addAttribute(charaId, AttributeType.maxmove, -chara.getStatusIntData(langMap!['grind']));
        }
        else if (status == langMap!['fragility']) {
          addAttribute(charaId, AttributeType.defence, -2 * chara.getStatusIntensity(langMap!['fragility']));
        }
        else if (status == langMap!['mirror']) {
          chara.status[langMap!['mirror']]![3] = chara.attack * 1024 + chara.defence;
          addAttribute(charaId, AttributeType.attack, chara.getStatusIntData(langMap!['mirror']) % 1024 - chara.attack);
          addAttribute(charaId, AttributeType.defence, (chara.getStatusIntData(langMap!['mirror']) / 1024).toInt() - chara.defence);
        }
        else if (status == langMap!['burn_out']) {
          addAttribute(charaId, AttributeType.attack, 5 * chara.getStatusIntensity(langMap!['burn_out']));
          addAttribute(charaId, AttributeType.defence, -5 * chara.getStatusIntensity(langMap!['burn_out']));
        }
        else if (status == langMap!['corroded']) {
          addAttribute(charaId, AttributeType.attack, -10 * chara.getStatusIntensity(langMap!['corroded']));
        }
        else if (status == langMap!['weakness']) {
          addAttribute(charaId, AttributeType.attack, -5 * chara.getStatusIntensity(langMap!['weakness']));
        }
        else if (status == langMap!['drowsy']) {
          addAttribute(charaId, AttributeType.attack, -5 * chara.getStatusIntensity(langMap!['drowsy']));
          addAttribute(charaId, AttributeType.defence, -5 * chara.getStatusIntensity(langMap!['drowsy']));
        }        
        else if (status == langMap!['eden']) {
          addAttribute(charaId, AttributeType.attack, 3 * chara.getStatusIntensity(langMap!['eden']));
          addHiddenStatus(charaId, 'apocalypse', 0, -1);
          List<String> statusList = chara.status.keys.toList();
          for (String status in statusList) {
            if (statusData![status][0] == 1) {
              removeStatus(charaId, status);
            }
          }
        }
        else if (status == langMap!['dehydration']) {
          addAttribute(charaId, AttributeType.defence, -10 * chara.getStatusIntensity(langMap!['dehydration']));
        }
        else if (status == langMap!['submerged']) {
          addAttribute(charaId, AttributeType.attack, -10 * chara.getStatusIntensity(langMap!['submerged']));
        }
        else if (status == langMap!['asphyxia']) {
          addAttribute(charaId, AttributeType.maxhp, -30 * chara.getStatusIntensity(langMap!['asphyxia']));
          if (chara.health > chara.maxHealth) {
            damagePlayer('empty', chara.id, chara.health - chara.maxHealth, DamageType.lost);
          }
        }

        // 冰火相融
        if (chara.hasStatus(langMap!['frost']) && chara.hasStatus(langMap!['flaming'])) {
          int frostIntensity = chara.getStatusIntensity(langMap!['frost']);
          int flamingIntensity = chara.getStatusIntensity(langMap!['flaming']);
          if (frostIntensity > flamingIntensity) {
            removeStatus(charaId, langMap!['flaming']);
            modifyStatusIntensity(charaId, langMap!['frost'], -flamingIntensity);
          }
          else if (flamingIntensity > frostIntensity) {
            removeStatus(charaId, langMap!['frost']);
            modifyStatusIntensity(charaId, langMap!['flaming'], -frostIntensity);
          }
          else {
            removeStatus(charaId, langMap!['frost']);
            removeStatus(charaId, langMap!['flaming']);
          }
        }
        if (chara.hasStatus(langMap!['frozen']) && chara.hasStatus(langMap!['inferno_fire'])) {
          int frozenLayer = chara.getStatusLayer(langMap!['frozen']);
          int infernoFireLayer = chara.getStatusLayer(langMap!['inferno_fire']);
          if (frozenLayer > infernoFireLayer) {
            removeStatus(charaId, langMap!['inferno_fire']);
            modifyStatusLayer(charaId, langMap!['frozen'], -infernoFireLayer);
          }
          else if (infernoFireLayer > frozenLayer) {
            removeStatus(charaId, langMap!['frozen']);
            modifyStatusLayer(charaId, langMap!['inferno_fire'], -frozenLayer);
          }
          else {
            removeStatus(charaId, langMap!['frozen']);
            removeStatus(charaId, langMap!['inferno_fire']);
          }
        }
      }
      _recordProvider!.addStatusRecord(getGameTurn(), emptyCharacter.id, charaId, status, 
      statusDataOld, [chara.getStatusIntensity(status), chara.getStatusLayer(status)], '');
      _gameLogger!.addStatusLog(getGameTurn(), charaId, status, chara.getStatusIntensity(status), chara.getStatusLayer(status));
    }
    refresh();
  }

  void removeStatus(String charaId, String status){ 
    Character chara = players[charaId]!;

    if (!chara.hasStatus(status)) {return;}

    if (status == langMap!['frost']) {
      addAttribute(charaId, AttributeType.attack, 4 * chara.getStatusIntensity(langMap!['frost']));
    }
    else if (status == langMap!['exhausted']) {
      addAttribute(charaId, AttributeType.attack, chara.getStatusIntData(langMap!['exhausted']));
    }
    else if (status == langMap!['strength']) {
      addAttribute(charaId, AttributeType.attack, -5 * chara.getStatusIntensity(langMap!['strength']));
    }
    else if (status == langMap!['teroxis']) {
      addAttribute(charaId, AttributeType.attack, -5 * chara.getStatusIntensity(langMap!['teroxis']));
    }
    else if (status == langMap!['lumen_flare']) {
      addAttribute(charaId, AttributeType.attack, -5);
    }
    else if (status == langMap!['erode_gelid']) {
      addAttribute(charaId, AttributeType.defence, -5);
    }
    else if (status == langMap!['grind']) {
      addAttribute(charaId, AttributeType.maxmove, chara.getStatusIntData(langMap!['grind']));
    }
    else if (status == langMap!['fragility']) {
      addAttribute(charaId, AttributeType.defence, 2 * chara.getStatusIntensity(langMap!['fragility']));
    }
    else if (status == langMap!['mirror']) {
      addAttribute(charaId, AttributeType.attack, (chara.getStatusIntData(langMap!['mirror']) / 1024).toInt() - chara.attack);
      addAttribute(charaId, AttributeType.defence, chara.getStatusIntData(langMap!['mirror']) % 1024 - chara.defence);
    }
    else if (status == langMap!['burn_out']) {
      addAttribute(charaId, AttributeType.attack, -5 * chara.getStatusIntensity(langMap!['burn_out']));
      addAttribute(charaId, AttributeType.defence, 5 * chara.getStatusIntensity(langMap!['burn_out']));
    }
    else if (status == langMap!['corroded']) {
      addAttribute(charaId, AttributeType.attack, 10 * chara.getStatusIntensity(langMap!['corroded']));
    }
    else if (status == langMap!['weakness']) {
      addAttribute(charaId, AttributeType.attack, 5 * chara.getStatusIntensity(langMap!['weakness']));
    }
    else if (status == langMap!['dreaming']) {
      if (isCharacterInGame(langMap!['valedictus'])) {
        castTrait(langMap!['valedictus'], [charaId], langMap!['nightmare_refrain'], {'type': 3});
      }
    }
    else if (status == langMap!['drowsy']) {
      addAttribute(charaId, AttributeType.attack, 5 * chara.getStatusIntensity(langMap!['drowsy']));
      addAttribute(charaId, AttributeType.defence, 5 * chara.getStatusIntensity(langMap!['drowsy']));
    }
    else if (status == langMap!['eden']) {
      addAttribute(charaId, AttributeType.attack, -3 * chara.getStatusIntensity(langMap!['eden']));
      removeHiddenStatus(charaId, 'apocalypse');
    }
    else if (status == langMap!['frozen']) {
      // 祝烨明【八裂】
      if (isCharacterInGame(langMap!['zhu_yeming'])) {
        castTrait(langMap!['zhu_yeming'], [charaId], langMap!['cryo_fissuring'], {'type': 1});
      }
      // 白谢【极寒环域】
      if (isCharacterInGame(langMap!['bai_xie'])) {
        castTrait(langMap!['bai_xie'], [charaId], langMap!['glacial_circle'], {'type': 2});
      }
    }
    else if (status == langMap!['dehydration']) {
      addAttribute(charaId, AttributeType.defence, 10 * chara.getStatusIntensity(langMap!['dehydration']));
    }
    else if (status == langMap!['submerged']) {
      addAttribute(charaId, AttributeType.attack, 10 * chara.getStatusIntensity(langMap!['submerged']));
    }

    _recordProvider!.addStatusRecord(getGameTurn(), emptyCharacter.id, charaId, status, 
    [chara.getStatusIntensity(status), chara.getStatusLayer(status)], [0, 0], '');
    chara.status.remove(status);
    _gameLogger!.addStatusLog(getGameTurn(), charaId, status, 0, 0);
    refresh();
  }

  // 更改状态层数
  void modifyStatusLayer(String charaId, String status, int layer) { 
    Character chara = players[charaId]!;

    if (!chara.hasStatus(status)) {return;}

    int modifiedLayer = layer;
    if (chara.getStatusLayer(status) + layer < 0) {
      modifiedLayer = -chara.getStatusLayer(status);    
    }

    _recordProvider!.addStatusRecord(getGameTurn(), emptyCharacter.id, charaId, status, 
    [chara.getStatusIntensity(status), chara.getStatusLayer(status)], [chara.getStatusIntensity(status), chara.getStatusLayer(status) + modifiedLayer], '');
    chara.status[status]![1] += modifiedLayer;
    _gameLogger!.addStatusLog(getGameTurn(), charaId, status, chara.getStatusIntensity(status), chara.getStatusLayer(status));
    refresh();
  }

  // 更改状态强度
  void modifyStatusIntensity(String charaId, String status, int intensity) {
    Character chara = players[charaId]!;

    if (!chara.hasStatus(status)) {return;}

    int modifiedIntensity = intensity;
    if (chara.getStatusIntensity(status) + intensity < 0) {
      modifiedIntensity = -chara.getStatusIntensity(status);    
    }

    if (status == langMap!['frost']) {
      addAttribute(charaId, AttributeType.attack, -4 * modifiedIntensity);
    }
    else if (status == langMap!['strength']) {
      addAttribute(charaId, AttributeType.attack, 5 * modifiedIntensity);
    }

    _recordProvider!.addStatusRecord(getGameTurn(), emptyCharacter.id, charaId, status, 
    [chara.getStatusIntensity(status), chara.getStatusLayer(status)], [chara.getStatusIntensity(status) + modifiedIntensity, chara.getStatusLayer(status)], '');
    chara.status[status]![0] += modifiedIntensity;
    _gameLogger!.addStatusLog(getGameTurn(), charaId, status, chara.getStatusIntensity(status), chara.getStatusLayer(status));
    refresh();
  }

  // 添加隐藏状态
  void addHiddenStatus(String charaId, String status, int intensity, int layer){
    Character chara = players[charaId]!;
    bool isImmune = false;
    if(!isImmune){
      try{
        if (status == 'dark') {
          if (chara.getHiddenStatusIntensity('dark') + intensity > 10) {
            chara.hiddenStatus[status]![0] = 10;
            addAttribute(charaId, AttributeType.attack, 2 * (10 - chara.getHiddenStatusIntensity('dark')));
          }
          else {
            chara.hiddenStatus[status]![0] += intensity;
            addAttribute(charaId, AttributeType.attack, 2 * intensity);
          }
        }
        else if (status == 'light_elf') {
          if (chara.getHiddenStatusIntensity('light_elf') + intensity > chara.getHiddenStatusIntensity('light')) {
            chara.hiddenStatus[status]![0] = chara.getHiddenStatusIntensity('light');
          }
          else {
            chara.hiddenStatus[status]![0] += intensity;
          }
        }
        else if (status == 'light') {
          if (chara.getHiddenStatusIntensity('light') + intensity > 5) {
            chara.hiddenStatus[status]![0] = 5;            
          }
          else {
            chara.hiddenStatus[status]![0] += intensity;
          }
        }
        else if ({'damageplus', 'hero_legend', 'dream_shelter', 'clover', 'flover', 'annihilate', 'alcohol', 'celestial', 
          'dreaming', 'forbidden','shade', 'night', 'collective', 'destiny', 'rage'}.contains(status)){
          chara.hiddenStatus[status]![0] += intensity;
        }
        else {
          chara.hiddenStatus[status]![1] += layer;
        }
      }
      catch (e){
        chara.hiddenStatus[status] = [intensity, layer, playerCount, 0];        
        if (status == 'yearning_atk') {
          addAttribute(charaId, AttributeType.attack, intensity);
        }
        else if (status == 'yearning_def') {
          addAttribute(charaId, AttributeType.defence, intensity);
        }
        else if (status == 'air_lock') {
          chara.maxCard = 3;
        }
        else if (status == 'spirit_bind') {
          addAttribute(charaId, AttributeType.attack, -10);
          addAttribute(charaId, AttributeType.defence, -10);
        }
        else if (status == 'dream_force') {
          addAttribute(charaId, AttributeType.attack, 30);
          addAttribute(charaId, AttributeType.defence, 30);
        }
        else if (status == 'dark') {
          addAttribute(charaId, AttributeType.attack, 2 * intensity);
        }
        else if (status == 'sacrifice') {
          addAttribute(charaId, AttributeType.attack, 5 * intensity);
          addAttribute(charaId, AttributeType.defence, 5 * intensity);
        }
        else if (status == 'slayer') {
          addAttribute(charaId, AttributeType.attack, 10);
        }
      }
    }
    refresh();
  }

  // 移除隐藏状态
  void removeHiddenStatus(String charaId, String status){ 
    Character chara = players[charaId]!;

    if (!chara.hasHiddenStatus(status)) {return;}

    if (status == 'undying') {
      addAttribute(charaId, AttributeType.armor, -400);
      if (chara.armor < 0) chara.armor = 0;
    }
    else if (status == 'velocity') {
      addHiddenStatus(charaId, 'anti_velocity', 0, 1);
    }
    else if (status == 'hema') {
      addAttribute(charaId, AttributeType.attack, -15);
    }
    else if (status == 'yearning_atk') {
      addAttribute(charaId, AttributeType.attack, -chara.hiddenStatus[status]![0]);
    }
    else if (status == 'yearning_def') {
      addAttribute(charaId, AttributeType.defence, -chara.hiddenStatus[status]![0]);
    }
    else if (status == 'touched') {
      countdown.deftTouchSkill = '';
      countdown.deftTouchTarget = '';
    }
    else if (status == 'annihilate') {
      addHiddenStatus(charaId, 'cycle', chara.getHiddenStatusIntensity(status), 1);
    }
    else if (status == 'air_lock') {
      chara.maxCard = chara.getHiddenStatusIntensity('air_lock');
    }
    else if (status == 'spirit_bind') {
      addAttribute(charaId, AttributeType.attack, 10);
      addAttribute(charaId, AttributeType.defence, 10);
    }
    else if (status == 'dream_force') {
      addAttribute(charaId, AttributeType.attack, -30);
      addAttribute(charaId, AttributeType.defence, -30);
    }
    else if (status == 'sacrifice') {
      addAttribute(charaId, AttributeType.attack, -5 * chara.getHiddenStatusIntensity(status));
      addAttribute(charaId, AttributeType.defence, -5 * chara.getHiddenStatusIntensity(status));
      damagePlayer('empty', charaId, 250, DamageType.lost);
    }
    else if (status == 'slayer') {
      addAttribute(charaId, AttributeType.attack, -10);
    }
    chara.hiddenStatus.remove(status);
    refresh();
  }

  // 更改隐藏状态层数
  void modifyHiddenStatusLayer(String charaId, String status, int layer){ 
    Character chara = players[charaId]!;

    if (!chara.hasHiddenStatus(status)) {return;}

    chara.hiddenStatus[status]![1] += layer;
    refresh();
  }

  // 更改隐藏状态强度
  void modifyHiddenStatusIntensity(String charaId, String status, int intensity){
    Character chara = players[charaId]!;

    if (!chara.hasHiddenStatus(status)) {return;}

    if (status == 'dark') {
      addAttribute(charaId, AttributeType.attack, 2 * intensity);
    }

    chara.hiddenStatus[status]![0] += intensity;
    refresh();
  }

  // 记录掷骰事件
  int throwDice(String source, String target, int point, DiceType type, [Map<String, dynamic>? args]) {
    Character sourceChara = players[source]!;
    // Character targetChara = players[target]!;
    int modifiedPoint = point;
    // 图西乌【蚀月】
    if (target == langMap!['tussiu'] && type == DiceType.action) {
      castTrait(target, [target], langMap!['eclipse'], {'type': 0, 'point': point});
    }
    // 雷刚【斩神】
    if (source == langMap!['lei_gang'] && type == DiceType.action) {
      modifyHiddenStatusIntensity(source, 'deicide', point);
    }
    // 蒙德里安【禁忌知识】
    for (var chara in players.values) {
      if(chara.id == langMap!['mondrian'] && point >= 4) {
        castTrait(chara.id, [chara.id], langMap!['taboo_lore'], {'type': 0});
        break;
      }
    }        
    if (sourceChara.hasHiddenStatus('forbidden_minus') && type == DiceType.action) {
      modifiedPoint -= 1;
      removeHiddenStatus(source, 'forbidden_minus');
    }
    if (sourceChara.hasHiddenStatus('forbidden_plus') && type == DiceType.action) {
      modifiedPoint += 1;
      removeHiddenStatus(source, 'forbidden_plus');
    }
    // 星惑【众人的乌托邦】
    if (source == langMap!['seiwaku'] && type == DiceType.action) { 
      if (point >= 6) {
        castTrait(source, [source], langMap!['collective_utopia'], {'type': 1});
      }      
      if (type == DiceType.action) {
        List<int> pointRef = [modifiedPoint];
        castTrait(source, [source], langMap!['collective_utopia'], {'type': 0, 'pointRef': pointRef});
        modifiedPoint = pointRef[0];
      }      
    }
    // 亭歆雨【彼岸之金】
    if (source == langMap!['ting_xinyu'] && sourceChara.hasHiddenStatus('destiny') && type == DiceType.action) {
      modifiedPoint += sourceChara.getHiddenStatusIntensity('destiny');
      removeHiddenStatus(source, 'destiny');
    }
    // 状态【重伤】
    if (sourceChara.hasStatus(langMap!['wounded'])) {
      damagePlayer('empty', source, sourceChara.getStatusIntensity(langMap!['wounded']), DamageType.lost);
      modifyStatusLayer(source, langMap!['wounded'], -1);      
    }
    // 状态【不安】
    if (sourceChara.hasStatus(langMap!['uneasiness'])) {
      modifiedPoint -= sourceChara.getStatusIntensity(langMap!['uneasiness']);
      modifyStatusLayer(source, langMap!['uneasiness'], -1);      
    }
    // 道具【三叶草之祝】
    if (sourceChara.hasHiddenStatus('clover') && type == DiceType.action) {
      modifiedPoint += sourceChara.getHiddenStatusIntensity('clover');
      removeHiddenStatus(source, 'clover');
    }
    // 道具【四叶草之愿】
    if (sourceChara.hasHiddenStatus('flover') && type == DiceType.action) {
      modifiedPoint *= sourceChara.getHiddenStatusIntensity('flover');
      removeHiddenStatus(source, 'flover');
    }    
    // 图西乌【蚀月】
    if (target == langMap!['tussiu'] && type == DiceType.action) {
      List<int> pointRef = [modifiedPoint];
      castTrait(target, [target], langMap!['eclipse'], {'type': 1, 'pointRef': pointRef});            
      castTrait(target, [target], langMap!['eclipse'], {'type': 2, 'pointRef': pointRef});
      modifiedPoint = pointRef[0];
    }
    // 雷刚【斩神】
    if (sourceChara.getHiddenStatusIntensity('deicide') > 0 && type == DiceType.action) {
      modifiedPoint = sourceChara.getHiddenStatusIntensity('deicide');
    }
    if (modifiedPoint < 0) {
      modifiedPoint = 0;
    }
    return modifiedPoint;
  }

  // 使用技能
  void castSkill(String source, List<String> targets, String skill, [Map<String, dynamic>? args]){
    bool skillAble = true;
    int movePointCost = 0;
    Character sourceChara = players[source]!;
    List<Character> targetCharaList = targets.map((target) => players[target]!).toList();
    String target = targetCharaList.isEmpty ? '' : targetCharaList.first.id;
    Character targetChara = targetCharaList.isEmpty ? emptyCharacter : targetCharaList.first;
    Map<String, dynamic> skillData = args ?? {};
    // 技能发动条件
    // 仁慈
    if (skill == langMap!['benevolence']) {
      List<GameRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, source: source, 
        startTurn: getGameTurn(), endTurn: getGameTurn());
      if (damageRecords.isEmpty) {
        skillAble = false;
      }
      else {
        skillAble = false;
        for (var record in damageRecords) {
          DamageRecord damageRecord = record as DamageRecord;
          if (damageRecord.damage >= 100) {
            skillAble = true;
            break;
          }
        }
      }
    }
    // 相转移
    else if (skill == langMap!['phase_transition']) {
      List<GameRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source, 
        startTurn: getGameTurn(), endTurn: getGameTurn());
      if (damageRecords.isEmpty) {
        skillAble = false;
      }
    }
    // 阈限
    else if (skill == langMap!['threshold']) {
      List<GameRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source, 
        startTurn: getGameTurn(), endTurn: getGameTurn());
      if (damageRecords.isEmpty) {
        skillAble = false;
      }
      else {
        skillAble = false;
        for (var record in damageRecords) {
          DamageRecord damageRecord = record as DamageRecord;
          if (damageRecord.damage >= 250) {
            skillAble = true;
            break;
          }
        }
      }
    }
    // 追击
    else if (skill == langMap!['chase']) {
      List<GameRecord> actionRecords = _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
        target: target, startTurn: getGameTurn(), endTurn: getGameTurn());
      if (actionRecords.isEmpty) {
        skillAble = false;
      }
      if (targetChara.health > 300) {
        skillAble = false;
      }
    }
    // 不死
    else if (skill == langMap!['undying']) {
      if (sourceChara.health > 0) {
        skillAble = false;
      }
    }
    // 止杀
    else if (skill == langMap!['kill_ceasing']) {
      if (targetChara.damageDealtTurn < 200) {
        skillAble = false;
      }
    }
    // 黯星【屠杀】
    else if (skill == langMap!['massacre']) {
      List<GameRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, source: source, 
        startTurn: getGameTurn(), endTurn: getGameTurn());
      if (damageRecords.isEmpty) {
        skillAble = false;
      }
      else {
        skillAble = false;
        for (var record in damageRecords) {
          DamageRecord damageRecord = record as DamageRecord;
          if (damageRecord.damage >= 250) {
            skillAble = true;
            break;
          }
        }
      }
    }
    // 敏博士【异镜解构】
    else if (skill == langMap!['deconstruction']) {
      if (sourceChara.movePoint < 1) {
        skillAble = false;
      }
    }
    // 卿别【安魂乐章】
    else if (skill == langMap!['requiem']) {
      if (!targetChara.hasStatus(langMap!['dreaming'])) {
        skillAble = false;
      }
    }
    // 炎焕【赤焱炼狱】
    else if (skill == langMap!['crimson_inferno']) {
      if (targets.length > 3) {
        skillAble = false;
      }
    }
    // 斯威芬【造梦者】
    else if (skill == langMap!['dream_weaver']) {
      int point = skillData['point'];
      int dreamCount = sourceChara.getHiddenStatusIntensity('dreaming');      
      if ((dreamCount + 1) ~/ 2 < point) {
        skillAble = false;
      }
    }
    // 红烬【封焰的135秒】
    else if (skill == langMap!['sealed_flame_135_seconds']) {
      int flamingLayer = 0;
      for (var chara in players.values) {
        if (chara.hasStatus(langMap!['flaming'])) {
          flamingLayer += chara.getStatusLayer(langMap!['flaming']);
        }
      }
      if (flamingLayer < 6) {
        skillAble = false;
      }
      List<GameRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, source: source, 
        startTurn: getGameTurn(), endTurn: getGameTurn());
      if (damageRecords.isEmpty) {
        skillAble = false;
      }
    }
    // 叶姬【须臾】
    else if (skill == langMap!['emphemeral']) {
      String status = skillData['status'];
      if (status == '' || statusData![status][1] == 0) {
        skillAble = false;
      }
    }
    // 科亚特尔【天启之庭】
    else if (skill == langMap!['apocalyptic_court']) {
      if (targets.length > 3) {
        skillAble = false;
      }
    }
    // 祝烨明【八寒之七】
    else if (skill == langMap!['seventh_frost']) {
      String status = skillData['status'];
      if (status == '') {
        skillAble = false;
      }
    }
    // 方塔索【入梦之手】
    else if (skill == langMap!['dream_grasp']) {
      if (targets.length > 3) {
        skillAble = false;
      }
    }
    // 颜若卿【补给】
    else if (skill == langMap!['replenishment']) {
      if (sourceChara.health < 250 || sourceChara.cardCount < 1) {
        skillAble = false;
      }
    }
    // 白谢【冰灭的135小节】
    else if (skill == langMap!['icy_oblivion_135_bars']) {
      int frostLayer = 0;
      for (var chara in players.values) {
        if (chara.hasStatus(langMap!['frost'])) {
          frostLayer += chara.getStatusLayer(langMap!['frost']);
        }
      }
      if (sourceChara.health < 100 * targets.length - frostLayer * 50) {
        skillAble = false;
      }
      if (targets.length > 3 || targets.isEmpty){
        skillAble = false;
      }
    }
    else if (skill == langMap!['frost_shatter']) {
      if (targets.length > 2 || targets.isEmpty) {
        skillAble = false;
      }
    }
    // 冷却未转好
    if (sourceChara.skill.keys.contains(skill)){
      if (sourceChara.skill[skill]! > 0){
        skillAble = false;
      }
    }
    // 状态【混乱】【冰封】【梦境】【星牢】【造梦】
    if (sourceChara.hasStatus(langMap!['confusion']) || sourceChara.hasStatus(langMap!['frozen']) || 
          sourceChara.hasStatus(langMap!['dreaming']) || sourceChara.hasStatus(langMap!['stellar_cage']) ||
          sourceChara.hasStatus(langMap!['dream_crafting'])){
      skillAble = false;
    }
    // 技能【净化】
    if (skill == langMap!['purification']) {
      skillAble = true;
    }
    // 亭歆雨【彼岸之金】
    if (sourceChara.hasHiddenStatus('weird')) {
      skillAble = false;
    }
    // 沉默
    if (skillAble) {
      if (sourceChara.hasHiddenStatus('reticence')){
        sourceChara.skill[skill] = skillCooldown![skill];
        skillAble = false;
      }
    }
    // 玩家死亡
    if (sourceChara.isDead) {
      skillAble = false;
    }
    // 技能可用
    if (skillAble) {
      // 仁慈
      if (skill == langMap!['benevolence']) {
        int type = skillData['type'];
        if (type == 1) {
          addAttribute(source, AttributeType.card, 2);
        }
        else {
          healPlayer(source, source, sourceChara.maxHealth ~/ 5, DamageType.heal);
        }
        List<DamageRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, source: source, 
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
        int maxDamage = 0;
        for (var damageRecord in damageRecords) {
          if (damageRecord.damage > maxDamage) {
            maxDamage = damageRecord.damage;
          }
        }
        for (var damageRecord in damageRecords) {
          if (damageRecord.damage == maxDamage) {
            _recordProvider!.removeRecord(damageRecord);
            break;
          }          
        }
        addAttribute(target, AttributeType.health, maxDamage);
        addAttribute(target, AttributeType.dmgreceived, -maxDamage);
        addAttribute(source, AttributeType.dmgdealt, -maxDamage);        
      }
      // 相转移
      else if (skill == langMap!['phase_transition']) {
        Map<String, int> damageDealer = {};
        List<DamageRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source, 
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
        for (var record in damageRecords) {
          if (damageDealer.containsKey(record.source)) {
            damageDealer[record.source] = damageDealer[record.source]! + record.damage;
          }
          else {
            damageDealer[record.source] = record.damage;
          }
          _recordProvider!.removeRecord(record);
        }
        addAttribute(source, AttributeType.health, sourceChara.damageReceivedTurn);
        addAttribute(source, AttributeType.dmgreceived, sourceChara.damageReceivedTurn);
        for (var dmgSource in damageDealer.keys) {          
          addAttribute(dmgSource, AttributeType.dmgreceived, -damageDealer[dmgSource]!);
          damagePlayer(dmgSource, target, damageDealer[dmgSource]!, DamageType.physical);
        }
      }
      // 天国邮递员
      else if (skill == langMap!['heaven_delivery']) {        
        addHiddenStatus(target, 'heaven', 0, 1);
        addHiddenStatus(source, 'heaven', 0, 1);
        if (sourceChara.hasHiddenStatus('heaven')) {
          sourceChara.hiddenStatus['heaven']![2] += 1;
        }        
      }
      // 净化
      else if (skill == langMap!['purification']) {
        List<dynamic> statusKeys = targetChara.status.keys.toList();
        for (var stat in statusKeys) {
          if (![langMap!['teroxis'], langMap!['lumen_flare'], langMap!['erode_gelid']].contains(stat)) {
            removeStatus(target, stat);
          }          
        }
      }
      // 嗜血
      else if (skill == langMap!['blood_thirst']) {
        healPlayer(source, source, sourceChara.damageDealtTurn ~/ 2, DamageType.heal);
      }
      // 外星人
      else if (skill == langMap!['stellar']) {
        addStatus(target, langMap!['stellar_cage'], 0, 1);
      }
      // 恐吓
      else if (skill == langMap!['intimidation']) {
        int point = skillData['point'];
        if ({3, 6}.contains(point)) {
          addHiddenStatus(source, 'intimidation', 0, 1);
        }
      }
      // 阈限
      else if (skill == langMap!['threshold']) {
        List<DamageRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source, 
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
        int maxDamage = 0;
        String maxDmgSource = '';
        for (var record in damageRecords) {
          if (record.damage > maxDamage && {DamageType.action, DamageType.physical, DamageType.magical}.contains(record.damageType)) {
            maxDamage = record.damage;
            maxDmgSource = record.source;
          }
        }
        for (var record in damageRecords) {
          if (record.damage == maxDamage) {
            _recordProvider!.removeRecord(record);
            break;
          }          
        }
        addAttribute(source, AttributeType.health, maxDamage - 100);
        addAttribute(source, AttributeType.dmgreceived, -maxDamage);
        addAttribute(maxDmgSource, AttributeType.dmgdealt, -maxDamage);
      }
      // 强化
      else if (skill == langMap!['reinforcement']) {
        addHiddenStatus(source, 'reinforcement', 0, 1);
      }
      // 追击
      else if (skill == langMap!['chase']) {
        addHiddenStatus(source, 'extra', 0, 1);
        addHiddenStatus(source, 'chase', 0, 1);
        addHiddenStatus(target, 'chased', 0, 1);
      }
      // 沉默
      else if (skill == langMap!['reticence']) {
        addHiddenStatus(target, 'reticence', 0, 1);
      }
      // 奉献
      else if (skill == langMap!['devotion']) {
        int point = skillData['point'];
        damagePlayer('empty', source, 100 * point, DamageType.lost);
        healPlayer(source, target, 100 * point, DamageType.heal);
        if (point >= 2) {
          addAttribute(source, AttributeType.card, point - 1);
        }
      }
      // 屏障
      else if (skill == langMap!['barrier']) {
        addAttribute(source, AttributeType.armor, 150);
        addHiddenStatus(source, 'barrier', 0, -1);
      }
      // 镭射
      else if (skill == langMap!['laser']) {
        damagePlayer(source, target, 60, DamageType.physical);
        addStatus(target, langMap!['fragility'], 5, 1);
      }
      // 不死
      else if (skill == langMap!['undying']) {
        sourceChara.isDead = false;
        healPlayer(source, source, 200 - sourceChara.health, DamageType.revive);
        addAttribute(source, AttributeType.armor, 400);
        addHiddenStatus(source, 'undying', 0, 2);
      }
      // 止杀
      else if (skill == langMap!['kill_ceasing']) {
        if (targetChara.cardCount > 2) {
          addAttribute(target, AttributeType.card, -2);
          addAttribute(source, AttributeType.card, 2);
        }
        else {
          addAttribute(target, AttributeType.card, -targetChara.cardCount);
          addAttribute(source, AttributeType.card, targetChara.cardCount);
        }
        addStatus(target, langMap!['exhausted'], 1, 1);
      }
      // 灵能注入
      else if (skill == langMap!['psionia']) {
        damagePlayer('empty', source, 75, DamageType.lost);
      }
      // 镜像
      else if (skill == langMap!['inversion']) {
        addStatus(target, langMap!['mirror'], 0, 3);
        addHiddenStatus(target, 'mirror', 0, 3);
        modifyHiddenStatusIntensity(target, 'mirror', targetChara.damageReceivedTotal);
        // targetChara.hiddenStatus['mirror']![0] = targetChara.damageReceivedTotal;
      }
      // 分裂
      else if (skill == langMap!['fission']) {
        addHiddenStatus(source, 'fission', 0, 1);
        addHiddenStatus(target, 'fission_target', 0, 1);
      }
      // 透支
      else if (skill == langMap!['overdraw']) {
        addStatus(source, langMap!['burn_out'], 5, 1);
      }
      // 挑唆
      else if (skill == langMap!['instigation']) {
        Map<String, int> points = skillData['points'];
        Map<String, int> isInstigated = skillData['isInstigated'];
        for (var chara in players.values) {
          if (chara.id != source && chara.id != 'empty') {
            int point = points[chara.id]!;
            if (isInstigated[chara.id] == 0) {
              int damage = sourceChara.attack > chara.defence ? (sourceChara.attack - chara.defence) * point :                       
                5 + sourceChara.attack ~/ 10;
                damagePlayer(source, chara.id, damage, DamageType.physical);
            }
            else {
              Character nextChara = gameSequence.indexOf(chara.id) == gameSequence.length - 1 ? 
                players[gameSequence.first]! : players[gameSequence[gameSequence.indexOf(chara.id) + 1]]!;
              int damage = chara.attack > nextChara.defence ? (chara.attack - nextChara.defence) * point :                       
                5 + chara.attack ~/ 10;
              damagePlayer(chara.id, nextChara.id, damage, DamageType.physical);
            }
          }
        }
      }
      // 开阳
      else if (skill == langMap!['mizar']) {
        addAttribute(source, AttributeType.card, 1);
      }
      // 太阴
      else if (skill == langMap!['lunar']) {
        if (targetChara.cardCount < 2) {
          addAttribute(target, AttributeType.card, -targetChara.cardCount);
        }
        else {
          addAttribute(target, AttributeType.card, -2);
        }
      }
      // 博览
      else if (skill == langMap!['perusing']) {
        addAttribute(source, AttributeType.card, 1);
      }
      // 反重力
      else if (skill == langMap!['anti_gravity']) {
        countdown.antiGravity++;
      }
      // 奇点
      else if (skill == langMap!['singularity']) {
        damagePlayer('empty', target, 300, DamageType.lost);
      }
      // 魂怨
      else if (skill == langMap!['soul_rancor']) {
        for (var charaId in targets) {          
          damagePlayer(source, charaId, 50, DamageType.physical, isAOE: true);
        }
      }
      // 瞬影
      else if (skill == langMap!['flash_shade']) {
        addHiddenStatus(source, 'extra', 0, 1);
      }
      // 侵蚀
      else if (skill == langMap!['corrosion']) {
        addStatus(target, langMap!['corroded'], 3, 1);
      }
      // 逆转乾坤
      else if (skill == langMap!['karma_reversal']) {
        int tempHp = sourceChara.health;
        int tempMp = sourceChara.movePoint;
        int tempCard = sourceChara.cardCount;
        addAttribute(source, AttributeType.health, targetChara.health - sourceChara.health);
        addAttribute(source, AttributeType.movepoint, targetChara.movePoint - sourceChara.movePoint);
        addAttribute(source, AttributeType.card, targetChara.cardCount - sourceChara.cardCount);
        addAttribute(target, AttributeType.health, tempHp - targetChara.health);
        addAttribute(target, AttributeType.movepoint, tempMp - targetChara.movePoint);
        addAttribute(target, AttributeType.card, tempCard - targetChara.cardCount);
      }
      // 极速
      else if (skill == langMap!['velocity']) {
        addHiddenStatus(source, 'velocity', 0, 1);
      }
      // 空袭
      else if (skill == langMap!['airstrike']) {
        damagePlayer(source, target, 100, DamageType.physical);
        if (target == source || isTeammate(source, target)) {
          addAttribute(target, AttributeType.card, 2);
        }
      }
      // 黯星【屠杀】
      else if (skill == langMap!['massacre']) {
        addAttribute(source, AttributeType.attack, 10);
        healPlayer(source, source, 100, DamageType.heal);
        if (extra == 0) {
          addHiddenStatus(source, 'extra', 0, 1);
        }
      }
      // 恋慕【氤氲】
      else if (skill == langMap!['nebula_field']) {
        addStatus(target, langMap!['nebula'], 1, 2);
      }
      // 卿别【安魂乐章】
      else if (skill == langMap!['requiem']) {
        addHiddenStatus(target, 'requiem', 0, 2);
      }
      // 时雨【冰芒】
      else if (skill == langMap!['ice_splinter']) {
        damagePlayer(source, target, 80, DamageType.magical);
        if (targetChara.hasStatus(langMap!['frost'])) {
          addStatus(target, langMap!['frost'], 0, 1);
          modifyStatusIntensity(target, langMap!['frost'], 3);
        }
        else {
          addStatus(target, langMap!['frost'], 3, 1);
        }
      }
      // 敏博士【异镜解构】
      else if (skill == langMap!['deconstruction']) {
        addAttribute(source, AttributeType.card, 1);
      }
      // 炎焕【赤焱炼狱】
      else if (skill == langMap!['crimson_inferno']) {
        for (var tar in targets) {
          addStatus(tar, langMap!['flaming'], 5, 1);
        }
      }
      // 斯威芬【造梦者】
      else if (skill == langMap!['dream_weaver']) {
        int point = skillData['point'];
        sourceChara.hiddenStatus['dreaming']![0] -= (2 * point - 1);
        if (point == 1) {
          addHiddenStatus(source, 'dream_weave', 0, 1);
        }
        else if (point == 2) {
          addAttribute(source, AttributeType.card, 1);
        }
        else {
          addHiddenStatus(source, 'dream_force', 0, 2);
          for (var chara in players.values) {
            if (isEnemy(source, chara.id)) {
              addStatus(chara.id, langMap!['dreaming'], 0, 1);
            }            
          }
        }
      }
      // 红烬【封焰的135秒】
      else if (skill == langMap!['sealed_flame_135_seconds']) {
        List<GameRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, source: source, 
          startTurn: getGameTurn(), endTurn: getGameTurn());
        DamageRecord damageRecord = damageRecords.first as DamageRecord;
        for (var chara in players.values) {
          if (chara.hasStatus(langMap!['flaming']) && isEnemy(source, chara.id)) {
            damagePlayer(source, chara.id, (3 * damageRecord.damage) ~/ 2, DamageType.lost);
            removeStatus(chara.id, langMap!['flaming']);
          }
        }
      }
      // 余梦得【护梦者】
      else if (skill == langMap!['dream_keeper']) {
        addStatus(target, langMap!['slowness'], 1, 1);
        addStatus(target, langMap!['weakness'], 2, 1);
      }
      // 叶姬【须臾】
      else if (skill == langMap!['ephemeral']) {
        String status = skillData['status'];
        targetChara.status[status]![0] = targetChara.status[status]![0] * targetChara.status[status]![1];
        targetChara.status[status]![1] = 1;
      }
      // 太夕【谜渊漩涡】
      else if (skill == langMap!['abyssal_whirl']) {
        addHiddenStatus(source, 'abyss', 0, 1);
        addHiddenStatus(target, 'taunt', 0, 1);
      }
      // 科亚特尔【天启之庭】
      else if (skill == langMap!['apocalyptic_court']) {
        int point = skillData['point'];
        for (String tar in targets) {
          addStatus(tar, langMap!['eden'], point, 2);
        }
      }
      // 祝烨明【八寒之七】
      else if (skill == langMap!['seventh_frost']) {
        int point = skillData['point'];
        String status = skillData['status'];
        if (point >= targetChara.getStatusLayer(status)) {
          addStatus(target, langMap!['moisturize'], 0, targetChara.getStatusLayer(status));
          removeStatus(target, status);
        }
        else {
          addStatus(target, langMap!['moisturize'], 0, point);
          targetChara.status[status]![1] -= point;
        }
        damagePlayer('empty', source, 50 * point, DamageType.magical);
      }
      // 方塔索【入梦之手】
      else if (skill == langMap!['dream_grasp']) {
        for (var chara in players.values) {
          if (!chara.isDead && chara.id != 'empty' && !targets.contains(chara.id)) {
            addStatus(chara.id, langMap!['dreaming'], 0, 1);
          }
        }
      }
      // 龙宇澈【牺牲】
      else if (skill == langMap!['sacrifice']) {
        addHiddenStatus(source, 'sacrifice', sourceChara.getHiddenStatusIntensity('light_elf'), 2);
        sourceChara.hiddenStatus['light_elf']![0] = 0;
      }
      // 祝言夙【灵魂震荡】
      else if (skill == langMap!['soul_tremor']) {
        addHiddenStatus(target, 'soul_tremor', 0, 1);
      }
      // 雷刚【斩神】
      else if (skill == langMap!['deicide']) {
        damagePlayer('empty', source, sourceChara.health ~/ 5, DamageType.lost);
        addAttribute(source, AttributeType.armor, sourceChara.maxHealth ~/ 10);
        if (sourceChara.health > 300) {
          addHiddenStatus(source, 'slayer', 0, 1);
        }
        else {
          addHiddenStatus(source, 'deicide', 0, 1);
        }
      }
      // 颜若卿【补给】
      else if (skill == langMap!['replenishment']) {
        addAttribute(source, AttributeType.card, -1);
        addAttribute(target, AttributeType.card, 2);
        damagePlayer('empty', source, 250, DamageType.lost);        
        healPlayer(source, target, 250, DamageType.heal);
      }
      // 白谢【冰灭的135小节】
      else if (skill == langMap!['icy_oblivion_135_bars']) {
        int frostLayer = 0;
        for (var chara in players.values) {
          if (chara.hasStatus(langMap!['frost'])) {
            frostLayer += chara.getStatusLayer(langMap!['frost']);
          }
        }
        damagePlayer('empty', source, 100 * targets.length - 50 * frostLayer, DamageType.lost);
        for (var tar in targets) {
          addStatus(tar, langMap!['frozen'], 0, 1);
        }
      }
      // 沈姝华【奉献之爱】
      else if (skill == langMap!['sacrificial_love']) {
        for (var tar in targets) {
          addAttribute(tar, AttributeType.armor, 50);
          if (isTeammate(tar, source) || tar == source) {
            addAttribute(tar, AttributeType.armor, 50);
          }      
        }
      }
      // 祝烨诚【裁冰裂霜】
      else if (skill == langMap!['frost_shatter']) {
        for (var tar in targets) {
          var tarChara = players[tar]!;
          int frostLayer = !tarChara.hasStatus(langMap!['frost']) ? 0 : tarChara.getStatusLayer(langMap!['frost']);
          int frozenLayer = !tarChara.hasStatus(langMap!['frozen']) ? 0 : tarChara.getStatusLayer(langMap!['frozen']);
          int damage = 75 + 10 * frostLayer * tarChara.getStatusIntensity(langMap!['frost'])
            + 30 * frozenLayer;
          // _logger.d(tarChara.getStatusIntensity(langMap!['frost']));       
          damagePlayer(source, tar, damage, DamageType.physical);
          addStatus(tar, langMap!['dissociated'], 10, 1);
        }
      } 

      // 技能进入CD
      sourceChara.skill[skill] = skillCooldown![skill];      
      // 斯威芬【造梦者】
      if (skill == langMap!['dream_weaver']) {
        int point = skillData['point'];
        if (point == 2) {
          sourceChara.skill[skill] = sourceChara.skill[skill]! + 4;
        }
        else if (point == 3) {
          sourceChara.skill[skill] = sourceChara.skill[skill]! + 8;
        }
      }
      // 雷刚【斩神】
      else if (skill == langMap!['deicide']) {
        if (sourceChara.health < 300) {
          sourceChara.skill[skill] = sourceChara.skill[skill]! + 4;
        }
      }

      // 特质结算   
      // 妮卡欧【不倦的观测者】
      if (source == langMap!['neko']) {
        castTrait(source, [source], langMap!['tireless_observer'], {'skill': skill});
      }
      // 唐菁延【延光】
      else if (source == langMap!['tang_jingyan']) {
        if (target != source) {
          castTrait(source, [target], langMap!['lingering_light'], {'type': 0});
        }
        else {
          castTrait(source, [target], langMap!['lingering_light'], {'type': 1});
        }
      }
      // 好好先生【见面礼】
      else if (sourceChara.hasStatus(langMap!['gift'])) {
        damagePlayer('empty', source, 2 * sourceChara.attack, DamageType.magical);
        addStatus(source, langMap!['confusion'], 0, 2);
        removeStatus(source, langMap!['gift']);
      }
      // 阿波菲斯【毁灭暗影】
      if (isCharacterInGame(langMap!['apophis']) && sourceChara.hasStatus(langMap!['nightmare']) 
        && sourceChara.getHiddenStatusIntensity('night') < 3) {
        Character chara = players[langMap!['apophis']]!;
        if (sourceChara.hasStatus(langMap!['eden'])) {
          damagePlayer(chara.id, source, 20 + 40 * sourceChara.getStatusIntensity(langMap!['nightmare']), DamageType.magical);
          healPlayer(chara.id, chara.id, 10 + 20 * sourceChara.getStatusIntensity(langMap!['nightmare']), DamageType.heal);
        }
        else { 
          damagePlayer(chara.id, source, 10 + 20 * sourceChara.getStatusIntensity(langMap!['nightmare']), DamageType.magical);
          healPlayer(chara.id, chara.id, 5 + 10 * sourceChara.getStatusIntensity(langMap!['nightmare']), DamageType.heal);
        }
        addHiddenStatus(source, 'night', 1, -1);
        addHiddenStatus(chara.id, 'night', 1, -1);
        castTrait(chara.id, [source], langMap!['ruinous_shade'], {'type': 1});
      }

      // 唐亚德【清心的乌托邦】
      if (source == langMap!['tang_yade']) {
        castTrait(source, [source], langMap!['utopia_of_clarity'], {'type': 0});
      }
      
      // 记录技能
      _recordProvider!.addSkillRecord(getGameTurn(), source, targets, skill, skillData);
      _gameLogger!.addSkillLog(getGameTurn(), source, targets.toString(), skill, skillData.toString());
    }
  }

  // 使用特质
  void castTrait(String source, List<String> targets, String trait, [Map<String, dynamic>? args]){
    bool traitAble = true;
    int movePointCost = 0;
    Character sourceChara = players[source]!;
    List<Character> targetCharaList = targets.map((target) => players[target]!).toList();
    String target = targetCharaList.isEmpty ? '' : targetCharaList.first.id;
    Character targetChara = targetCharaList.isEmpty ? emptyCharacter : targetCharaList.first;
    Map<String, dynamic> traitData = args ?? {};
    // 特质触发条件
    // 茵竹【自勉】
    if (trait == langMap!['self_encouragement']) {
      int type = traitData['type'];      
      if (type == 0 && (sourceChara.health > sourceChara.maxHealth * 0.5 || sourceChara.health < 0 
      || sourceChara.hasHiddenStatus('encouragement'))){
        traitAble = false;
      }
    }
    // 黯星【决心】
    else if (trait == langMap!['resolution']) {
      if (sourceChara.health > 0) {
        traitAble = false;
      }
    }
    // 岚【天魔体】
    else if (trait == langMap!['demonic_avatar']) {
      if (sourceChara.health > sourceChara.maxHealth * 0.5) {
        traitAble = false;
      }
    }
    // 岚【血灵斩】
    else if (trait == langMap!['hema_slash']) {
      movePointCost = 1;
      if (sourceChara.cardCount < 1) {
        traitAble = false;
      }
    }
    // K97【二进制】
    else if (trait == langMap!['binary']) {
      int type = traitData['type'];
      if (type == 0 && sourceChara.health < 100) {
        traitAble = false;
      }
      else if (type == 2 && sourceChara.armor <= 0) {
        traitAble = false;
      }
    }
    // 安德宁【回旋曲】
    else if (trait == langMap!['rondo']) {
      if (sourceChara.damageDealtTurn > 150) {
        traitAble = false;
      }
    }
    // 扶风【大预言】
    else if (trait == langMap!['grand_prophecy']) {
      int type = traitData['type'];
      if (type == 1) {
        movePointCost = 1;
      }      
      if (sourceChara.hasHiddenStatus('grand_prophecy')) {
        traitAble = false;
      }
    }
    // 星凝【祝愿】
    else if (trait == langMap!['blessing']) {
      movePointCost = 1;
    }
    // 时雨【天霜封印】
    else if (trait == langMap!['arctic_seal']) {
      List<GameRecord> damageRecords =  _recordProvider!.getFilteredRecords(type: RecordType.damage, target: target, 
        startTurn: getPreviousGameTurn(), endTurn: getGameTurn());
      traitAble = false;
      for (var record in damageRecords) {
        DamageRecord damageRecord = record as DamageRecord;
        if (damageRecord.tag == 'frost') {
          traitAble = true;
        }
      }
    }
    // 赐弥【在云端】
    else if (trait == langMap!['upon_the_clouds']) {
      if (sourceChara.health > 0 || sourceChara.hasHiddenStatus('cloud')) {
        traitAble = false;
      }
    }
    // 舸灯【引渡】
    else if (trait == langMap!['ghost_ferry']) {
      int type = traitData['type'];
      if (type == 1) {
        movePointCost = 2;
      }
    }
    // 长霾【律令】
    else if (trait == langMap!['decree']) {
      movePointCost = 1;
      List<GameRecord> traitRecords =  _recordProvider!.getFilteredRecords(type: RecordType.trait, source: source,
        target: target, startTurn: GameTurn(round: 1, turn: 1, extra: 0), endTurn: getGameTurn());
      GameRecord? latestRecord = traitRecords.isEmpty ? null : traitRecords.last;
      if (latestRecord != null) {
        TraitRecord latestTraitRecord = latestRecord as TraitRecord;
        int type = traitData['type'];
        if (type == latestTraitRecord.params['type']) {
          traitAble = false;
        }
      }
      if (targetChara.hasHiddenStatus('non_flying') || targetChara.hasHiddenStatus('air_lock') ||
            targetChara.hasHiddenStatus('demon_seal') || targetChara.hasHiddenStatus('spirit_bind')) {
        traitAble = false;
      }
    }
    // 卿别【夜魇游吟】
    else if (trait == langMap!['nightmare_refrain']) {
      int type = traitData['type'];
      if (type == 0) {
        movePointCost = 1;
        if (targetChara.hasHiddenStatus('dream')) {
          traitAble = false;
        }
        List<GameRecord> actionRecords =  _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
          target: target, startTurn: getPreviousGameTurn(), endTurn: getGameTurn());
        if (actionRecords.isEmpty) {
          traitAble = false;
        }
      }
    }
    // 云津【云系祝乐】
    else if (trait == langMap!['celestial_joy']) {
      int type = traitData['type'];
      if (type == 0) {
        if (!sourceChara.hasHiddenStatus('celestial')) {
          traitAble = false;
        }
        if (sourceChara.getHiddenStatusIntensity('celestial') < 2) {
          traitAble = false;
        }
      }
      else if (type == 1) {
        movePointCost = 2;
        if (sourceChara.movePoint != sourceChara.maxMove) {
          traitAble = false;
        }
      }
    }
    // 炎焕【心炎】
    else if (trait == langMap!['cardio_blaze']) {
      movePointCost = 1;
    }
    // 樊求【游侠】
    else if (trait == langMap!['ranger']) {
      int type = traitData['type'];
      if (type == 0) {
        traitAble = false;
        if (!sourceChara.hasHiddenStatus('ranger_def')) {
          for (var chara in players.values) {
            if (gameType == GameType.team && isTeammate(source, chara.id) && !chara.isDead) {
              traitAble = true;
              break;
            }
          }
        }
      }
      else {        
        if (!sourceChara.hasHiddenStatus('ranger_atk')) {
          traitAble = true;
          for (var chara in players.values) {
            if (gameType == GameType.team && isTeammate(source, chara.id) && !chara.isDead) {
              traitAble = false;
              break;
            }
          }
        }
      }
    }
    // 斯威芬【梦的塑造】
    else if (trait == langMap!['crafting_of_dreams']) {
      int type = traitData['type'];
      if (type == 0) {
        movePointCost = 2;
        if (sourceChara.hasStatus(langMap!['dream_crafting'])) {
          traitAble = false;
        }
      }
      else if ((type == 1 || type == 2) && !sourceChara.hasStatus(langMap!['dream_crafting'])) {        
        traitAble = false;
      }
    }
    // 红烬【烈焰之体】
    else if (trait == langMap!['conflagration_avatar']) {
      int type = traitData['type'];
      if (type == 1) {
        List<GameRecord> actionRecords =  _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn());
        if (actionRecords.isEmpty) {
          traitAble = false;
        }
      }
      else if (type == 2) { 
        List<GameRecord> actionRecords =  _recordProvider!.getFilteredRecords(type: RecordType.action, target: source,
          startTurn: getGameTurn(), endTurn: getGameTurn());
        if (actionRecords.isEmpty) {
          traitAble = false;
        }
      }
    }
    // 余梦得【梦的守护】
    else if (trait == langMap!['guardian_of_dreams']) {
      int type = traitData['type'];
      if (type == 0) {
        List<ActionRecord> actionRecords =  _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<ActionRecord>();
        for (var record in actionRecords) {
          if (record.attacked == true) {
            traitAble = false;
            break;
          }
        }
      }
      else if (type == 1) {
        if (!sourceChara.hasStatus(langMap!['dream_guarding'])) {
          traitAble = false;
        }
      }
      else if (type == 2) {
        List<GameRecord> actionRecords =  _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn());
        for (var record in actionRecords) {
          ActionRecord actionRecord = record as ActionRecord;
          if (actionRecord.attacked == true) {
            traitAble = false;
            break;
          }
        }
        List<GameRecord> skillRecords =  _recordProvider!.getFilteredRecords(type: RecordType.skill, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn());
        if (skillRecords.isNotEmpty) {
          traitAble = false;
        }
      }
    }
    // 好好先生【见面礼】
    else if (trait == langMap!['introductory_gift']) {
      if (targetChara.hasHiddenStatus('intro_gift')) {
        traitAble = false;
      }
    }
    // 好好先生【深重情谊】
    else if (trait == langMap!['imposing_favor']) {
      if (playerCount - playerDiedCount <= 2) {
        traitAble = false;
      }
    }
    // 叶姬【永恒】
    else if (trait == langMap!['eternity']) {
      int point = traitData['point'];
      if (point > 0) {
        movePointCost = point - 1;
      }
      String status = traitData['status'];
      if (status == '' || statusData![status][1] == 0) {
        traitAble = false;
      }
    }
    // 太夕【黯灭】
    else if (trait == langMap!['dark_dissolution']) {
      int type = traitData['type'];
      if (type == 0) {
        movePointCost = 1;
      }
      else if (type == 1) {
        if (sourceChara.cardCount < 1) {
          traitAble = false;
        }
      }
    }
    // 太夕【吞噬之锁】
    else if (trait == langMap!['devouring_lock']) {
      if (sourceChara.getHiddenStatusIntensity('dark') < 2){
        traitAble = false;
      }
    }
    // 科亚特尔【拟造“伊甸园”】
    else if (trait == langMap!['artificial_eden']) {
      if (sourceChara.damageDealtTurn > 0) {
        traitAble = false;
      }
    }
    // 科亚特尔【善恶天平】
    else if (trait == langMap!['balance_of_light_and_shadow']) {
      traitAble = false;
      if (sourceChara.hasStatus(langMap!['eden']) && sourceChara.hasStatus(langMap!['nightmare'])) {
        traitAble = true;
      }
    }
    // 蒙德里安【禁忌知识】
    else if (trait == langMap!['taboo_lore']) {
      int type = traitData['type'];
      if ({1, 2}.contains(type)) {
        if (sourceChara.getHiddenStatusIntensity('forbidden') < 1) {
          traitAble = false;
        }
      }  
    }
    // 阿波菲斯【永夜无终】
    else if (trait == langMap!['endless_night']) {
      if (sourceChara.getHiddenStatusIntensity('night') < 9) {
        traitAble = false;
      }
    }
    // 红黎【红莲业火】
    else if (trait == langMap!['lotus_flame']) {
      int type = traitData['type'];
      if (type == 1 && !targetChara.hasStatus(langMap!['flaming'])) {        
        traitAble = false;        
      }      
    }
    // 红黎【冰火相融】
    else if (trait == langMap!['ice_fire_fusion']) {
      if (targetChara.hasStatus(langMap!['flaming'])) {
        traitAble = false;
      }
    }
    // 祝烨明【八裂】
    else if (trait == langMap!['cryo_fissuring']) {
      int type = traitData['type'];
      if (type == 0 && !targetChara.hasStatus(langMap!['moisturize'])) {
        traitAble = false;
      }
    }
    // 方塔索【神游】
    else if (trait == langMap!['astral_projection']) {
      int type = traitData['type'];
      if (type == 0 && !sourceChara.hasStatus(langMap!['dreaming'])) {
        traitAble = false;        
      }
    }
    // 龙宇澈【光耀】
    else if (trait == langMap!['radiance']) {
      int type = traitData['type'];
      if (type == 0) {
        if (sourceChara.cardCount < 1) {
          traitAble = false;
        }
        if (sourceChara.getHiddenStatusIntensity('light') <= sourceChara.getHiddenStatusIntensity('light_elf') && 
          sourceChara.getHiddenStatusIntensity('light') > 0) {
          traitAble = false;
        }
      }
      else if (type == 1) {
        if (!({2, 3, 4}.contains(sourceChara.getHiddenStatusIntensity('light')) && 
          sourceChara.health <= sourceChara.maxHealth - 200 * (sourceChara.getHiddenStatusIntensity('light') - 1))) {
          traitAble = false;
        }
      }
    }
    // 龙宇澈【燃魂】
    else if (trait == langMap!['soul_burning']) {
      if (sourceChara.hasHiddenStatus('soul_burning')) {
        traitAble = false;
      }
    }
    // 祝言夙【精神干扰】
    else if (trait == langMap!['mental_disruption']) {
      if (!{1, gameSequence.length - 1}.contains((gameSequence.indexOf(source) - gameSequence.indexOf(target)) % gameSequence.length)) {
        traitAble = false;
      }
    }
    // 唐亚德【清心的乌托邦】
    else if (trait == langMap!['utopia_of_clarity']) {
      int type = traitData['type'];
      if (type == 1) {
        if (!sourceChara.hasHiddenStatus('clarity')) {
          traitAble = false;
        }
        if (sourceChara.getHiddenStatusIntensity('clarity') < 1) {
          traitAble = false;
        }
      }     
    }
    // 雷刚【决意的乌托邦】
    else if (trait == langMap!['utopia_of_resolve']) {
      int type = traitData['type'];
      if (type == 0 && (sourceChara.health > 300 || sourceChara.hasHiddenStatus('resolve'))) {
        traitAble = false;
      }
      else if (type == 2) {
        List<String> cardList = traitData['cardList'];
        traitAble = false;
        for (String card in cardList) {
          List<String> tagList = tagData![card];
          if (tagList.contains(langMap!['vital'])){
            traitAble = true;
            break;
          }
        }
      }
    }
    // 陆风【追猎的乌托邦】
    else if (trait == langMap!['utopia_of_celerity']) {
      int type = traitData['type'];
      if (type == 0 && (sourceChara.cardCount < 1 || targetChara.hasStatus(langMap!['prey']))) {
        traitAble = false;
      }
      else if (type == 1 && !targetChara.hasStatus(langMap!['prey'])) {
        traitAble = false;
      }
      else if (type == 2 && !targetChara.hasStatus(langMap!['prey'])) {
        traitAble = false;
      }
    }
    // 安山定【后发的乌托邦】
    else if (trait == langMap!['utopia_of_upspring']) {
      int type = traitData['type'];
      if (type == 0) { 
        List<ActionRecord> actionRecords =  _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<ActionRecord>();
        List<SkillRecord> skillRecords =  _recordProvider!.getFilteredRecords(type: RecordType.skill, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<SkillRecord>();
        if (actionRecords.isNotEmpty || skillRecords.isNotEmpty) {
          traitAble = false;
        }
      }
      else {
        if (!sourceChara.hasHiddenStatus('upspring')) {
          traitAble = false;
        }
      }
    }
    // 颜若卿【调和的乌托邦】
    else if (trait == langMap!['utopia_of_concord']) {
      int type = traitData['type'];
      if (type == 1) {
        traitAble = false;
        List<String> cardList = traitData['cardList'];
        for (String card in cardList) {
          if ({langMap!['filching'], langMap!['regenerating'], langMap!['curing'], langMap!['aurora_concussion'],
            langMap!['pandora_box'], langMap!['homology'], langMap!['invisibility_spell']}.contains(card)) {
            traitAble = true;
            break;
          }
        }        
      }
      else if (type == 2) {
        int damage = traitData['damage'];
        if (damage < 300) {
          traitAble = false;
        }
      }      
    }
    // 白谢【极寒环域】
    else if (trait == langMap!['glacial_circle']) {
      int type = traitData['type'];
      if (type == 0) {
        List<DamageRecord> damageRecords =  _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source,
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
        if (damageRecords.isEmpty) {
          traitAble = false;
        }
      }
    }
    // 图尔巴赫【生息】
    else if (trait == langMap!['life_breath']) {
      int type = traitData['type'];
      if (type == 0) {
        if (sourceChara.damageReceivedRound <= 300) {
          traitAble = false;
        }
      }
      else if (type == 1) {
        if (!sourceChara.hasHiddenStatus('breath')) {
          traitAble = false;
        }
      }
    }
    // 湍云【屏息】
    else if (trait == langMap!['hold_breath']) {
      int type = traitData['type'];
      if (type == 0 && (sourceChara.damageDealtRound >= 120 || sourceChara.damageDealtRound <= 0)) {
        traitAble = false;        
      }
      else if (type == 1 && !sourceChara.hasHiddenStatus('hold')) {
        traitAble = false;
      }
      else if (type == 2) {
        List<DamageRecord> damageRecords =  _recordProvider!.getFilteredRecords(type: RecordType.damage, source: source,
          startTurn: GameTurn(round: round, turn: 1, extra: 0), endTurn: getGameTurn()).cast<DamageRecord>();        
        for (DamageRecord damageRecord in damageRecords) {
          if (damageRecord.damageType == DamageType.action && damageRecord.damage > 0) {
            traitAble = false;
            break;
          }
        }        
      }
      else if (type == 3 && !sourceChara.hasHiddenStatus('holding')) {
        traitAble = false;
      }
    }
    // 湍云【惊弓】
    else if (trait == langMap!['gun_shy']) {
      int type = traitData['type'];
      if (type == 0 && sourceChara.damageDealtRound < 300) {
        traitAble = false;
      }
      else if (type == 1 && !sourceChara.hasHiddenStatus('gun_shy')) {
        traitAble = false;
      }
    }
    // 洛尔【不断燃烧的愤怒】
    else if (trait == langMap!['smoldering_rage']) {
      int type = traitData['type'];
      int rageIntensity = sourceChara.getHiddenStatusIntensity('rage') == -1 
        ? 0 : sourceChara.getHiddenStatusIntensity('rage');
      if (type == 0 && !(sourceChara.health < sourceChara.maxHealth - 200 * (rageIntensity + 1))) {
        traitAble = false;
      }
    }
    // 洛尔【毫无章法的进攻】
    else if (trait == langMap!['chaotic_strikes']) {
      int type = traitData['type'];
      int point = traitData['point'];
      if (type == 0 && point > 2) {
        traitAble = false;
      }
      else if (type == 1 && point < 3) {
        traitAble = false;
      }
    }
    // 奥菲莉娅【控水】
    else if (trait == langMap!['hydromancy']) {
      int type = traitData['type'];
      if (type == 0) {
        movePointCost = 1;
        if (targetChara.hasStatus(langMap!['submerged'])) {
          traitAble = false;
        }
      }
      else if (type == 1) {
        movePointCost = 1;
        if (targetChara.hasStatus(langMap!['dehydration'])) {
          traitAble = false;
        }
      }
    }
    // 奥菲莉娅【水之刑】
    else if (trait == langMap!['water_torture']) {
      int type = traitData['type'];
      if (type == 0) {
        movePointCost = 1;
        if (!targetChara.hasStatus(langMap!['submerged']) && !targetChara.hasStatus(langMap!['dehydration'])) {
          traitAble = false;
        }
      }
      else if (type == 1) {
        if (!targetChara.hasStatus(langMap!['asphyxia'])) {
          traitAble = false;
        }
      }
    }
    // EnGine-4【<04>质能转换】
    else if (trait == langMap!['mass_energy_conversion']) {
      int type = traitData['type'];
      if (type == 0) {        
        int damage = traitData['damage'];
        if (damage < 64) {
          traitAble = false;
        }
      }
      else if (type == 1 && sourceChara.damageDealtRound > 0) {        
        traitAble = false;
      }
      else if ((type == 2 || type == 3) && !sourceChara.hasHiddenStatus('conversion')) {
        traitAble = false;
      }
    }
    // 状态【混乱】【冰封】
    if (sourceChara.hasStatus(langMap!['confusion']) || sourceChara.hasStatus(langMap!['frozen'])) {
      traitAble = false;
    }
    // 状态【梦境】【星牢】
    if ((sourceChara.hasStatus(langMap!['dreaming']) || sourceChara.hasStatus(langMap!['stellar_cage'])) 
      && turn == gameSequence.indexOf(source)) {
      traitAble = false;
    }
    // 长霾【律令·禁空】
    if (sourceChara.hasHiddenStatus('non_flying')) {
      movePointCost++;
    }
    // 长霾【律令·封魔】
    if (sourceChara.hasHiddenStatus('demon_seal')) {
      traitAble = false;
    }
    // 亭歆雨【彼岸之金】
    if (sourceChara.hasHiddenStatus('strange')) {
      traitAble = false;
    }
    // 行动点不足
    if (movePointCost > sourceChara.movePoint) {
      traitAble = false;
    }
    // 永久可用特质
    if ({langMap!['resolution']}.contains(trait)) {
      traitAble = true;
    }
    // 玩家死亡
    if (sourceChara.isDead) {
      traitAble = false;
    }
    if (traitAble) {
      // 行动点减损
      if (movePointCost > 0) {
        addAttribute(source, AttributeType.movepoint, -movePointCost);
      }      
      // 茵竹【自勉】
      if (trait == langMap!['self_encouragement']) {
        int type = traitData['type'];
        if (type == 0) {
          healPlayer(source, source, (sourceChara.maxHealth * 0.8).toInt() - sourceChara.health, DamageType.heal);
          addHiddenStatus(source, 'encouragement', 0, -1);
        }
        else {          
          List<bool> isImmuneRef = traitData['isImmuneRef'];
          isImmuneRef[0] = true;
        }        
      }
      // 妮卡欧【不倦的观测者】
      else if (trait == langMap!['tireless_observer']) {
        String skill = traitData['skill'];
        sourceChara.skill[skill] = sourceChara.skill[skill]! - 1;
      }
      // 云云子【晨昏寥落】
      else if (trait == langMap!['dusk_void']) {
        List<double> baseDamageRef = traitData['baseDamageRef'];
        int attack = traitData['attack'];
        double attackMulti = traitData['attackMulti'];
        int point = traitData['point'];
        baseDamageRef[0] = (point - 1) * (attack - 30) * attackMulti;
      }
      // 星尘【幸运壁垒】
      else if (trait == langMap!['lucky_shield']) {
        String dmgSource = traitData['dmgSource'];
        int damage = traitData['damage'];
        int point = traitData['point'];
        if ({3, 6}.contains(point)) {
          addAttribute(source, AttributeType.health, damage);
          addAttribute(source, AttributeType.dmgreceived, -damage);
          addAttribute(dmgSource, AttributeType.dmgdealt, -damage);
        }
        List<DamageRecord> damageRecords =  _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source,
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
        for (DamageRecord damageRecord in damageRecords) {
          if (damageRecord.source == dmgSource && damageRecord.damage == damage) {
            _recordProvider!.removeRecord(damageRecord);
            break;
          }
        }
      }
      // 黯星【决心】
      else if (trait == langMap!['resolution']) {
        int point = traitData['point'];
        if ({1, 5, 6}.contains(point)) {
          addAttribute(source, AttributeType.health, 1 - sourceChara.health);
        }
        else {
          addHiddenStatus(source, 'res_failed', 0, 1);
        }
      }
      // 方寒【耀光爆裂】
      else if (trait == langMap!['radiant_blast']) {
        int point = traitData['point'];
        if ({4, 5}.contains(point)) {
          addStatus(target, langMap!['soul_flare'], 1, -1);
        }
        else if (point == 6) {
          addStatus(target, langMap!['soul_flare'], 2, -1);
        }
      }
      // 恪玥【咕了】
      else if (trait == langMap!['escaping']) {
        int point = traitData['point'];
        if ({3, 6}.contains(point)) {
          addStatus(source, langMap!['gugu'], 0, 1);
        }
      }
      // 岚【天魔体】
      else if (trait == langMap!['demonic_avatar']) {
        List<double> damageMultiRef = traitData['damageMultiRef'] ;
        damageMultiRef[0] = damageMultiRef[0] * 1.5;
      }
      // 岚【血灵斩】
      else if (trait == langMap!['hema_slash']) {
        addAttribute(source, AttributeType.card, -1);
        sourceChara.actionTime++;
        addHiddenStatus(source, 'hema', 0, 0);    
      }
      // 恋慕【勿忘我】
      else if (trait == langMap!['dont_forget_me']) {
        int type = traitData['type'];
        if (type == 0) {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] *= 3.3;
        }
        else if (type == 1) {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] *= 2.7;
        }
        else if (type == 2) {
          addAttribute(source, AttributeType.health, 1 - sourceChara.health);
          addHiddenStatus(source, 'forget_me', 0, 1);
        }
      }
      // K97【二进制】
      else if (trait == langMap!['binary']) {
        int type = traitData['type'];
        if (type == 0) {
          addAttribute(source, AttributeType.health, -100);
          addAttribute(source, AttributeType.armor, 100);
        }
        else if (type == 1) {
          addAttribute(source, AttributeType.health, sourceChara.armor);
          addAttribute(source, AttributeType.armor, -sourceChara.armor);
        }
        else if (type == 2) {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] *= 0.4;         
        }
      }
      // 安德宁【回旋曲】
      else if (trait == langMap!['rondo']) {
        addStatus(source, langMap!['dodge'], 0, 1);
      }
      // 卿别【夜魇游吟】
      else if (trait == langMap!['nightmare_refrain']) {
        int type = traitData['type'];
        if (type == 0) {
          addStatus(target, langMap!['dreaming'], 0, 1);
          addHiddenStatus(target, 'dream', 0, 2);
        }
        else if (type == 1) {
          addHiddenStatus(source, 'nightmare', 0, 0);
        }
        else if (type == 2) {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] = damageMultiRef[0] * 1.2;
        }
        else {
          addStatus(target, langMap!['drowsy'], 1, 1);
        }
      }
      // 扶风【大预言】
      else if (trait == langMap!['grand_prophecy']) {
        int point = traitData['point'];
        throwDice(target, target, point, DiceType.trait);
        addHiddenStatus(source, 'grand_prophecy', 0, 1);
      }
      // 奈普斯特【幽魂化】
      else if (trait == langMap!['spectralization']) {
        int type = traitData['type'];
        if (type == 0) {
          List<int> damageRef = traitData['damageRef'];
          damageRef[0] = 0;
        }
        else {
          List<dynamic> statusKeys = sourceChara.status.keys.toList();
          for (var stat in statusKeys) {
            removeStatus(source, stat);
          }
        }
      }
      // 奈普斯特【小惊吓】
      else if (trait == langMap!['little_spook']) {
        List<GameRecord> actionDamageRecords =  _recordProvider!.getFilteredRecords(type: RecordType.damage, 
          startTurn: GameTurn(round: round - 1, turn: 1, extra: 0), endTurn: getGameTurn());
        Set<String> actionSources = {};
        for (var record in actionDamageRecords) { 
          DamageRecord damageRecord = record as DamageRecord;
          if (damageRecord.damageType == DamageType.action && damageRecord.damage > 0) {
            actionSources.add(damageRecord.source);
          }
        }
        for (var chara in players.keys) {
          if (!actionSources.contains(chara)) {
            addStatus(chara, langMap!['uneasiness'], 1, 2);
          }
        }
      }
      // 星凝【希冀】
      else if (trait == langMap!['yearning']) {
        int type = traitData['type'];
        if (type == 0) {
          addHiddenStatus(target, 'yearning_atk', (sourceChara.damageDealtTurn * 0.1).toInt(), 1);
          
        }
        else {
          addHiddenStatus(target, 'yearning_def', (sourceChara.damageDealtTurn * 0.1).toInt(), 1);
        }
      }
      // 星凝【祝愿】
      else if (trait == langMap!['blessing']) {
        healPlayer(source, target, 100, DamageType.heal);
        List<dynamic> statusKeys = targetChara.status.keys.toList();
        for (var stat in statusKeys) {
          if (statusData![stat][0] == 1) {
            removeStatus(target, stat);
          }
        }
      }
      // 时雨【天霜封印】
      else if (trait == langMap!['arctic_seal']){
        int point = traitData['point'];
        if ({1, 3, 6}.contains(point)) {
          addStatus(target, langMap!['frozen'], 0, 1);
          if (targetChara.hasStatus(langMap!['frozen'])) {
            // 此处是为了平衡回合结束时，冰封状态的层数减少，否则轮到该玩家时，冰封状态已经结束
            targetChara.status[langMap!['frozen']]![2]++;
          }
        }
      }
      // 时雨【寒冰血脉】
      else if (trait == langMap!['icy_blood']){
        int type = traitData['type'];
        if (type == 0) {
          List<bool> isImmuneRef = traitData['isImmuneRef'];
          isImmuneRef[0] = true;
        }
        else {
          List<int> damagePlusRef = traitData['damagePlusRef'];
          if (targetChara.hasStatus(langMap!['frost'])) {
            damagePlusRef[0] = damagePlusRef[0] - 30 * targetChara.getStatusIntensity(langMap!['frost']);
          }
        }
      }
      // 图西乌【凌日】
      else if (trait == langMap!['transit']) {
        List<int> damagePlusRef = traitData['damagePlusRef'];
        List<double> damageMultiRef = traitData['damageMultiRef'];
        damagePlusRef[0] = 0;
        damageMultiRef[0] = 1;
      }
      // 图西乌【蚀月】
      else if (trait == langMap!['eclipse']) {
        int type = traitData['type'];
        if (type == 0) {
          int point = traitData['point'];
          addHiddenStatus(source, 'eclipse', point, 1);
        }
        else if (type == 1) {
          List<int> pointRef = traitData['pointRef'];
          if (sourceChara.hasHiddenStatus('eclipse')) {
            pointRef[0] = sourceChara.getHiddenStatusIntensity('eclipse');
            removeHiddenStatus(source, 'eclipse');
          }          
        }
        else {
          List<int> pointRef = traitData['pointRef'];
          if (pointRef[0] > 5) {
            pointRef[0] = 5;
          }
        }        
      }
      // 舸灯【引渡】
      else if (trait == langMap!['ghost_ferry']) {
        int type = traitData['type'];
        if (type == 0) {
          List<int> costRef = traitData['costRef'];
          costRef[0] -= 1;
        }
        else {
          addAttribute(source, AttributeType.card, 2);
          addHiddenStatus(source, 'ferry', 0, 1);
        }
      }
      // 赐弥【在云端】
      else if (trait == langMap!['upon_the_clouds']) {
        int sourceSeq = gameSequence.indexOf(source) + 1;
        bool findHistory = false;

        for (int i = _historyProvider!.currentHistoryIndex; i >= 0; i--) {
          String history = _historyProvider!.getStateAt(i);
          Map<String, dynamic> gameState = jsonDecode(history);
          if (gameState['turn'] == sourceSeq) {
            findHistory = true;
          }
          if (findHistory && gameState['turn'] == (sourceSeq == 1 ? gameSequence.length : sourceSeq - 1)) {            
            String save = _historyProvider!.getStateAt(i + 1);
            Map<String, dynamic> saveState = jsonDecode(save);
            Map<String, dynamic> playersData = saveState['players'];
            addAttribute(source, AttributeType.health, playersData[source]['health'] - sourceChara.health);
            addAttribute(source, AttributeType.attack, playersData[source]['attack'] - sourceChara.attack);
            addAttribute(source, AttributeType.defence, playersData[source]['defence'] - sourceChara.defence);
            addAttribute(source, AttributeType.movepoint, playersData[source]['movePoint'] - sourceChara.movePoint);
            addAttribute(source, AttributeType.card, playersData[source]['cardCount'] - sourceChara.cardCount);
            sourceChara.skill = Map<String, int>.from(playersData[source]['skill']);
            sourceChara.status = Map<String, List<dynamic>>.from(playersData[source]['status']);
            addHiddenStatus(source, 'cloud', 0, 1);
            break;
          }
        }
      }
      // 高淼【轻捷妙手】
      else if (trait == langMap!['deft_touch']) {
        int type = traitData['type'];
        if (type == 0) {
          addAttribute(source, AttributeType.card, 1);
        }
        else {
          String skill = traitData['skill'];
          countdown.deftTouchSkill = skill;
          countdown.deftTouchTarget = target;
          addHiddenStatus(target, 'touched', 0, 1);
        }
      }
      // 沫【湮灭性轮回】
      else if (trait == langMap!['annihilative_cycle']) {
        int type = traitData['type'];
        if (type == 0) {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] *= 2;
        }
        else {
          int damage = traitData['damage'];
          addHiddenStatus(target, 'annihilate', (damage * 0.4).toInt(), 1);
        }
      }
      // 长霾【我还能喝】
      else if (trait == langMap!['im_drunk']) {
        int type = traitData['type'];
        if (type == 0) {
          addHiddenStatus(source, 'alcohol', 50, -1);
        }
        else {
          int damage = traitData['damage'];
          addHiddenStatus(source, 'alcohol', (0.4 * damage).toInt(), -1);
          if (damage >= 300) {
            damagePlayer(source, target, sourceChara.getHiddenStatusIntensity('alcohol'), DamageType.physical);
            modifyHiddenStatusIntensity(source, 'alcohol', -sourceChara.getHiddenStatusIntensity('alcohol'));            
            addStatus(source, langMap!['weakness'], 1, 1);
            addStatus(target, langMap!['nausea'], 0, 2);
          }
        }
      }
      // 长霾【律令】
      else if (trait == langMap!['decree']) {
        int type = traitData['type'];
        if (type == 0) {
          addHiddenStatus(target, 'non_flying', 0, 1);
        }
        else if (type == 1) {
          addHiddenStatus(target, 'air_lock', targetChara.maxCard, 1);
        }
        else if (type == 2) {
          addHiddenStatus(target, 'demon_seal', 0, 1);
        }
        else {
          addHiddenStatus(target, 'spirit_bind', 0, 1);
        }        
      }
      // 云津【云系祝乐】
      else if (trait == langMap!['celestial_joy']) {
        int type = traitData['type'];
        if (type == 0) {
          int point = traitData['point'];
          if (point == 2) {
            addAttribute(source, AttributeType.movepoint, 1);
          }
          sourceChara.hiddenStatus['celestial']![0] -= 2;
        }
        else if (type == 1) {
          addAttribute(source, AttributeType.card, 1);
        }
        else {
          int movepoint = traitData['movepoint'];
          if (movepoint > 0) {
            addHiddenStatus(source, 'celestial', movepoint, -1);
          }
        }
      }
      // 晖夕【挑拣】
      else if (trait == langMap!['discerning']) {
        int point = traitData['point'];
        throwDice(source, source, point, DiceType.action);
      }
      // 唐菁延【延光】
      else if (trait == langMap!['lingering_light']) {
        int type = traitData['type'];
        if (type == 0) {
          if (targetChara.movePoint > 0) {
            addAttribute(target, AttributeType.movepoint, -1);
          }          
        }
        else {
          addAttribute(source, AttributeType.movepoint, 1);
        }
      }
      // 炎焕【心炎】
      else if (trait == langMap!['cardio_blaze']) {
        int point = traitData['point'];
        if ({2, 3, 4}.contains(point)) {
          for (var chara in players.values) {
            if (chara.id != source) {
              bool hasDebuff = false;
              for (var status in chara.status.keys) {  
                if (statusData![status][0] == 1) {
                  hasDebuff = true;
                  break;
                }
              }              
              if (hasDebuff) {
                addStatus(chara.id, langMap!['inferno_fire'], 5, 1);
              }
            }
          }
        }
      }
      // 樊求【游侠】
      else if (trait == langMap!['ranger']) { 
        int type = traitData['type'];
        if (type == 0) {
          addAttribute(source, AttributeType.defence, 10);
          addHiddenStatus(source, 'ranger_def', 0, -1);
        }
        else {
          addAttribute(source, AttributeType.attack, 15);
          addHiddenStatus(source, 'ranger_atk', 0, -1);
        }
      }
      // 斯威芬【梦的塑造】
      else if (trait == langMap!['crafting_of_dreams']) { 
        int type = traitData['type'];
        if (type == 0) { 
          addAttribute(source, AttributeType.card, -1);
          addStatus(source, langMap!['dream_crafting'], 0, 1);
        }
        else if (type == 1) {
          removeStatus(source, langMap!['dream_crafting']);
        }
        else if (type == 2) {
          int point = traitData['point'];
          if ({1, 2, 6}.contains(point)) {
            addHiddenStatus(source, 'dreaming', 2, -1);
          }
          else  {
            addHiddenStatus(source, 'dreaming', 1, -1);
          }
        }
        else if (type == 3) {
          addHiddenStatus(source, 'nightmare', 0, 0);
        }
        else {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] *= 1.1;
        }
      }
      // 红烬【烈焰之体】
      else if (trait == langMap!['conflagration_avatar']) { 
        int type = traitData['type'];        
        if (type == 0) { 
          List<bool> isImmuneRef = traitData['isImmuneRef'];
          isImmuneRef[0] = true;          
        }
        else if (type == 1) {
          int point = traitData['point'];
          if ({2, 4, 5}.contains(point)) {
            List<GameRecord> actionRecords = _recordProvider!.getFilteredRecords(type: RecordType.action, source: source, 
              startTurn: getGameTurn(), endTurn: getGameTurn());
            for (var record in actionRecords) {
              ActionRecord actionRecord = record as ActionRecord;
              addStatus(actionRecord.target, langMap!['flaming'], 5, 3);     
            }
          }
        }
        else if (type == 2) {
          int point = traitData['point'];
          if ({2, 4, 5}.contains(point)) {
            List<GameRecord> actionRecords = _recordProvider!.getFilteredRecords(type: RecordType.action, target: source, 
              startTurn: getGameTurn(), endTurn: getGameTurn());
            for (var record in actionRecords) {
              ActionRecord actionRecord = record as ActionRecord;
              addStatus(actionRecord.source, langMap!['flaming'], 5, 3);     
            }
          }
        }
      }
      // 余梦得【梦的守护】
      else if (trait == langMap!['guardian_of_dreams']) {
        int type = traitData['type'];
        if (type == 0) {
          addStatus(source, langMap!['dream_guarding'], 0, 1);
        }
        else if (type == 1) {
          addHiddenStatus(source, 'dream_guard', 0, 1);
        }
        else if (type == 2) {
          if (sourceChara.skill.keys.contains(langMap!['dream_keeper'])) {
            sourceChara.skill[langMap!['dream_keeper']] = sourceChara.skill[langMap!['dream_keeper']]! - 1;
          }
        }
      }
      // 好好先生【见面礼】
      else if (trait == langMap!['introductory_gift']) { 
        addStatus(target, langMap!['gift'], 0, -1);
        addHiddenStatus(target, 'intro_gift', 0, -1);
      }
      // 好好先生【深重情谊】
      else if (trait == langMap!['imposing_favor']) {
        addHiddenStatus(target, 'favor', 0, 2);
      }
      // 叶姬【永恒】
      else if (trait == langMap!['eternity']) {
        int point = traitData['point'];
        String status = traitData['status'];
        if (point == 0) {
          addAttribute(source, AttributeType.movepoint, 1);
        }
        else {
          //targetChara.status[status]![1] += point;
          modifyStatusLayer(target, status, point);
        }
      }
      // 太夕【黯灭】
      else if (trait == langMap!['dark_dissolution']) {
        int type = traitData['type'];
        if (type == 0) {
          addHiddenStatus(source, 'dark', 1, -1);                  
        }
        else if (type == 1) {
          String card = traitData['card'];
          addAttribute(source, AttributeType.card, -1);
          if (tagData![card].length > 1){
            addHiddenStatus(source, 'dark', 2, -1);
          }
          else {
            addHiddenStatus(source, 'dark', 1, -1);
          }          
        }
      }
      // 太夕【吞噬之锁】
      else if (trait == langMap!['devouring_lock']) {         
        modifyHiddenStatusIntensity(source, 'dark', -2);
        damagePlayer(source, target, 100, DamageType.physical);
        healPlayer(source, source, 100, DamageType.heal);
        addStatus(target, langMap!['constraint'], 0, 1);
      }
      // 科亚特尔【拟造“伊甸园”】
      else if (trait == langMap!['artificial_eden']) { 
        addStatus(source, langMap!['sanctify'], 0, 1);
        addHiddenStatus(source, 'sanctify', 0, 1);
        if (sourceChara.hasHiddenStatus('sanctify')) {
          sourceChara.hiddenStatus['sanctify']![2] += 1;
        }
      }
      // 科亚特尔【善恶天平】
      else if (trait == langMap!['balance_of_light_and_shadow']) { 
        addHiddenStatus(source, 'balance_change', 0, 1);
      }
      // 蒙德里安【禁忌知识】
      else if (trait == langMap!['taboo_lore']) { 
        int type = traitData['type'];
        if (type == 0) { 
          addHiddenStatus(source, 'forbidden', 1, -1);
        }
        else if (type == 1) {           
          modifyHiddenStatusIntensity(source, 'forbidden', -1);
          if (targetChara.hasStatus(langMap!['eden'])) {
            removeStatus(target, langMap!['eden']);
            damagePlayer(source, source, 75, DamageType.physical);
          }
          else {
            addHiddenStatus(source, 'forbidden_plus', 0, 1);
            damagePlayer(source, target, 75, DamageType.physical);
          }     
        }
        else if (type == 2) {           
          modifyHiddenStatusIntensity(source, 'forbidden', -1);
          if (targetChara.hasStatus(langMap!['eden'])) {
            removeStatus(target, langMap!['eden']);
            damagePlayer(source, source, 75, DamageType.physical);
          }
          else {            
            addHiddenStatus(target, 'forbidden_minus', 0, 1);
            damagePlayer(source, target, 75, DamageType.physical);
          }          
        }
        else {
          int heal = traitData['heal'];
          healPlayer(target, source, heal, DamageType.heal);
        }
      }
      // 阿波菲斯【毁灭暗影】
      else if (trait == langMap!['ruinous_shade']) { 
        int type = traitData['type'];
        if (type == 0) { 
          if (!sourceChara.hasHiddenStatus('shade')) {
            addHiddenStatus(source, 'shade', 1, -1);
          }
          addStatus(target, langMap!['nightmare'], sourceChara.getHiddenStatusIntensity('shade'), 2);
          addHiddenStatus(target, 'night', 0, -1);
        }
        else if (type == 1) { 
          castTrait(source, targets, langMap!['endless_night']);
          for (var chara in players.values) {
            if (chara.id == langMap!['mondrian'] && !chara.isDead) {              
              if (targetChara.hasStatus(langMap!['eden'])) {
                castTrait(chara.id, [source], langMap!['taboo_lore'], {'type': 3, 'heal': 6 + 12 * targetChara.getStatusIntensity(langMap!['nightmare'])});                              
              } 
              else {
                castTrait(chara.id, [source], langMap!['taboo_lore'], {'type': 3, 'heal': 3 + 6 * targetChara.getStatusIntensity(langMap!['nightmare'])});              
              }
              castTrait(source, targets, langMap!['ruinous_shade'], {'type': 2, 'damage': 30 * chara.getHiddenStatusIntensity('forbidden')}); 
              break;
            }
          }
        }
        else {
          int damage = traitData['damage'];
          damagePlayer(source, target, damage, DamageType.magical);
        }
      }
      // 阿波菲斯【永夜无终】
      else if (trait == langMap!['endless_night']) { 
        addHiddenStatus(source, 'shade', 1, -1);
        //addAttribute(target, AttributeType.attack, -5);
        //addAttribute(target, AttributeType.defence, -5);
        //targetChara.hiddenStatus['night']![0] %= 1024;
        modifyHiddenStatusIntensity(source, 'night', -sourceChara.getHiddenStatusIntensity('night'));
      }
      // 红黎【红莲业火】
      else if (trait == langMap!['lotus_flame']) { 
        int type = traitData['type'];
        if (type == 0) { 
          addStatus(target, langMap!['flaming'], 5, 1);
        }
        else if (type == 1) {
          int tag = traitData['tag'];
          addHiddenStatus(target, 'lotus', tag, 1);
        }
      }
      // 红黎【冰火相融】
      else if (trait == langMap!['ice_fire_fusion']) { 
        List<double> damageMultiRef = traitData['damageMultiRef'];
        damageMultiRef[0] *= 1.5;
      }
      // 祝烨明【八裂】
      else if (trait == langMap!['cryo_fissuring']) { 
        int type = traitData['type'];
        if (type == 0) { 
          int layers = traitData['damage'] ~/ 100;
          if (layers >= targetChara.getStatusLayer(langMap!['moisturize'])) {
            addStatus(target, langMap!['frozen'], 0, targetChara.getStatusLayer(langMap!['moisturize']));
            removeStatus(target, langMap!['moisturize']);
          }
          else {
            addStatus(target, langMap!['frozen'], 0, layers);
            modifyStatusLayer(target, langMap!['moisturize'], -layers);
            // targetChara.status[langMap!['moisturize']]![1] -= layers;
          }
        }
        else {
          damagePlayer(source, target, targetChara.maxHealth ~/ 8, DamageType.physical);
        }
      }
      // 方塔索【神游】
      else if (trait == langMap!['astral_projection']) { 
        int type = traitData['type'];
        if (type == 0) {          
          addHiddenStatus(source, 'astral', 0, 1);
        }
        else if (type == 1) { 
          List<int> damagePlusRef = traitData['damagePlusRef'];
          damagePlusRef[0] += 40;
        }
        else {
          addHiddenStatus(source, 'nightmare', 0, 1);
        }
      }
      // 龙宇澈【光耀】
      else if (trait == langMap!['radiance']) { 
        int type = traitData['type'];
        if (type == 0) { 
          if (!sourceChara.hasHiddenStatus('light')) {
            addHiddenStatus(source, 'light', 2, -1);
          }
          addAttribute(source, AttributeType.card, -1);
          addHiddenStatus(source, 'light_elf', 1, -1);
        }
        else if (type == 1) { 
          int intensity = (sourceChara.maxHealth - sourceChara.health) ~/ 200 + 2 - sourceChara.getHiddenStatusIntensity('light');
          addHiddenStatus(source, 'light', intensity, -1);
        }
        else {
          String dmgSource = traitData['dmgSource'];
          int damage = traitData['damage'];
          int point = traitData['point'];
          if (point <= sourceChara.getHiddenStatusIntensity('light_elf')) {
            addAttribute(source, AttributeType.health, damage);
            addAttribute(source, AttributeType.dmgreceived, -damage);
            addAttribute(dmgSource, AttributeType.dmgdealt, -damage);
          }
          List<DamageRecord> damageRecords =  _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source,
            startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
          for (DamageRecord damageRecord in damageRecords) {
            if (damageRecord.source == dmgSource && damageRecord.damage == damage) {
              _recordProvider!.removeRecord(damageRecord);
              break;
            }
          }
        }
      }
      // 龙宇澈【燃魂】
      else if (trait == langMap!['soul_burning']) { 
        if (sourceChara.hasHiddenStatus('light')) {
          addHiddenStatus(source, 'soul_burning', 0, -1);
        }        
      }
      // 祝言夙【精神干扰】
      else if (trait == langMap!['mental_disruption']) { 
        int point = traitData['point'];
        if ({3, 4}.contains(point)) {
          addHiddenStatus(target, 'disruption', 0, 1);
        }
      }
      // 星惑【众人的乌托邦】
      else if (trait == langMap!['collective_utopia']) { 
        int type = traitData['type'];
        if (type == 0) {
          List<int> pointRef = traitData['pointRef'];
          int pointPlus = 1;
          for (var chara in players.values) {
            if (isTeammate(source, chara.id) && !chara.isDead) {              
              pointPlus += 1;
            }
            if (chara.id == langMap!['long_yuche'] && chara.hasHiddenStatus('light_elf')) {
              pointPlus += chara.getHiddenStatusIntensity('light_elf');
            }
          }
          if (sourceChara.hasHiddenStatus('collective')) {
            pointPlus += sourceChara.getHiddenStatusIntensity('collective');
          }          
          pointRef[0] += pointPlus; 
        }
        else {
          addHiddenStatus(source, 'collective', 1, -1);
        }        
      }
      // 唐亚德【清心的乌托邦】
      else if (trait == langMap!['utopia_of_clarity']) { 
        int type = traitData['type'];
        if (type == 0) { 
          addHiddenStatus(source, 'clarity', 1, -1);
        }
        else if (type == 1) { 
          modifyHiddenStatusIntensity(source, 'clarity', -1);
          damagePlayer(source, target, 80, DamageType.physical);
        }
        else {
          for (var skill in sourceChara.skill.keys) {
            if (sourceChara.skill[skill]! > 0) {
              sourceChara.skill[skill] =  sourceChara.skill[skill]! - 1;
            }            
          }
        }
      }
      // 雷刚【决意的乌托邦】
      else if (trait == langMap!['utopia_of_resolve']) { 
        int type = traitData['type'];
        if (type == 0) { 
          addAttribute(source, AttributeType.armor, 100);
          addHiddenStatus(source, 'barrier', 0, -1);
          addHiddenStatus(source, 'resolve', 0, -1);
        }
        else if (type == 1) { 
          List<String> cardList = traitData['cardList'];
          if (sourceChara.health < 300) {
            for (String card in cardList) {
              List<String> tagList = tagData![card];
              if (tagList.contains(langMap!['vital'])){
                addAttribute(source, AttributeType.armor, 50);
              }
            }
          }
          else {
            for (String card in cardList) {
              List<String> tagList = tagData![card];
              if (tagList.contains(langMap!['vital']) || tagList.contains(langMap!['sharp'])){
                damagePlayer('empty', source, 100, DamageType.lost);
              }
            }
          }          
        }
        else { 
          removeHiddenStatus(source, 'rest');
        }
      }
      // 陆风【追猎的乌托邦】
      else if (trait == langMap!['utopia_of_celerity']) { 
        int type = traitData['type'];
        if (type == 0) { 
          addStatus(target, langMap!['prey'], 0, -1);
          addAttribute(source, AttributeType.card, -1);
        }
        else if (type == 1) { 
          List<double> damageMultiRef = traitData['damageMultiRef'];
          addAttribute(source, AttributeType.movepoint, 1);
          damageMultiRef[0] *= 1.2;
        }
        else { 
          addHiddenStatus(target, 'prey', 0, 1);
          removeStatus(target, langMap!['prey']);
        }
      }
      // 安山定【后发的乌托邦】
      else if (trait == langMap!['utopia_of_upspring']) { 
        int type = traitData['type'];
        if (type == 0) {
          addStatus(source, langMap!['poised'], 0, 1);
          sourceChara.status[langMap!['poised']]![2] += 1;
          addHiddenStatus(source, 'upspring', 0, -1);
        }
        else {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] *= 0.75;          
        }        
      }
      // 颜若卿【调和的乌托邦】
      else if (trait == langMap!['utopia_of_concord']) { 
        int type = traitData['type'];
        if (type == 0) { 
          List<int> costRef = traitData['costRef'];
          List<String> cardList = traitData['cardList'];
          for (String card in cardList) {
            List<String> tagList = tagData![card];
            if (tagList.contains(langMap!['vital'])){
              costRef[0] -= 1;
            }
          }          
        }
        else if (type == 1) { 
          List<int> costRef = traitData['costRef'];
          costRef[0] = 0;
        }
        else { 
          addStatus(source, langMap!['regeneration'], 3, 1);
          addAttribute(source, AttributeType.card, 1);
        }
      }
      // 亭歆雨【彼岸之金】
      else if (trait == langMap!['aurelysium']) { 
        List<String> cardList = traitData['cardList'];
        Set<String> tagSet = {};        
        for (var card in cardList) { 
          List<String> tagList = tagData![card];
          tagSet.addAll(tagList);
        }
        if (tagSet.length < 5) {
          for (var card in cardList) {
            List<String> tagList = tagData![card];
            for (var tag in tagList) { 
              if (tag == langMap!['sharp']) {
                addAttribute(source, AttributeType.attack, 5);
              }
              else if (tag == langMap!['protect']) {
                addAttribute(source, AttributeType.defence, 5);
              }
              else if (tag == langMap!['vital']) {
                healPlayer(source, source, 50, DamageType.heal);
              }
              else if (tag == langMap!['destiny']) {
                addHiddenStatus(source, 'destiny', 1, 1);
              }
              else if (tag == langMap!['mystique']) {
                for (var status in sourceChara.status.keys) {
                  if (statusData![status][0] == 0) {
                    modifyStatusLayer(source, status, 1);
                    // sourceChara.status[status]![1] += 1;
                  }
                }
              }
              else if (tag == langMap!['phantom']) {
                addAttribute(source, AttributeType.card, 1);
              }
              else if (tag == langMap!['magic']) {
                removeStatus(target, langMap!['dodge']);
                addAttribute(target, AttributeType.armor, -targetChara.armor);
              }
              else if (tag == langMap!['weird']) {
                addHiddenStatus(target, 'weird', 0, 1);
              }
              else if (tag == langMap!['disorder']) {
                addAttribute(target, AttributeType.movepoint, -1);
              }
              else if (tag == langMap!['sense']) {
                addAttribute(source, AttributeType.movepoint, 1);
              }
              else if (tag == langMap!['heat']) {
                damagePlayer(source, target, 30, DamageType.magical);
              }
              else if (tag == langMap!['chill']) {
                addStatus(target, langMap!['frost'], 1, 1);
              }
            }
          }
        }
        else {
          for (var card in cardList) {
            List<String> tagList = tagData![card];
            for (var tag in tagList) { 
              if (tag == langMap!['sharp']) {
                addAttribute(source, AttributeType.attack, 10);
              }
              else if (tag == langMap!['protect']) {
                addAttribute(source, AttributeType.defence, 10);
              }
              else if (tag == langMap!['vital']) {
                healPlayer(source, source, 100, DamageType.heal);
              }
              else if (tag == langMap!['destiny']) {
                addHiddenStatus(source, 'destiny', 2, 1);
              }
              else if (tag == langMap!['mystique']) {
                for (var status in sourceChara.status.keys) {
                  if (statusData![status][0] == 0) {
                    modifyStatusLayer(source, status, 2);
                    //sourceChara.status[status]![1] += 2;
                  }
                }
              }
              else if (tag == langMap!['phantom']) {
                addAttribute(source, AttributeType.card, 2);
              }
              else if (tag == langMap!['magic']) {
                removeStatus(target, langMap!['dodge']);
                addAttribute(target, AttributeType.armor, -targetChara.armor);
                for (var status in targetChara.status.keys.toList()) {
                  if (statusData![status][0] == 0) {
                    removeStatus(target, status);
                  }
                }
              }
              else if (tag == langMap!['weird']) {
                addHiddenStatus(target, 'weird', 0, 1);
                addHiddenStatus(target, 'strange', 0, 1);
              }
              else if (tag == langMap!['disorder']) {
                addAttribute(target, AttributeType.movepoint, -2);
              }
              else if (tag == langMap!['sense']) {
                addAttribute(source, AttributeType.movepoint, 2);
              }
              else if (tag == langMap!['heat']) {
                damagePlayer(source, target, 60, DamageType.magical);
              }
              else if (tag == langMap!['chill']) {
                addStatus(target, langMap!['frost'], 2, 1);
              }
            }
          }
        }
      }
      // 白谢【极寒环域】
      else if (trait == langMap!['glacial_circle']) { 
        int type = traitData['type'];
        if (type == 0) { 
          int point = traitData['point'];
          if ({2, 4, 5}.contains(point)) {
            List<DamageRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source, 
              startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
            for (var record in damageRecords) {
              if ({DamageType.action, DamageType.physical}.contains(record.damageType)) {
                addAttribute(record.target, AttributeType.health, record.damage ~/ 2);
                addAttribute(record.target, AttributeType.dmgreceived, record.damage ~/ 2);
                addAttribute(record.source, AttributeType.dmgdealt, -record.damage ~/ 2);      
              }
              _recordProvider!.addDamageRecord(record.turn, record.source, record.target, record.damage ~/ 2, record.damageType, record.tag);
              _recordProvider!.removeRecord(record);
            }

            for (var tar in targets) {
              addStatus(tar, langMap!['frost'], 3, 1);
            }
          }          
        }
        else if (type == 1) { 
          addAttribute(target, AttributeType.attack, -2);
          addAttribute(target, AttributeType.defence, -3);
        }
        else {
          addAttribute(target, AttributeType.attack, -5);
          addAttribute(target, AttributeType.defence, -5);
        }
      }
      // 沈姝华【纯洁之爱】
      else if (trait == langMap!['innocent_love']) { 
        int type = traitData['type'];
        if (type == 0) { 
          List<String> cardList = traitData['cardList'];
          int cardOverlapped = 0;
          int maxOverlapped = 0;
          for (var tag in Tag.values) {
            cardOverlapped = 0;
            for (var card in cardList) {              
              List<String> tagList = tagData![card];
              if (tagList.contains(tag.tagId)) {
                cardOverlapped += 1;
              }
            }
            if (cardOverlapped > maxOverlapped) {
              maxOverlapped = cardOverlapped;
            }
          }
          List<int> costRef = traitData['costRef'];          
          costRef[0] -= (maxOverlapped - 1);
        }
        else {
          addAttribute(source, AttributeType.card, 1);
        }
      }
      // 图尔巴赫【生息】
      else if (trait == langMap!['life_breath']) { 
        int type = traitData['type'];
        if (type == 0) { 
          addHiddenStatus(source, 'breath', 0, 1);
        }
        else if (type == 1) { 
          for (var tar in targets) {
            damagePlayer(source, tar, 50, DamageType.lost);
            healPlayer(source, source, 50, DamageType.heal);
          }
          removeHiddenStatus(source, 'breath');
        }
      }
      // 图尔巴赫【破土】
      else if (trait == langMap!['earth_break']) { 
        List<String> cardList = traitData['cardList'];
        for (String card in cardList) {
          List<String> tagList = tagData![card];
          if (tagList.contains(langMap!['vital'])) {
            for (var tar in targets) {
              addStatus(tar, langMap!['tear'], 50, 1);
            }
          }
        }
      }
      // 湍云【屏息】
      else if (trait == langMap!['hold_breath']) { 
        int type = traitData['type'];
        if (type == 0) { 
          addHiddenStatus(source, 'hold', 0, 1);
        }
        else if (type == 1) { 
          addStatus(source, langMap!['charge'], 0, 1);
          modifyStatusIntensity(source, langMap!['charge'], 25);
          removeHiddenStatus(source, 'hold');
        }
        else if (type == 2) {
          addHiddenStatus(source, 'holding', 0, 1);
        }
        else { 
          addStatus(source, langMap!['charge'], 0, 1);
          modifyStatusIntensity(source, langMap!['charge'], 40);
          removeHiddenStatus(source, 'holding');
        }
      }
      // 湍云【惊弓】
      else if (trait == langMap!['gun_shy']) { 
        int type = traitData['type'];
        if (type == 0) { 
          addHiddenStatus(source, 'gun_shy', 0, 1);
        }
        else if (type == 1) { 
          addStatus(source, langMap!['uneasiness'], 1, 1);
          removeHiddenStatus(source, 'gun_shy');     
        }
      }
      // 洛尔【不断燃烧的愤怒】
      else if (trait == langMap!['smoldering_rage']) { 
        int type = traitData['type'];
        if (type == 0) { 
          int rageIntensity = targetChara.getHiddenStatusIntensity('rage') == -1 
            ? 0 : targetChara.getHiddenStatusIntensity('rage');
          addAttribute(source, AttributeType.attack, 5 * ((targetChara.maxHealth - targetChara.health) ~/ 200 - rageIntensity));
          addHiddenStatus(source, 'rage', ((targetChara.maxHealth - targetChara.health) ~/ 200 - rageIntensity), -1);                  
        }
        else{ 
          addStatus(source, langMap!['wounded'], 50, 1);
        }
      }
      // 洛尔【毫无章法的进攻】
      else if (trait == langMap!['chaotic_strikes']) { 
        int type = traitData['type'];
        if (type == 0) { 
          addStatus(target, langMap!['unbalanced'], targetChara.attack * 3, 1);
        }
        else { 
          addAttribute(target, AttributeType.maxhp, -targetChara.getStatusIntensity(langMap!['unbalanced']));          
          modifyStatusLayer(target, langMap!['unbalanced'], -1);
          if (targetChara.maxHealth < targetChara.health) {
            damagePlayer('empty', target, targetChara.health - targetChara.maxHealth, DamageType.lost);
            addStatus(target, langMap!['confusion'], 0, 1);
            addHiddenStatus(source, 'unbalanced', 0, 1);
          }
        }
      }
      // 奥菲莉娅【控水】
      else if (trait == langMap!['hydromancy']) { 
        int type = traitData['type'];
        if (type == 0) { 
          addStatus(target, langMap!['dehydration'], 1, 2);
        }
        else if (type == 1) { 
          addStatus(target, langMap!['submerged'], 1, 2);
        }
      }
      // 奥菲莉娅【水之刑】
      else if (trait == langMap!['water_torture']) { 
        int type = traitData['type'];
        if (type == 0) { 
          int point = traitData['point'];
          addStatus(target, langMap!['asphyxia'], point, 1);
          removeStatus(target, langMap!['dehydration']);
          removeStatus(target, langMap!['submerged']);
        }
        else if (type == 1) { 
          damagePlayer('empty', target, 50 * targetChara.getStatusIntensity(langMap!['asphyxia']), DamageType.lost);
          removeStatus(target, langMap!['asphyxia']);
        }
      }
      // EnGine-4【<04>质能转换】
      else if (trait == langMap!['mass_energy_conversion']) { 
        int type = traitData['type'];
        if (type == 0) { 
          int damage = traitData['damage'];
          switch (damage) {
            case >= 244:
              healPlayer(source, source, 17 * (sourceChara.maxHealth - sourceChara.health) ~/ 50, DamageType.heal);
              break;
            case >= 124:
              healPlayer(source, source, 6 * (sourceChara.maxHealth - sourceChara.health) ~/ 25, DamageType.heal);
              break;
            case >= 64:
              healPlayer(source, source, 7 * (sourceChara.maxHealth - sourceChara.health) ~/ 50, DamageType.heal);
              break;
          }
        }
        else if (type == 1){
          addHiddenStatus(source, 'conversion', 0, 1);
        }
        else if (type == 2){
          addAttribute(source, AttributeType.card, 2);
        }
        else {
          if (targetChara.cardCount > 0) {
            addAttribute(source, AttributeType.card, 1);
            addAttribute(target, AttributeType.card, -1);
          }
        }
      }
      // 祝烨诚【凛息】
      else if (trait == langMap!['icy_stillness']) {
        int type = traitData['type'];
        if (type == 0) { 
          addStatus(target, langMap!['frost'], 2, 1);
        }
        else if (type == 1) {
          List<String> cardList = traitData['cardList'];
          List<int> costRef = traitData['costRef'];
          for (String card in cardList) {
            List<String> tagList = tagData![card];
            if (tagList.contains(langMap!['chill']) || tagList.contains(langMap!['mystique'])) {
              costRef[0] -= 1;
            }
          }
        }
        else {          
          List<String> cardList = traitData['cardList'];
          for (String card in cardList) {
            List<String> tagList = tagData![card];
            if (tagList.contains(langMap!['chill']) || tagList.contains(langMap!['mystique'])) {
              addStatus(target, langMap!['frost'], 1, 1);
              modifyStatusIntensity(target, langMap!['frost'], 1);
            }
          }
        }
      }

      // 特质结算
      // 阿波菲斯【毁灭暗影】
      if (isCharacterInGame(langMap!['apophis']) && sourceChara.hasStatus(langMap!['nightmare']) 
        && sourceChara.getHiddenStatusIntensity('night') < 3) {
        Character chara = players[langMap!['apophis']]!;
        if (sourceChara.hasStatus(langMap!['eden'])) {
          damagePlayer(chara.id, source, 20 + 40 * sourceChara.getStatusIntensity(langMap!['nightmare']), DamageType.magical);
          healPlayer(chara.id, chara.id, 10 + 20 * sourceChara.getStatusIntensity(langMap!['nightmare']), DamageType.heal);
        }
        else { 
          damagePlayer(chara.id, source, 10 + 20 * sourceChara.getStatusIntensity(langMap!['nightmare']), DamageType.magical);
          healPlayer(chara.id, chara.id, 5 + 10 * sourceChara.getStatusIntensity(langMap!['nightmare']), DamageType.heal);
        }
        addHiddenStatus(source, 'night', 1, -1);
        addHiddenStatus(chara.id, 'night', 1, -1);
        castTrait(chara.id, [source], langMap!['ruinous_shade'], {'type': 1});
      }

      // 记录特质
      _recordProvider!.addTraitRecord(GameTurn(round: round, turn: turn, extra: extra), source, targets, 
      trait, traitData);
      _gameLogger!.addTraitLog(getGameTurn(), source, targets.toString(), trait, traitData.toString());
    }
  }

  void damagePlayer(String source, String target, int damage, DamageType type, {String tag = '', bool isAOE = false}){ 
    Character sourceChara = players[source]!;
    Character targetChara = players[target]!;
    int damagePlus = 0;
    double damageMulti = 1;
    // 加伤相关道具
    if (targetChara.hasHiddenStatus('damageplus') && type == DamageType.action) {
      damagePlus += targetChara.getHiddenStatusIntensity('damageplus');
      removeHiddenStatus(target, 'damageplus');
      }
    // 道具【终焉长戟】
    if (targetChara.hasHiddenStatus('end') && type == DamageType.action) {
      for (int i = 0; i < targetChara.getHiddenStatusIntensity('end'); i++) { 
        damageMulti *= 1.5;
      }      
      removeHiddenStatus(target, 'end');
      }
    // 道具【猎魔灵刃】
    if (targetChara.hasHiddenStatus('track') && type == DamageType.action) {
      for (int i = 0; i < targetChara.getHiddenStatusIntensity('track'); i++) {
        damageMulti *= 1.5;
      }      
      removeHiddenStatus(target, 'track');
    }
    // 道具【融甲宝珠】
    if (targetChara.hasHiddenStatus('penetrate') && type == DamageType.action) {
      for (int i = 0; i < targetChara.getHiddenStatusIntensity('penetrate'); i++) {
        damageMulti *= 1.5;
      }      
      removeHiddenStatus(target, 'penetrate');
    }
    // 图西乌【凌日】
    if (target == langMap!['tussiu'] && type == DamageType.action) {
      List<int> damagePlusRef = [damagePlus];
      List<double> damageMultiRef = [damageMulti];
      castTrait(target, [target], langMap!['transit'], {'damagePlusRef': damagePlusRef, 'damageMultiRef': damageMultiRef});
      damagePlus = damagePlusRef[0];
      damageMulti = damageMultiRef[0];
    }
    // 状态【氤氲】
    if (targetChara.hasStatus(langMap!['nebula']) && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      damageMulti *= (1.0 + 0.5 * targetChara.getStatusIntensity(langMap!['nebula']));      
    }
    // 状态【灵曜】
    if (targetChara.hasStatus(langMap!['soul_flare']) && {DamageType.action, DamageType.physical}.contains(type)) {
      damagePlus -= 80 * targetChara.getStatusIntensity(langMap!['soul_flare']);
      damagePlayer(target, source, 105 * targetChara.getStatusIntensity(langMap!['soul_flare']), DamageType.magical);
      removeStatus(target, langMap!['soul_flare']);
    }
    // 状态【骑虎难下】
    if(targetChara.hasStatus(langMap!['tigris_dilemma']) && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)){
      damageMulti *= 1.2;
    }
    // 状态【润化】
    if (targetChara.hasStatus(langMap!['moisturize']) && type == DamageType.action) {
      damagePlus -= 50;
    }
    // 状态【撕裂】
    if (targetChara.hasStatus(langMap!['tear']) && type == DamageType.action) {
      damagePlayer(source, target, targetChara.getStatusIntensity(langMap!['tear']), DamageType.lost);
      modifyStatusLayer(target, langMap!['tear'], -1);      
    }
    // 状态【蓄力】
    if (sourceChara.hasStatus(langMap!['charge']) && type == DamageType.action) {
      damagePlus += sourceChara.getStatusIntensity(langMap!['charge']);
      modifyStatusLayer(source, langMap!['charge'], -1);      
    }
    // 状态【造梦】
    if (targetChara.hasStatus(langMap!['dream_crafting']) && type == DamageType.action) {
      damageMulti *= 0.75;
    }
    // 技能【恐吓】
    if (targetChara.hasHiddenStatus('intimidation') && type == DamageType.action) {
      damageMulti *= 0.5;
    }
    // 技能【分裂】
    if (sourceChara.hasHiddenStatus('fission') && type == DamageType.action) {
      damageMulti *= 0.8;
    }
    // 卿别【安魂乐章】
    if (sourceChara.hasStatus('requiem') && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      damagePlus += 75;
    }
    // 斯威芬【造梦者】
    if (sourceChara.hasHiddenStatus('dream_weave') && type == DamageType.action) {
      damagePlayer(source, target, 50, DamageType.magical);
      addStatus(target, langMap!['dreaming'], 0, 1);
      removeHiddenStatus(source, 'dream_weave');
    }
    // 科亚特尔【天启之庭】
    if (targetChara.hasHiddenStatus('apocalypse') && {DamageType.action, DamageType.physical}.contains(type)) {
      damageMulti *= 0.75;
      removeHiddenStatus(target, 'apocalypse');
    }
    // 岚【天魔体】
    if (source == langMap!['windflutter'] && type == DamageType.action) {
      List<double> damageMultiRef = [damageMulti];      
      castTrait(source, [source], langMap!['demonic_avatar'], {'damageMultiRef': damageMultiRef});
      damageMulti = damageMultiRef[0];
    }
    // 恋慕【勿忘我】
    if (source == langMap!['loveless'] && type == DamageType.action) {
      List<double> damageMultiRef = [damageMulti];      
      castTrait(source, [source], langMap!['dont_forget_me'], {'damageMultiRef': damageMultiRef, 'type': 0});
      damageMulti = damageMultiRef[0];
    }    
    if (target == langMap!['loveless'] && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      List<double> damageMultiRef = [damageMulti];      
      castTrait(target, [target], langMap!['dont_forget_me'], {'damageMultiRef': damageMultiRef, 'type': 1});
      damageMulti = damageMultiRef[0];
    }
    // K97【二进制】
    if (target == langMap!['k97'] && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      List<double> damageMultiRef = [damageMulti];      
      castTrait(target, [target], langMap!['binary'], {'damageMultiRef': damageMultiRef, 'type': 2});
      damageMulti = damageMultiRef[0];
    }
    // 卿别【夜魇游吟】
    if (source == langMap!['valedictus'] && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      List<double> damageMultiRef = [damageMulti];
      if (targetChara.hasStatus(langMap!['dreaming'])) {
        castTrait(source, [source], langMap!['nightmare_refrain'], {'type': 2, 'damageMultiRef': damageMultiRef});
      }
      damageMulti = damageMultiRef[0];
    }
    // 时雨【寒冰血脉】
    if (target == langMap!['shigure'] && {DamageType.action, DamageType.physical}.contains(type)) {
      List<int> damagePlusRef = [damagePlus];
      castTrait(target, [source], langMap!['icy_blood'], {'type': 1, 'damagePlusRef': damagePlusRef});
      damagePlus = damagePlusRef[0];
    }
    // 舸灯【引渡】
    if (source == langMap!['gentou'] && type == DamageType.action) {
      if (sourceChara.hasHiddenStatus('ferry')) {
        damagePlus += 45;
        removeHiddenStatus(source, 'ferry');
      }
    }
    // 沫【湮灭性轮回】
    if (source == langMap!['froth'] && type == DamageType.action) {
      List<double> damageMultiRef = [damageMulti];
      castTrait(source, [target], langMap!['annihilative_cycle'], {'type': 0, 'damageMultiRef': damageMultiRef});
      damageMulti = damageMultiRef[0];
    }
    // 斯威芬【梦的塑造】
    if (source == langMap!['sweven'] && type == DamageType.action) {
      List<double> damageMultiRef = [damageMulti];
      if (targetChara.hasStatus(langMap!['dreaming'])) {
        castTrait(source, [source], langMap!['crafting_of_dreams'], {'type': 4, 'damageMultiRef': damageMultiRef});
      }
      damageMulti = damageMultiRef[0];
    }
    // 余梦得【梦的守护】
    if (isCharacterInGame(langMap!['yu_mengde']) && isTeammate(langMap!['yu_mengde'], target) 
      && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      Character chara = players[langMap!['yu_mengde']]!;
      castTrait(chara.id, [chara.id], langMap!['guardian_of_dreams'], {'type': 1});
      if (chara.hasHiddenStatus('dream_guard')) {        
        target = chara.id;
        targetChara = chara;
        removeHiddenStatus(chara.id, 'dream_guard');
      }
    }
    if (targetChara.hasStatus(langMap!['dream_guarding']) && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      damageMulti *= 0.8;
    }
    // 红黎【冰火相融】
    if (source == langMap!['dimpsy'] && type == DamageType.action) {
      List<double> damageMultiRef = [damageMulti];
      castTrait(source, [target], langMap!['ice_fire_fusion'], {'damageMultiRef': damageMultiRef});
      damageMulti = damageMultiRef[0];
    }
    // 方塔索【神游】
    if (target == langMap!['phantos'] && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      List<int> damagePlusRef = [damagePlus];
      castTrait(target, [target], langMap!['astral_projection'], {'type': 1, 'damagePlusRef': damagePlusRef});
      damagePlus = damagePlusRef[0];
    }
    // 陆风【追猎的乌托邦】
    if (source == langMap!['lu_feng'] && targetChara.hasStatus(langMap!['prey']) && type == DamageType.action) {
      List<double> damageMultiRef = [damageMulti];
      castTrait(source, [target], langMap!['utopia_of_celerity'], {'type': 1, 'damageMultiRef': damageMultiRef});
      damageMulti = damageMultiRef[0];
    }
    if (sourceChara.hasHiddenStatus('prey')) {
      damageMulti *= 0.8;
      removeHiddenStatus(source, 'prey');
    }
    // 安山定【后发的乌托邦】
    if (source == langMap!['an_shanding'] && type == DamageType.action && sourceChara.hasStatus(langMap!['poised'])) {
      damageMulti *= 2;
    }
    if (target == langMap!['an_shanding'] && targetChara.hasHiddenStatus('upspring')) {
      List<double> damageMultiRef = [damageMulti];
      castTrait(target, [target], langMap!['utopia_of_upspring'], {'type': 1, 'damageMultiRef': damageMultiRef});
      damageMulti = damageMultiRef[0];
    }
    // 洛尔【毫无章法的进攻】
    if (source == langMap!['lor'] && sourceChara.hasHiddenStatus('unbalanced') && type == DamageType.action) {
      damageMulti *= 0.5;
    }
    
    // 伤害计算
    damage = ((damage + damagePlus) * damageMulti).toInt();    
    
    // 状态【闪避】
    if(targetChara.hasStatus(langMap!['dodge']) && {DamageType.action, DamageType.physical}.contains(type)){
      if(!sourceChara.hasHiddenStatus('critical')){        
        addHiddenStatus(source, 'void', 0, 1);
      }
      removeStatus(target, langMap!['dodge']);
    }
    // 状态【咕咕】
    if(targetChara.hasStatus(langMap!['gugu'])){
      if(!sourceChara.hasHiddenStatus('critical')){        
        addHiddenStatus(source, 'void', 0, 1);
      }
    }
    // 状态【梦境】
    if (targetChara.hasStatus(langMap!['dreaming'])) {
      // 卿别【夜魇游吟】
      if (source == langMap!['valedictus']) {
        castTrait(source, [target], langMap!['nightmare_refrain'], {'type': 1});
      }
      // 斯威芬【梦的塑造】
      if (source == langMap!['sweven']) {
        castTrait(source, [target], langMap!['crafting_of_dreams'], {'type': 3});
      }
      // 方塔索【神游】
      if (source == langMap!['phantos']) {
        castTrait(source, [target], langMap!['astral_projection'], {'type': 2});
      }
      if (!sourceChara.hasHiddenStatus('critical') && !sourceChara.hasHiddenStatus('nightmare')) {        
        addHiddenStatus(source, 'void', 0, 1);
      }
    }
    // 太夕【谜渊漩涡】
    if (target == langMap!['nyxumbra'] && targetChara.hasHiddenStatus('abyss')){      
      int absorbedDamage = damage - 300;
      if (absorbedDamage > 0) {
        damage = 300;
        addHiddenStatus(target, 'dark', absorbedDamage ~/ 50, -1);
      }
    }
    // 奈普斯特【幽魂化】
    if (target == langMap!['nepst']) {
      if (isAOE) {
        List<int> damageRef = [damage];
        castTrait(target, [target], langMap!['spectralization'], {'type': 0, 'damageRef': damageRef});
        damage = damageRef[0];
      }                  
    }
    // 方塔索【神游】
    if (target == langMap!['phantos'] && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      castTrait(target, [target], langMap!['astral_projection'], {'type': 0});
      if (targetChara.hasHiddenStatus('astral')) {        
        addHiddenStatus(source, 'void', 0, 1);
        removeHiddenStatus(target, 'astral');
      }
    }
    
    // 不造成伤害
    /*if (sourceChara.hasHiddenStatus('rest') && type == DamageType.action) {
      damage = 0;
      removeHiddenStatus(source, 'rest');
    }*/
    if (sourceChara.hasHiddenStatus('void') && type == DamageType.action) {
      damage = 0;
      removeHiddenStatus(source, 'void');
    }
    if (damage < 0) {
      damage = 0;
    }
    // 伤害结算
    if (type == DamageType.action) {
      if (sourceChara.hasHiddenStatus('fission')) {
        Character fissionChara = emptyCharacter;
        for (var c in players.values) {
          if (c.hasHiddenStatus('fission_target')) {
            fissionChara = c;
            break;
          }
        }        
        removeHiddenStatus(source, 'fission');
        removeHiddenStatus(fissionChara.id, 'fission_target');
        damagePlayer(source, fissionChara.id, damage, DamageType.physical, isAOE: true);
      }
      if (targetChara.hasStatus(langMap!['fractured']) || sourceChara.hasHiddenStatus('critical')) {
        addAttribute(target, AttributeType.health, -damage);
        if (sourceChara.hasHiddenStatus('critical')) {removeHiddenStatus(source, 'critical');}
      }
      else {
        if (targetChara.armor > 0) {
          if (damage > targetChara.armor) {
            if (targetChara.hasHiddenStatus('barrier')) {
              addAttribute(target, AttributeType.armor, -targetChara.armor);
              removeHiddenStatus(target, 'barrier');
            }
            else {
              addAttribute(target, AttributeType.health, -damage + targetChara.armor);
              addAttribute(target, AttributeType.armor, -targetChara.armor);
            }              
          }
          else {
            addAttribute(target, AttributeType.armor, -damage);
          }
        }
        else {
          addAttribute(target, AttributeType.health, -damage);
        }
      }
    }
    else if (type == DamageType.physical) {
      if (targetChara.hasStatus(langMap!['fractured'])) {
        addAttribute(target, AttributeType.health, -damage);
      }
      else {
        if (targetChara.armor > 0) {
          if (damage > targetChara.armor) {
            if (targetChara.hasHiddenStatus('barrier')) {
              addAttribute(target, AttributeType.armor, -targetChara.armor);
              removeHiddenStatus(target, 'barrier');
            }
            else {
              addAttribute(target, AttributeType.health, -damage + targetChara.armor);
              addAttribute(target, AttributeType.armor, -targetChara.armor);
            }              
          }
          else {
            addAttribute(target, AttributeType.armor, -damage);
          }
        }
        else {
          addAttribute(target, AttributeType.health, -damage);
        }
      }
    }
    else if (type == DamageType.magical) {
      addAttribute(target, AttributeType.health, -damage);
    }
    else if (type == DamageType.lost) {
      addAttribute(target, AttributeType.health, -damage);
    }
    
    // 技能【镜像】
    if (targetChara.hasHiddenStatus('mirror')) {
      if (targetChara.damageReceivedTotal - targetChara.getHiddenStatusIntensity('mirror') > 300) {
        removeStatus(target, langMap!['mirror']);
        removeHiddenStatus(target, 'mirror');
      }
    }
    // 沫【湮灭性轮回】
    if (source == langMap!['froth'] && type == DamageType.action) {
      castTrait(source, [target], langMap!['annihilative_cycle'], {'type': 1, 'damage': damage});
    }
    // 长霾【我还能喝】
    if (target == langMap!['sumoggu']) {
      castTrait(target, [source], langMap!['im_drunk'], {'type': 1, 'damage': damage});
    }
    // 祝烨明【八裂】
    if (source == langMap!['zhu_yeming']) {
      castTrait(source, [target], langMap!['cryo_fissuring'], {'type': 0, 'damage': damage});
    }
    // 颜若卿【调和的乌托邦】
    if (target == langMap!['yan_ruoqing']) {
      castTrait(target, [target], langMap!['utopia_of_concord'], {'type': 2, 'damage': damage});
    }
    // EnGine-4【<04>质能回收】
    if (source == langMap!['engine_4']) {
      castTrait(source, [target], langMap!['mass_energy_conversion'], {'type': 0, 'damage': damage});
    }

    // 伤害统计
    if (damage > 0) {
      addAttribute(source, AttributeType.dmgdealt, damage);
      addAttribute(target, AttributeType.dmgreceived, damage);
      _recordProvider!.addDamageRecord(GameTurn(round: round, turn: turn, extra: extra), 
        source, target, damage, type, tag);
      _gameLogger!.addDamageLog(getGameTurn(), source, target, damage, type, 
        'damagePlus: $damagePlus, damageMulti: $damageMulti');
    }    
    refresh();
  }

  void healPlayer(String source, String target, int heal, DamageType type, {String tag = '', bool isAOE = false}) {
    // Character sourceChara = players[source]!;
    Character targetChara = players[target]!;
    int healPlus = 0;
    double healMulti = 1;
    bool healAble = true;

    if (targetChara.hasStatus(langMap!['dissociated'])) {
      healMulti *= (1 - 0.1 * targetChara.getStatusIntensity(langMap!['dissociated']));
    }

    heal = ((heal + healPlus) * healMulti).toInt();

    if (type == DamageType.heal){
      // 龙宇澈【燃魂】
      if (target == langMap!['long_yuche']) {
        castTrait(target, [target], langMap!['soul_burning']);
        if (targetChara.hasHiddenStatus('soul_burning')) {
          healAble = false;
        }
      }
      // 雷刚【决意的乌托邦】
      if (target == langMap!['lei_gang']) {
        healAble = false;
      }
      if (healAble) {
        
        addAttribute(target, AttributeType.health, heal);
      }
    }
    else if (type == DamageType.revive) {
      targetChara.health += heal;
    }

    // 治疗统计
    if (heal > 0 && healAble) {
      addAttribute(source, AttributeType.dmgdealt, heal);
      addAttribute(target, AttributeType.dmgreceived, heal);
      _recordProvider!.addHealRecord(GameTurn(round: round, turn: turn, extra: extra), 
        source, target, heal, type, tag);
      _gameLogger!.addHealLog(getGameTurn(), source, target, heal);
    }    
    refresh();
  }

  // 结束轮次
  void endTurn(){
    // 设置游戏状态为进行中
    if (gameState == GameState.waiting) {
      gameState = GameState.start;
    }
    // 获取当前角色
    String currentCharaId;
    if (turn == 0) {
      currentCharaId = gameSequence[0];
    }
    else {
      currentCharaId = gameSequence[turn - 1];
    }
    Character currentChara = players[currentCharaId]!;        

    if (turn != 0) {
    // 全局状态结算
    if (turn == playerCount && !currentChara.hasHiddenStatus('extra')) {
      // 达摩克利斯之剑
      for (; countdown.reinforcedDamocles > 0; countdown.reinforcedDamocles--) {
        Character maxHpChara = players[currentCharaId]!;
        int maxHp = maxHpChara.health;
        for(Character target in players.values){ 
          if(target.health > maxHp){
            maxHp = target.health;
            maxHpChara = target;
          }          
        }
        damagePlayer('empty', maxHpChara.id, 300, DamageType.magical);        
      }
      for (; countdown.damocles > 0; countdown.damocles--) {
        Character maxHpChara = players[currentCharaId]!;
        int maxHp = maxHpChara.health;
        for(Character target in players.values){
          if(target.health > maxHp){
            maxHp = target.health;
            maxHpChara = target;            
          }          
        }
        damagePlayer('empty', maxHpChara.id, 150, DamageType.magical);      
      }        
    }

    // 状态结算
    // 霜冻
    if (currentChara.hasStatus(langMap!['frost'])) {
      damagePlayer('empty', currentCharaId, 6 * currentChara.getStatusIntensity(langMap!['frost']), DamageType.magical, tag: 'frost');
      // 白谢【极寒环域】
      if (isCharacterInGame(langMap!['bai_xie'])) {
        castTrait(langMap!['bai_xie'], [currentCharaId], langMap!['glacial_circle'], {'type': 1});
      }
    }
    // 灼炎
    if (currentChara.hasStatus(langMap!['flaming'])) {
      damagePlayer('empty', currentCharaId, 10 * currentChara.getStatusIntensity(langMap!['flaming']), DamageType.magical, tag: 'flaming');
    }
    // 狱焱
    if (currentChara.hasStatus(langMap!['inferno_fire'])) {
      damagePlayer('empty', currentCharaId, 15 * currentChara.getStatusIntensity(langMap!['inferno_fire']), DamageType.magical, tag: 'inferno_fire');
    }
    // 脱水
    if (currentChara.hasStatus(langMap!['dehydration'])) {
      damagePlayer('empty', currentCharaId, 30 * currentChara.getStatusIntensity(langMap!['dehydration']), DamageType.magical, tag: 'dehydration');
    }
    // 再生
    if (currentChara.hasStatus(langMap!['regeneration'])) {
      healPlayer(currentCharaId, currentCharaId, 20 * currentChara.getStatusIntensity(langMap!['regeneration']), DamageType.heal);
    }

    // 特质结算    
    for (var chara in players.values) {
      // 茵竹【自勉】
      if (chara.id == langMap!['chinro']){
        castTrait(chara.id, [chara.id], langMap!['self_encouragement'], {'type': 0});
      }
      // 龙宇澈【光耀】
      if (chara.id == langMap!['long_yuche']) {
        castTrait(chara.id, [chara.id], langMap!['radiance'], {'type': 1});
      }
      // 雷刚【决意的乌托邦】
      if (chara.id == langMap!['lei_gang']) {
        castTrait(chara.id, [chara.id], langMap!['utopia_of_resolve'], {'type': 0});
      }
      // 图尔巴赫【生息】
      if (chara.id == langMap!['turbach'] && turn == gameSequence.length) {
        castTrait(chara.id, [chara.id], langMap!['life_breath'], {'type': 0});
      }
      // 湍云【屏息】
      if (chara.id == langMap!['zephyr'] && turn == gameSequence.length) {
        castTrait(chara.id, [chara.id], langMap!['hold_breath'], {'type': 0});
        castTrait(chara.id, [chara.id], langMap!['hold_breath'], {'type': 2});
      }
      // 湍云【惊弓】
      if (chara.id == langMap!['zephyr'] && turn == gameSequence.length) {
        castTrait(chara.id, [chara.id], langMap!['gun_shy'], {'type': 0});
      }
      // EnGine-4【<04>质能回收】
      if (chara.id == langMap!['engine_4'] && turn == gameSequence.length) {
        castTrait(chara.id, [chara.id], langMap!['mass_energy_conversion'], {'type': 1});
      }
    }

    // 安德宁【回旋曲】
    if (currentCharaId == langMap!['andrenin']) {
      castTrait(currentCharaId, [], langMap!['rondo']);
    }
    // 沫 行动点
    else if (currentCharaId == langMap!['froth']) {
      if (currentChara.damageDealtTurn >= 300) {
        addAttribute(currentCharaId, AttributeType.movepoint, -currentChara.damageDealtTurn ~/ 300);
      }
    }
    // 卿别 行动点
    else if (currentCharaId == langMap!['valedictus']) {
      for (var chara in players.values) {
        if (chara.hasStatus(langMap!['dreaming'])) {
          addAttribute(currentCharaId, AttributeType.movepoint, 1);
        }
      }
    }
    // 余梦得【梦的守护】
    else if (currentCharaId == langMap!['yu_mengde']) {
      castTrait(currentCharaId, [currentCharaId], langMap!['guardian_of_dreams'], {'type': 0});
      castTrait(currentCharaId, [currentCharaId], langMap!['guardian_of_dreams'], {'type': 2});
    }
    // 太夕 行动点
    else if (currentCharaId == langMap!['nyxumbra']) {
      if (currentChara.cureReceivedTurn >= 100) {
        addAttribute(currentCharaId, AttributeType.movepoint, 1);
      }
    }
    // 科亚特尔【拟造“伊甸园”】
    else if (currentCharaId == langMap!['quetzalcoatl']) {
      castTrait(currentCharaId, [currentCharaId], langMap!['artificial_eden']);
    }

    // 安山定【后发的乌托邦】
    else if (currentCharaId == langMap!['an_shanding']) {
      castTrait(currentCharaId, [currentCharaId], langMap!['utopia_of_upspring'], {'type': 0});
    }
    // 阿波菲斯【毁灭暗影】
    else if (currentChara.hasHiddenStatus('night')) {
      modifyHiddenStatusIntensity(currentCharaId, 'night', -currentChara.getHiddenStatusIntensity('night'));
    }
    

    // 弃牌
    //for (var chara in players.values) {
    if (currentChara.cardCount > currentChara.maxCard) {
      currentChara.cardCount = currentChara.maxCard;
    }
    //}

    // 状态层数削减
    if (countdown.extraTurn == 0) {
    for (var chara in players.values){
      List<String> statusKeys = chara.status.keys.toList();
      for (String status in statusKeys){
        if (!{langMap!['teroxis'], langMap!['dodge'], langMap!['lumen_flare'], langMap!['erode_gelid'], langMap!['dream_crafting'], 
        langMap!['tear'], langMap!['wounded'], langMap!['unbalanced'], langMap!['uneasiness'], langMap!['charge'], 
        langMap!['prey']}.contains(status)) {
          chara.status[status]![2]--;
        }
        if (chara.status[status]![2] <= 0) {
          // chara.status[status]![1]--;
          modifyStatusLayer(chara.id, status, -1);
          chara.status[status]![2] = playerCount;
        }
        if (chara.getStatusLayer(status) == 0) {
          removeStatus(chara.id, status);
        }
      }
      List<String> hiddenStatusKeys = chara.hiddenStatus.keys.toList();
      for (String status in hiddenStatusKeys){
        if (!['barrier'].contains(status)) {
          chara.hiddenStatus[status]![2]--;
        }      
        if (chara.hiddenStatus[status]![2] <= 0) {
          // chara.hiddenStatus[status]![1]--;
          modifyHiddenStatusLayer(chara.id, status, -1);
          chara.hiddenStatus[status]![2] = playerCount;
        }
        if (chara.getHiddenStatusLayer(status) == 0) {
          removeHiddenStatus(chara.id, status);
        }
      }
    }
    }

    // 技能CD减少
    if (countdown.extraTurn == 0) {
      for (String skill in currentChara.skill.keys){
        if(currentChara.skill[skill]! > 0){
          currentChara.skill[skill] = currentChara.skill[skill]! - 1;
        }
      }
    }

    // 玩家死亡
    for (var chara in players.values) {
      // 恋慕【勿忘我】
      if (chara.id == langMap!['loveless'] && chara.health <= 0 && round == 1) {
        castTrait(chara.id, [chara.id], langMap!['dont_forget_me'], {'type': 2});
      }
      // 赐弥【在云端】
      if (chara.id == langMap!['cimme'] && chara.health <= 0) {
        castTrait(chara.id, [chara.id], langMap!['upon_the_clouds']);
      }
      if (chara.health <= 0 && !({langMap!['darkstar']}.contains(chara.id)) ) {
        chara.isDead = true;
        playerDiedCount++;
      }
      // 黯星【决心】
      if (chara.id == langMap!['darkstar'] && chara.hasHiddenStatus('res_failed')) {
        chara.isDead = true;
        playerDiedCount++;
      }
    }
    // 好好先生【深重情谊】
    if (playerCount - playerDiedCount <= 2) {
      for (var chara in players.values) {
        if (chara.hasHiddenStatus('favor')) {
          removeHiddenStatus(chara.id, 'favor');
        }
      }
    }
    bool teamGameOver = false;
    if (gameType == GameType.team) {
      teamGameOver = true;
      for (var chara1 in players.values) {
        for (var chara2 in players.values) {
          if (isEnemy(chara1.id, chara2.id) && !chara2.isDead && !chara1.isDead) {
            teamGameOver = false;
          }
        }
      }
    }    
    if (gameType == GameType.single && playerDiedCount == playerCount - 1 || teamGameOver) {
      gameState = GameState.over;
      for (var chara in players.values) {
        if (!(chara.id == 'empty')) {
          _gameLogger!.addStatisticsLog(getGameTurn(), chara.id, 'DamageDealt', chara.damageDealtTotal);
          _gameLogger!.addStatisticsLog(getGameTurn(), chara.id, 'DamageReceived', chara.damageReceivedTotal);          
          _gameLogger!.addStatisticsLog(getGameTurn(), chara.id, 'CureDealt', chara.cureDealtTotal);
          _gameLogger!.addStatisticsLog(getGameTurn(), chara.id, 'CureReceived', chara.cureReceivedTotal);
        }
      }
    }
    }

    // 额外回合
    if (countdown.extraTurn == 1) {
      countdown.extraTurn = 0;
    }
    if (!currentChara.hasHiddenStatus('extra')) {
      turn++;
      extra = 0;
    }
    else {
      removeHiddenStatus(currentCharaId, 'extra');
      extra++;
      countdown.extraTurn = 1;
    }
    // 轮次变更
    if(turn > playerCount){
      turn = 1;
      round++;
    }
    gameTurnList.add(getGameTurn());
    // 技能【反重力】
    if (turn == 1) {
      for (; countdown.antiGravity > 0; countdown.antiGravity--) {
        gameSequence = gameSequence.reversed.toList();
      }
    }
    currentCharaId = gameSequence[turn - 1];
    currentChara = players[currentCharaId]!;

    // 伤害统计重置
    for (var chara in players.values) {
      chara.damageDealtTurn = 0;
      chara.damageReceivedTurn = 0;
      chara.cureDealtRound = 0;
      chara.cureReceivedRound = 0;
      if (turn == 1 && countdown.extraTurn == 0) {
        chara.damageDealtRound = 0;
        chara.damageReceivedRound = 0;
        chara.cureDealtRound = 0;
        chara.cureReceivedRound = 0;
      }
    }

    // 特质结算    
    for (var chara in players.values) {
      // 恋慕【勿忘我】
      if (chara.id == langMap!['loveless'] && chara.hasHiddenStatus('forget_me') && round >= 2) {
        removeHiddenStatus(chara.id, 'forget_me');
        chara.isDead = true;
        playerDiedCount++;
      }
      // 扶风【大预言】
      if (chara.id == langMap!['flowwind'] && chara.hasHiddenStatus('grand_prophecy') && turn == 1) {
        removeHiddenStatus(chara.id, 'grand_prophecy');                
      }
      // 奈普斯特【小惊吓】
      if (chara.id == langMap!['nepst'] && turn == 1 && extra == 0 && round > 1) {
        castTrait(chara.id, [chara.id], langMap!['little_spook']);
      }
      // 沫【湮灭性轮回】
      if (chara.hasHiddenStatus('cycle') && turn == playerCount) {
        addAttribute(chara.id, AttributeType.armor, chara.getHiddenStatusIntensity('cycle'));
        removeHiddenStatus(chara.id, 'cycle');
      }
      // 科亚特尔【善恶天平】
      if (chara.id == langMap!['quetzalcoatl']) {
        castTrait(chara.id, [chara.id], langMap!['balance_of_light_and_shadow']);
        if (chara.hasHiddenStatus('balance_change') && !chara.hasHiddenStatus('balance')) {
          addHiddenStatus(chara.id, 'balance', 0, -1);
          removeHiddenStatus(chara.id, 'balance_change');
          addAttribute(chara.id, AttributeType.attack, 15);
        }
        else if (chara.hasHiddenStatus('balance') && !chara.hasHiddenStatus('balance_change')) {
          removeHiddenStatus(chara.id, 'balance');
          addAttribute(chara.id, AttributeType.attack, -15);
        }
      }
      // 图尔巴赫【生息】
      if (chara.id == langMap!['turbach']) {
        final targets = [...players.keys.where((tar) => !players[tar]!.isDead && tar != langMap!['turbach'])];
        castTrait(chara.id, targets, langMap!['life_breath'], {'type': 1});
      }
      // 湍云【屏息】
      if (chara.id == langMap!['zephyr']) {
        castTrait(chara.id, [chara.id], langMap!['hold_breath'], {'type': 1});
        castTrait(chara.id, [chara.id], langMap!['hold_breath'], {'type': 3});
      }
      // 湍云【惊弓】
      if (chara.id == langMap!['zephyr']) {
        castTrait(chara.id, [chara.id], langMap!['gun_shy'], {'type': 1});
      }
    }
    // K97【二进制】
    if (currentCharaId == langMap!['k97']) {
      if (round % 2 == 1) {
        castTrait(currentCharaId, [currentCharaId], langMap!['binary'], {'type': 0});
      }
      else {
        castTrait(currentCharaId, [currentCharaId], langMap!['binary'], {'type': 1});
      }
    }
    // 奈普斯特【幽魂化】
    else if (currentCharaId == langMap!['nepst']) {
      castTrait(currentCharaId, [currentCharaId], langMap!['spectralization'], {'type': 1});
    }
    // 赐弥【在云端】
    else if (currentCharaId == langMap!['cimme']) {
      if (currentChara.hasHiddenStatus('cloud')) {
        removeHiddenStatus(currentCharaId, 'cloud');
      }
    }
    // 长霾【我还能喝】
    else if (currentCharaId == langMap!['sumoggu']){
      castTrait(currentCharaId, [currentCharaId], langMap!['im_drunk'], {'type': 0});
    }
    // 樊求【游侠】
    else if (currentCharaId == langMap!['fan_qiu']){
      castTrait(currentCharaId, [currentCharaId], langMap!['ranger'], {'type': 0});
      castTrait(currentCharaId, [currentCharaId], langMap!['ranger'], {'type': 1});
    }
    // 洛尔【不断燃烧的愤怒】
    else if (currentCharaId == langMap!['lor']){
      castTrait(currentCharaId, [currentCharaId], langMap!['smoldering_rage'], {'type': 0});
    }

    // 抽牌
    bool drawAble = true;
    // 状态【冰封】【咕咕】【星牢】【梦境】【束缚】【窒息】
    if (currentChara.hasStatus(langMap!['frozen']) || currentChara.hasStatus(langMap!['gugu']) 
        || currentChara.hasStatus(langMap!['stellar_cage']) || currentChara.hasStatus(langMap!['dreaming']) 
        || currentChara.hasStatus(langMap!['constraint']) || currentChara.hasStatus(langMap!['asphyxia'])) {
      drawAble = false;
    }
    if (currentChara.isDead) {
      drawAble = false;
    }
    if (drawAble) {
      addAttribute(currentCharaId, AttributeType.card, 2);
      // 技能【天国邮递员】
      if (currentChara.hasHiddenStatus('heaven')) {
        addAttribute(currentCharaId, AttributeType.card, 1);
        removeHiddenStatus(currentCharaId, 'heaven');
      }
    }    

    // 行动点回复
    bool recoverAble = true;
    if (currentChara.hasStatus(langMap!['stellar_cage']) || currentChara.hasStatus(langMap!['dreaming'])) {
      drawAble = false;
    }
    if (currentChara.isDead) {
      recoverAble = false;
    }
    if (recoverAble) {
      int moveRegen = 0;
      if (currentChara.regenType == 0) {
        moveRegen = currentChara.moveRegen;
      }
      else if (currentChara.regenType == 2) {
        moveRegen = currentChara.maxMove;
      }
      else if (currentChara.regenType == 3) {
        moveRegen = (currentChara.cardCount / 2).ceil();
      }
      else if (currentChara.regenType == 4) {
      if (round == 1) {moveRegen = currentChara.maxMove;}
      else {moveRegen = currentChara.moveRegen;}
      }
      if (currentChara.hasStatus(langMap!['swift'])) {
        moveRegen++;
      }
      if (currentChara.hasStatus(langMap!['slowness'])) {
        moveRegen--;
      }
      if (currentChara.hasStatus(langMap!['submerged'])) {
        moveRegen--;
      }
      if (moveRegen < 0) {
        moveRegen = 0;
      }
      if (currentChara.maxMove - currentChara.movePoint < moveRegen) {
        moveRegen = currentChara.maxMove - currentChara.movePoint;
      }
      if (([0, 3, 4].contains(currentChara.regenType)) && (round - 1) % currentChara.regenTurn == 0) {
        addAttribute(currentCharaId, AttributeType.movepoint, moveRegen);
      }
      if (currentChara.movePoint == 0 && currentChara.regenType == 2) {
        addAttribute(currentCharaId, AttributeType.movepoint, moveRegen);
      }
    }

    // 行动次数增加
    bool actionAble = true;
    if (actionAble) {
      currentChara.actionTime++;
    }    

    refresh();
  }  

  void refresh(){
    notifyListeners();
  }
}

class GameManager{
  static final GameManager _instance = GameManager._internal();
  factory GameManager() => _instance;
  GameManager._internal();
  
  Game game = Game('game1', GameType.single);
}