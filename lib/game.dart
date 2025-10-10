import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'assets.dart';

class Character{
  String id;
  int maxHealth, attack, defence, maxMove, moveRegen, regenType, regenTurn;
  int health = 0, armor = 0, movePoint = 0, cardCount = 2;
  int damageReceivedTotal = 0, damageDealtTotal = 0, damageDealtRound = 0;
  bool isDead = false;
  Map<String, List<int>> status = {}, hiddenStatus = {};
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
      return status[stat]![0];
    } catch (e) {
      return -1;
    }
  }

  int getStatusLayer(String stat){
    try{
      return status[stat]![1];
    } catch (e) {
      return -1;
    }
  }

  int getStatusIntData(String stat){
    try{
      return status[stat]![3];
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
  List<String> gameSequence = [];
  Map<String, Character> players = {};
  var playerDied = {}, teams = {};
  int gameType = 0, playerCount = 0, turn = 0, round = 1, teamCount = 0;

  final AssetsManager assets = AssetsManager();
  Map<String, dynamic>? langMap;

  Game(this.id){
    players['empty'] = emptyCharacter;
    _initializeAssets();
  }

  Future<void> _initializeAssets() async {
    await assets.loadData();
    langMap = assets.langMap;
  }

  void clearGame(){
    players.clear();
    gameSequence.clear();
    playerDied.clear();
    teams.clear();
    gameType = 0;
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

  void addAttribute(String charaId, String attribute, int value){
    Character chara = players[charaId]!;
    if(attribute == "health"){
      chara.health += value;
      if(chara.health > chara.maxHealth){chara.health = chara.maxHealth;}
      }
    else if(attribute == "maxhp"){chara.maxHealth += value;}
    else if(attribute == "attack"){chara.attack += value;}
    else if(attribute == "defence"){chara.defence += value;}
    else if(attribute == "armor"){chara.armor += value;}
    else if(attribute == "movepoint"){chara.movePoint += value;}
    else if(attribute == "maxmove"){chara.maxMove += value;}
    refresh();
  }

  void addStatus(String charaId, String status, int intensity, int layer){
    Character chara = players[charaId]!;
    bool isImmune = false;
    if(chara.hasHiddenStatus('babel')){
      isImmune = true;
    }
    if(!isImmune){
      try{
        chara.status[status]![1] += layer;
      }
      catch (e){
        chara.status[status] = [intensity, layer, playerCount, 0];
        if(status == langMap!['frost']){
          addAttribute(chara.id, "attack", -4 * chara.getStatusIntensity(langMap!['frost']));
        }
        if(status == langMap!['exhausted']){
          chara.status[langMap!['exhausted']]![3] = (chara.attack / 2).toInt();
          addAttribute(chara.id, "attack", -chara.getStatusIntData(langMap!['exhausted']));
        }
      }
    }
    refresh();
  }

  void removeStatus(String charaId, String status){ 
    Character chara = players[charaId]!;
    if(status == langMap!['frost']){
      addAttribute(chara.id, "attack", 4 * chara.getStatusIntensity(langMap!['frost']));
    }
    if(status == langMap!['exhausted']){
      addAttribute(chara.id, "attack", chara.getStatusIntData(langMap!['exhausted']));

    }
    chara.status.remove(status);
    refresh();
  }

  void addHiddenStatus(String charaId, String status, int intensity, int layer){
    Character chara = players[charaId]!;
    bool isImmune = false;
    if(!isImmune){
      try{
        if(status == 'damageplus'){
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
    if(status == 'damocles'){
      int maxHp = chara.health;
      Character maxHpChara = chara;
      for(Character target in players.values){
        if(target.health > maxHp){
          maxHp = target.health;
          maxHpChara = target;
        }
      }
      addAttribute(maxHpChara.id, 'health', -150);
    }
    chara.hiddenStatus.remove(status);
    refresh();
  }

  void damagePlayer(String source, String target, int damage, String damageType, 
  {bool isAOE = false}){ 
    Character sourceChara = players[source]!;
    Character targetChara = players[target]!;
    int damagePlus = 0;
    double damageMulti = 1;
    if(targetChara.hasHiddenStatus('damageplus')){
      damagePlus += targetChara.hiddenStatus['damageplus']![0];
      removeHiddenStatus(target, 'damageplus');
      }
    if(targetChara.hasHiddenStatus('end')){
      damageMulti *= 1.5; 
      removeHiddenStatus(target, 'end');
      }
    if(targetChara.hasStatus(langMap!['tigris_dilemma'])){
      damageMulti *= 1.2;
      }
    damage = ((damage + damagePlus) * damageMulti).toInt();
    if(sourceChara.hasHiddenStatus('void')){
      damage = 0;
      removeHiddenStatus(source, 'void');
    }
    if(damageType == 'physical'){
      if(targetChara.hasStatus(langMap!['fractured'])){
        targetChara.health -= damage;
      }
      else{
        targetChara.armor -= damage;
        if(targetChara.armor < 0){
          targetChara.health += targetChara.armor;
          targetChara.armor = 0;
        }
      }
    }
    else if(damageType == 'magical'){
      targetChara.health -= damage;
    }
    else if(damageType == 'heal'){
      if (targetChara.hasStatus(langMap!['dissociated']) == false){
        targetChara.health += damage;
        if(targetChara.health > targetChara.maxHealth){
          targetChara.health = targetChara.maxHealth;
        }
      }
    }
    refresh();
  }


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
    
    // 轮次变更
    turn++;
    if(turn > playerCount){
      turn = 1;
      round++;
    }

    // 状态结算
    if(currentChara.hasStatus(langMap!['frost'])){
      damagePlayer(emptyCharacter.id, currentCharaId, 4 * currentChara.getStatusIntensity(langMap!['frost']), 'magical');
    }
    if(currentChara.hasStatus(langMap!['flaming'])){
      damagePlayer(emptyCharacter.id, currentCharaId, 10 * currentChara.getStatusIntensity(langMap!['flaming']), 'magical');
    }
    if(currentChara.hasStatus(langMap!['regeneration'])){
      damagePlayer(emptyCharacter.id, currentCharaId, 30 * currentChara.getStatusIntensity(langMap!['regeneration']), 'heal');
    }
    

    // 状态层数削减
    for(Character chara in players.values){
      List<String> statusKeys = chara.status.keys.toList();
      for(String status in statusKeys){
        chara.status[status]![2]--;
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
        chara.hiddenStatus[status]![2]--;
        if(chara.hiddenStatus[status]![2] <= 0){
          chara.hiddenStatus[status]![1]--;
          chara.hiddenStatus[status]![2] = playerCount;
        }
        if(chara.hiddenStatus[status]![1] <= 0){
          removeHiddenStatus(chara.id, status);
        }
      }
    }

    // 抽牌
    currentCharaId = gameSequence[turn - 1];
    currentChara = players[currentCharaId]!;
    currentChara.cardCount += 2;

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
    if(currentChara.hasStatus('迅捷')){
      moveRegen++;
    }
    if(currentChara.hasStatus('迟缓')){
      moveRegen--;
    }
    if(currentChara.maxMove - currentChara.movePoint < moveRegen){
      moveRegen = currentChara.maxMove - currentChara.movePoint;
    }
    if(currentChara.isDead){
      moveRegen = 0;
    }
    if((round - 1) % currentChara.regenTurn == 0 && ([0, 3, 4].contains(currentChara.regenType))){
      addAttribute(currentCharaId, 'movepoint', moveRegen);
    }
    if(currentChara.movePoint == 0 && currentChara.regenType == 2){
      addAttribute(currentCharaId, 'movepoint', moveRegen);
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
  
  Game game = Game('game1');
}