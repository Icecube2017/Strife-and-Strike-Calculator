import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'assets.dart';
import 'core.dart';
import 'record.dart';

// 攻击特效
enum AttackEffect{ 
  lumenFlare('烛焱'),
  oculusVeil('障目');

  final String effectId;

  const AttackEffect(this.effectId);
}

// 防守特效
enum DefenceEffect{ 
  erodeGelid('蚀凛');

  final String effectId;

  const DefenceEffect(this.effectId);
}

// 全局状态效果
class GlobalCountdown{
  // 达摩克利斯之剑
  int damocles = 0;
  int reinforcedDamocles = 0;
  // 伊甸园
  int eden = 0;
  int reinforcedEden = 0;
  // 额外回合
  int extraTurn = 0;
}

class Character{
  String id;
  int maxHealth, attack, defence, maxMove, moveRegen, regenType, regenTurn;
  int health = 0, armor = 0, movePoint = 0, cardCount = 2;
  int damageReceivedTotal = 0, damageDealtTotal = 0, damageDealtRound = 0, damageReceivedRound = 0,
  damageReceivedTurn = 0, damageDealtTurn = 0;
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
        // 确保转换为 int 类型
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
        // 确保转换为 int 类型
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
        // 确保转换为 int 类型
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
      if (statusData != null && statusData.length > 3) {
        // 确保转换为 int 类型
        return (statusData[0] as num).toInt();
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

final Character emptyCharacter = Character('empty', 0, 0, 0, 0, 0, 0, 0, 0);

class Game extends ChangeNotifier{
  String id;
  GameType gameType;
  List<String> gameSequence = [];
  Map<String, Character> players = {};
  var playerDied = {}, teams = {};
  int playerCount = 0, playerDiedCount = 0, turn = 0, round = 1, teamCount = 0, extra = 0;
  GlobalCountdown countdown = GlobalCountdown();
  bool isGameOver = false;
  final Logger _logger = Logger();

  final AssetsManager assets = AssetsManager();
  Map<String, dynamic>? langMap;

  RecordProvider? _recordProvider;

  Game(this.id, this.gameType){
    players['empty'] = emptyCharacter;
    _initializeAssets();
  }

  Future<void> _initializeAssets() async {
    await assets.loadData();
    langMap = assets.langMap;
  }

  // 设置RecordProvider
  void setRecordProvider(RecordProvider recordProvider){
    _recordProvider = recordProvider;
  }

  GameTurn getGameTurn() {
    return GameTurn(round: round, turn: turn, extra: extra);
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
    playerCount--;
  }

  void addAttribute(String charaId, AttributeType type, int value){
    Character chara = players[charaId]!;
    if(type == AttributeType.health){
      chara.health += value;
      if(chara.health > chara.maxHealth){chara.health = chara.maxHealth;}
      }
    else if(type == AttributeType.maxhp){chara.maxHealth += value;}
    else if(type == AttributeType.attack){chara.attack += value;}
    else if(type == AttributeType.defence){chara.defence += value;}
    else if(type == AttributeType.armor){chara.armor += value;}
    else if(type == AttributeType.movepoint){chara.movePoint += value;}
    else if(type == AttributeType.maxmove){chara.maxMove += value;}
    else if(type == AttributeType.card){chara.cardCount += value;}
    else if(type == AttributeType.dmgdealt) {chara.damageDealtTotal += value; chara.damageDealtRound += value; chara.damageDealtTurn += value;}
    else if(type == AttributeType.dmgreceived) {chara.damageReceivedTotal += value; chara.damageReceivedRound += value; chara.damageReceivedTurn += value;}
    refresh();
  }

  void addStatus(String charaId, String status, int intensity, int layer){
    Character chara = players[charaId]!;
    bool isImmune = false;
    List<int> statusDataOld = [chara.getStatusIntensity(status), chara.getStatusLayer(status)];
    if(chara.hasHiddenStatus('babel')){
      isImmune = true;
    }
    if(!isImmune){
      try{
        if(status == langMap!['teroxis']){
          if(chara.getStatusIntensity(langMap!['teroxis']) + intensity <= 5){
            chara.status[status]![0] += intensity;
            addAttribute(charaId, AttributeType.attack, 5 * intensity);
          }
          else{
            chara.status[status]![0] = 5;
            addAttribute(charaId, AttributeType.attack, 5 * (5 - chara.getStatusIntensity(langMap!['teroxis'])));
          }   
        }
        else{
          chara.status[status]![1] += layer;
        }        
      }
      catch (e){
        chara.status[status] = [intensity, layer, playerCount, 0];
        if(status == langMap!['frost']){
          addAttribute(chara.id, AttributeType.attack, -4 * chara.getStatusIntensity(langMap!['frost']));
        }
        else if(status == langMap!['exhausted']){
          chara.status[langMap!['exhausted']]![3] = (chara.attack / 2).toInt();
          addAttribute(chara.id, AttributeType.attack, -chara.getStatusIntData(langMap!['exhausted']));
        }
        else if(status == langMap!['strength']){
          addAttribute(chara.id, AttributeType.attack, 5 * chara.getStatusIntensity(langMap!['strength']));
        }
        else if(status == langMap!['teroxis']){
          addAttribute(chara.id, AttributeType.attack, 5 * intensity);
        }
        else if (status == langMap!['lumen_flare']) {
          addAttribute(chara.id, AttributeType.attack, 5);
        }
        else if (status == langMap!['erode_gelid']) {
          addAttribute(chara.id, AttributeType.defence, 5);
        }
        else if (status == langMap!['grind']) {
          chara.status[langMap!['grind']]![3] = 2;
          addAttribute(chara.id, AttributeType.maxmove, -chara.getStatusIntData(langMap!['grind']));
        }
        else if (status == langMap!['fragility']) {
          addAttribute(chara.id, AttributeType.defence, -2 * chara.getStatusIntensity(langMap!['fragility']));
        }

        // 冰火相融
        if (chara.hasStatus(langMap!['frost']) && chara.hasStatus(langMap!['flaming'])) {
          int frostIntensity = chara.getStatusIntensity(langMap!['frost']);
          int flamingIntensity = chara.getStatusIntensity(langMap!['flaming']);
          if (frostIntensity > flamingIntensity) {
            removeStatus(charaId, langMap!['flaming']);
            changeStatusIntensity(charaId, langMap!['frost'], frostIntensity - flamingIntensity);
          }
          else if (flamingIntensity > frostIntensity) {
            removeStatus(charaId, langMap!['frost']);
            changeStatusIntensity(charaId, langMap!['flaming'], flamingIntensity - frostIntensity);
          }
          else {
            removeStatus(charaId, langMap!['frost']);
            removeStatus(charaId, langMap!['flaming']);
          }
        }
      }
      _recordProvider!.addStatusRecord(GameTurn(round: round, turn: turn, extra: extra), 
      emptyCharacter.id, charaId, status, statusDataOld, [chara.getStatusIntensity(status), chara.getStatusLayer(status)], '');
    }
    refresh();
  }

  void removeStatus(String charaId, String status){ 
    Character chara = players[charaId]!;

    if (!chara.hasStatus(status)) {return;}

    if(status == langMap!['frost']){
      addAttribute(chara.id, AttributeType.attack, 4 * chara.getStatusIntensity(langMap!['frost']));
    }
    else if(status == langMap!['exhausted']){
      addAttribute(chara.id, AttributeType.attack, chara.getStatusIntData(langMap!['exhausted']));
    }
    else if(status == langMap!['strength']){
      addAttribute(chara.id, AttributeType.attack, -5 * chara.getStatusIntensity(langMap!['strength']));
    }
    else if(status == langMap!['teroxis']){
      addAttribute(chara.id, AttributeType.attack, -5 * chara.getStatusIntensity(langMap!['teroxis']));
    }
    else if(status == langMap!['lumen_flare']){
      addAttribute(chara.id, AttributeType.attack, -5);
    }
    else if(status == langMap!['erode_gelid']){
      addAttribute(chara.id, AttributeType.defence, -5);
    }
    else if(status == langMap!['grind']){
      addAttribute(chara.id, AttributeType.maxmove, chara.getStatusIntData(langMap!['grind']));
    }
    else if(status == langMap!['fragility']){
      addAttribute(chara.id, AttributeType.defence, 2 * chara.getStatusIntensity(langMap!['fragility']));
    }
    _recordProvider!.addStatusRecord(GameTurn(round: round, turn: turn, extra: extra), 
    emptyCharacter.id, charaId, status, [chara.getStatusIntensity(status), chara.getStatusLayer(status)], [0, 0], '');
    chara.status.remove(status);
    refresh();
  }

  void changeStatusIntensity(String charaId, String status, int intensity){
    Character chara = players[charaId]!;

    if (!chara.hasStatus(status)) {return;}

    if (status == langMap!['frost']) {
      addAttribute(chara.id, AttributeType.attack, 4 * chara.getStatusIntensity(langMap!['frost']) - 4 * intensity);
    }
    else if (status == langMap!['strength']) {
      addAttribute(chara.id, AttributeType.attack, -5 * chara.getStatusIntensity(langMap!['strength']) + 5 * intensity);
    }

    _recordProvider!.addStatusRecord(GameTurn(round: round, turn: turn, extra: extra), 
    emptyCharacter.id, charaId, status, [chara.getStatusIntensity(status), chara.getStatusLayer(status)], [intensity, chara.getStatusLayer(status)], '');
    chara.status[status]![0] = intensity;
  }

  void addHiddenStatus(String charaId, String status, int intensity, int layer){
    Character chara = players[charaId]!;
    bool isImmune = false;
    if(!isImmune){
      try{
        if(['damageplus', 'hero_legend', 'dream_shelter'].contains(status)){
          chara.hiddenStatus[status]![0] += intensity;
        }
        else{
          chara.hiddenStatus[status]![1] += layer;
        }
      }
      catch (e){
        chara.hiddenStatus[status] = [intensity, layer, playerCount, 0];
      }
    }
    refresh();
  }

  void removeHiddenStatus(String charaId, String status){ 
    Character chara = players[charaId]!;
    /*if(status == 'damocles'){
      int maxHp = chara.health;
      Character maxHpChara = chara;
      for(Character target in players.values){
        if(target.health > maxHp){
          maxHp = target.health;
          maxHpChara = target;
        }
      }
      addAttribute(maxHpChara.id, 'health', -150);
    }*/
    if (status == 'undying') {
      addAttribute(charaId, AttributeType.armor, -400);
      if (chara.armor < 0) chara.armor = 0;
    }
    chara.hiddenStatus.remove(status);
    refresh();
  }

  void damagePlayer(String source, String target, int damage, DamageType type, 
  {bool isAOE = false, String tag = ''}){ 
    Character sourceChara = players[source]!;
    Character targetChara = players[target]!;
    int damagePlus = 0;
    double damageMulti = 1;
    // 加伤相关效果
    if(targetChara.hasHiddenStatus('damageplus')){
      damagePlus += targetChara.getHiddenStatusIntensity('damageplus');
      removeHiddenStatus(target, 'damageplus');
      }
    // 终焉长戟
    if(targetChara.hasHiddenStatus('end')){
      for (int i = 0; i < targetChara.getHiddenStatusIntensity('end'); i++) { 
        damageMulti *= 1.5;
      }      
      removeHiddenStatus(target, 'end');
      }
    // 猎魔灵刃
    if(targetChara.hasHiddenStatus('track')){
      for (int i = 0; i < targetChara.getHiddenStatusIntensity('track'); i++) {
        damageMulti *= 1.5;
      }      
      removeHiddenStatus(target, 'track');
    }
    // 融甲宝珠
    if(targetChara.hasHiddenStatus('penetrate')){
      for (int i = 0; i < targetChara.getHiddenStatusIntensity('penetrate'); i++) {
        damageMulti *= 1.5;
      }      
      removeHiddenStatus(target, 'penetrate');
    }
    // 氤氲
    if(targetChara.hasStatus(langMap!['nebula'])){
      damageMulti *= (1.0 + 0.5 * targetChara.getStatusIntensity(langMap!['nebula']));      
    }
    // 骑虎难下
    if(targetChara.hasStatus(langMap!['tigris_dilemma'])){
      damageMulti *= 1.2;
    }
    // 恐吓
    if (targetChara.hasHiddenStatus('intimidation')) {
      damageMulti *= 0.5;
    }
    // 伤害计算 
    damage = ((damage + damagePlus) * damageMulti).toInt();
    
    // 闪避
    if(targetChara.hasStatus(langMap!['dodge']) && [DamageType.action, DamageType.physical].contains(type)){
      if(!sourceChara.hasHiddenStatus('critical')){        
        addHiddenStatus(source, 'void', 0, 1);
      }
      removeStatus(target, langMap!['dodge']);
    }
    // 不造成伤害
    if(sourceChara.hasHiddenStatus('void') && type == DamageType.action){
      damage = 0;
      removeHiddenStatus(source, 'void');
    }
    // 伤害结算
    if(type == DamageType.action){
      if(targetChara.hasStatus(langMap!['fractured']) || sourceChara.hasHiddenStatus('critical')){
        targetChara.health -= damage;
        if (sourceChara.hasHiddenStatus('critical')) removeHiddenStatus(source, 'critical');
      }
      else{
        targetChara.armor -= damage;
        if(targetChara.armor < 0){
          if (!targetChara.hasHiddenStatus('barrier')){
            targetChara.health += targetChara.armor;
          }
          else {
            removeHiddenStatus(target, 'barrier');
          }
          targetChara.armor = 0;
        }
      }
    }
    else if(type == DamageType.physical){
      if(targetChara.hasStatus(langMap!['fractured'])){
        targetChara.health -= damage;
      }
      else{
        targetChara.armor -= damage;
        if(targetChara.armor < 0){
          if (!targetChara.hasHiddenStatus('barrier')){
            targetChara.health += targetChara.armor;
          }
          else {
            removeHiddenStatus(target, 'barrier');
          }    
          targetChara.armor = 0;
        }
      }
    }
    else if(type == DamageType.magical){
      targetChara.health -= damage;
    }
    else if(type == DamageType.heal){
      if (targetChara.hasStatus(langMap!['dissociated']) == false){
        targetChara.health += damage;
        if(targetChara.health > targetChara.maxHealth){
          targetChara.health = targetChara.maxHealth;
        }
      }
    }
    else if (type == DamageType.revive) {
      targetChara.health += damage;
    }

    // 伤害统计
    addAttribute(source, AttributeType.dmgdealt, damage);
    addAttribute(target, AttributeType.dmgreceived, damage);
    _recordProvider!.addDamageRecord(GameTurn(round: round, turn: turn, extra: extra), 
    source, target, damage, type, tag);
    //_logger.d(_recordProvider!.getRecordsInRounds(
     // GameTurn(round: round, turn: turn, isExtraTurn: countdown.extraTurn == 1), 
    //  GameTurn(round: round, turn: turn, isExtraTurn: countdown.extraTurn == 1)));
    refresh();
  }

  // 结束轮次
  void endTurn(){
    //
    String currentCharaId;
    if(turn == 0){
      currentCharaId = gameSequence[0];
    }
    else{
      currentCharaId = gameSequence[turn - 1];
    }
    Character currentChara = players[currentCharaId]!;        

    // 全局状态结算
    if(turn == playerCount && !currentChara.hasHiddenStatus('extra')){
      // 达摩克利斯之剑
      for(; countdown.reinforcedDamocles > 0; countdown.reinforcedDamocles--){
        Character maxHpChara = players[currentCharaId]!;
        int maxHp = maxHpChara.health;
        for(Character target in players.values){ 
          if(target.health > maxHp){
            maxHp = target.health;
            maxHpChara = target;
          }          
        }
        damagePlayer(emptyCharacter.id, maxHpChara.id, 300, DamageType.magical);        
      }
      for(; countdown.damocles > 0; countdown.damocles--){
        Character maxHpChara = players[currentCharaId]!;
        int maxHp = maxHpChara.health;
        for(Character target in players.values){
          if(target.health > maxHp){
            maxHp = target.health;
            maxHpChara = target;
            // _logger.d(maxHpChara.id);
          }          
        }
        damagePlayer(emptyCharacter.id, maxHpChara.id, 150, DamageType.magical);      
      }      
    }

    // 状态结算
    // 霜冻
    if(currentChara.hasStatus(langMap!['frost'])){
      damagePlayer(emptyCharacter.id, currentCharaId, 4 * currentChara.getStatusIntensity(langMap!['frost']), DamageType.magical);
    }
    // 灼炎
    if(currentChara.hasStatus(langMap!['flaming'])){
      damagePlayer(emptyCharacter.id, currentCharaId, 10 * currentChara.getStatusIntensity(langMap!['flaming']), DamageType.magical);
    }
    // 再生
    if(currentChara.hasStatus(langMap!['regeneration'])){
      damagePlayer(emptyCharacter.id, currentCharaId, 30 * currentChara.getStatusIntensity(langMap!['regeneration']), DamageType.heal);
    }

    // 状态层数削减
    if (countdown.extraTurn == 0) {
    for(Character chara in players.values){
      List<String> statusKeys = chara.status.keys.toList();
      for(String status in statusKeys){
        if(![langMap!['teroxis'], langMap!['dodge'], langMap!['lumen_flare'], langMap!['erode_gelid']].contains(status)){
          chara.status[status]![2]--;
        }
        if(chara.status[status]![2] <= 0){
          chara.status[status]![1]--;
          chara.status[status]![2] = playerCount;
        }
        if(chara.status[status]![1] <= 0){
          removeStatus(chara.id, status);
        }
      }
      List<String> hiddenStatusKeys = chara.hiddenStatus.keys.toList();
      for(String status in hiddenStatusKeys){
        if (!['barrier'].contains(status)){
          chara.hiddenStatus[status]![2]--;
        }      
        if(chara.hiddenStatus[status]![2] <= 0){
          chara.hiddenStatus[status]![1]--;
          chara.hiddenStatus[status]![2] = playerCount;
        }
        if(chara.hiddenStatus[status]![1] <= 0){
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
      if (chara.health <= 0) {
        chara.isDead = true;
        playerDiedCount++;
      }
    }
    if (gameType == GameType.single && playerDiedCount == playerCount - 1) {
      isGameOver = true;
    }

    // 额外回合
    if (countdown.extraTurn > 0) {
      countdown.extraTurn--;
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

    // 伤害统计重置
    for (var chara in players.values) {
      chara.damageDealtTurn = 0;
      chara.damageReceivedTurn = 0;
      if (turn == 1 && countdown.extraTurn == 0) {
        chara.damageDealtRound = 0;
        chara.damageReceivedRound = 0;      
      }
    }

    // 抽牌
    currentCharaId = gameSequence[turn - 1];
    currentChara = players[currentCharaId]!;
    currentChara.cardCount += 2;
    if(currentChara.hasHiddenStatus('heaven')){
      currentChara.cardCount += 1;
    }

    // 行动点回复
    int moveRegen = 0;
    if(currentChara.regenType == 0){
      moveRegen = currentChara.moveRegen;
    }
    else if(currentChara.regenType == 2){
      moveRegen = currentChara.maxMove;
    }
    else if(currentChara.regenType == 3){
      moveRegen = (currentChara.cardCount / 2).ceil();
    }
    else if(currentChara.regenType == 4){
      if(round == 1){moveRegen = currentChara.maxMove;}
      else {moveRegen = currentChara.moveRegen;}
    }
    if(currentChara.hasStatus(langMap!['swift'])){
      moveRegen++;
    }
    if(currentChara.hasStatus(langMap!['slowness'])){
      moveRegen--;
    }
    if(currentChara.maxMove - currentChara.movePoint < moveRegen){
      moveRegen = currentChara.maxMove - currentChara.movePoint;
    }
    if(currentChara.isDead){
      moveRegen = 0;
    }
    if((round - 1) % currentChara.regenTurn == 0 && ([0, 3, 4].contains(currentChara.regenType))){
      addAttribute(currentCharaId, AttributeType.movepoint, moveRegen);
    }
    if(currentChara.movePoint == 0 && currentChara.regenType == 2){
      addAttribute(currentCharaId, AttributeType.movepoint, moveRegen);
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