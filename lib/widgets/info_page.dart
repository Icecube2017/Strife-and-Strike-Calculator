import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:sns_calculator/history.dart';
import 'package:sns_calculator/record.dart';
import 'package:sns_calculator/game.dart';
import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/core.dart';
import 'package:sns_calculator/widgets/add_action.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  // 表格数据（每行包含各列内容）
  List<Map<String, dynamic>> tableData = [];
  final ScrollController _horizontalScrollController = ScrollController();
  // 当前选中的行索引（null表示无选中）
  int? selectedIndex;
  // 游戏数据id
  String gameId = 'game1';
  // 游戏数据
  late Game game;
  // 语言数据
  Map<String, dynamic>? langMap;
  // 角色数据
  Map<String, dynamic>? characterData;
  Map<String, dynamic>? characterTypeData;
  Map<String, dynamic>? regenerateTypeData;
  // 下拉框选项
  List<String> dropdownItems = [];
  // 固定列数
  final int columnCount = 7;

  
  // 日志
  static final Logger _logger = Logger();
  //final columnWidth = MediaQuery.of(context).size.width / columnCount * 0.8;

  @override
  void initState() {
    super.initState();
    // 使用全局注入的 AssetsManager（在 app 启动时已加载）
    final assets = Provider.of<AssetsManager>(context, listen: false);
    langMap = assets.langMap;
    characterData = assets.characterData;
    characterTypeData = assets.characterTypeData;
    regenerateTypeData = assets.regenerateTypeData;
    dropdownItems = characterData?.keys.toList() ?? [];
    game = GameManager().game;
    final recordProvider = Provider.of<RecordProvider>(context, listen: false);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    GameManager().game.setRecordProvider(recordProvider);
    GameManager().game.setHistoryProvider(historyProvider);

    // 添加监听器来响应游戏状态变化
    game.addListener(_handleGameChange);
    // 初始化历史记录，保存初始状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
  }

  // 处理游戏状态变化的回调函数
  void _handleGameChange() {
    // 使用 setState 来触发 UI 更新
    setState(() {
      // 这里不需要做任何事情，只需要触发重建    
    });
  }

  // 读取并解析JSON文件（已迁移到 app 启动时预加载）

  // 保存当前游戏状态到历史记录
  void _saveCurrentStateToHistory() {
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    String currentState = _serializeGameState();
    historyProvider.saveCurrentStateToHistory(currentState);  
  }

// 将游戏状态序列化为JSON字符串
String _serializeGameState() {
  final recordProvider = Provider.of<RecordProvider>(context, listen: false);

  Map<String, dynamic> gameState = {
    'gameId': game.id,
    'gameSequence': game.gameSequence,
    'players': {},
    'playerDied': game.playerDied,
    'teams': game.teams,
    'gameType': game.gameType.name,
    'playerCount': game.playerCount,
    'turn': game.turn,
    'round': game.round,
    'teamCount': game.teamCount,
    'extra': game.extra,
    'records': recordProvider.serializeRecords(),
    'countdown': {
      'damocles': game.countdown.damocles,
      'reinforcedDamocles': game.countdown.reinforcedDamocles,
      'eden': game.countdown.eden,
      'reinforcedEden': game.countdown.reinforcedEden,
      'extraturn':game.countdown.extraTurn
    }
  };
  
  // 序列化每个玩家的状态
  game.players.forEach((id, character) {
    gameState['players'][id] = {
      'id': character.id,
      'maxHealth': character.maxHealth,
      'attack': character.attack,
      'defence': character.defence,
      'maxMove': character.maxMove,
      'moveRegen': character.moveRegen,
      'regenType': character.regenType,
      'regenTurn': character.regenTurn,
      'health': character.health,
      'armor': character.armor,
      'movePoint': character.movePoint,
      'cardCount': character.cardCount,
      'actionTime': character.actionTime,
      'damageReceivedTotal': character.damageReceivedTotal,
      'damageDealtTotal': character.damageDealtTotal,
      'damageReceivedRound' : character.damageReceivedRound,
      'damageDealtRound': character.damageDealtRound,
      'damageReceivedTurn' : character.damageReceivedTurn,
      'damageDealtTurn': character.damageDealtTurn,
      'isDead': character.isDead,
      'status': character.status,
      'hiddenStatus': character.hiddenStatus,
      'skill': character.skill,
      'skillStatus': character.skillStatus,
    };
  });
  
  return jsonEncode(gameState);
}

// 从JSON字符串恢复游戏状态
void _restoreGameState(String stateJson) {
  final recordProvider = Provider.of<RecordProvider>(context, listen: false);

  Map<String, dynamic> gameState = jsonDecode(stateJson);
  
  // 恢复游戏基本属性
  game.gameSequence = List<String>.from(gameState['gameSequence']);
  game.playerDied = gameState['playerDied'];
  game.teams = gameState['teams'];
  game.gameType = GameType.values.firstWhere((e) => e.name == gameState['gameType'], orElse: () => GameType.single);
  game.playerCount = gameState['playerCount'];
  game.turn = gameState['turn'];
  game.round = gameState['round'];
  game.teamCount = gameState['teamCount'];
  game.extra = gameState['extra'];
  game.countdown.damocles = gameState['countdown']['damocles'];
  game.countdown.reinforcedDamocles = gameState['countdown']['reinforcedDamocles'];
  game.countdown.eden = gameState['countdown']['eden'];
  game.countdown.reinforcedEden = gameState['countdown']['reinforcedEden'];
  game.countdown.extraTurn = gameState['countdown']['extraturn'];

  if (gameState.containsKey('records')) {
    recordProvider.deserializeRecords(gameState['records']);
  }
  
  // 恢复玩家状态
  game.players.clear();
  Map<String, dynamic> playersData = gameState['players'];
  playersData.forEach((id, playerData) {
    Character character = Character(
      playerData['id'],
      playerData['maxHealth'],
      playerData['attack'],
      playerData['defence'],
      playerData['movePoint'],
      playerData['maxMove'],
      playerData['moveRegen'],
      playerData['regenType'],
      playerData['regenTurn'],
    );
    
    character.health = playerData['health'];
    character.armor = playerData['armor'];
    character.movePoint = playerData['movePoint'];
    character.cardCount = playerData['cardCount'];
    character.actionTime = playerData['actionTime'];
    character.damageReceivedTotal = playerData['damageReceivedTotal'];
    character.damageDealtTotal = playerData['damageDealtTotal'];
    character.damageReceivedRound = playerData['damageReceivedRound'];
    character.damageDealtRound = playerData['damageDealtRound'];
    character.damageReceivedTurn = playerData['damageReceivedTurn'];
    character.damageDealtTurn = playerData['damageDealtTurn'];
    character.isDead = playerData['isDead'];
    character.status = Map<String, List<dynamic>>.from(playerData['status']);
    character.hiddenStatus = Map<String, List<dynamic>>.from(playerData['hiddenStatus']);
    character.skill = Map<String, int>.from(playerData['skill']);
    character.skillStatus = Map<String, int>.from(playerData['skillStatus']);
    
    game.players[id] = character;
  });

  if (tableData.isEmpty){
    for(var playerId in game.gameSequence) {
      tableData.add({"column1":playerId});
    }
  }
  
  game.refresh();
}

  // 回到上一个游戏状态
  void _undo() {
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    if (historyProvider.currentHistoryIndex > 0) {
      historyProvider.undo();  
      String state = historyProvider.getCurrentState()!;
      _restoreGameState(state);
    }
  }

  // 重做到下一个游戏状态
  void _redo() {
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    if (historyProvider.currentHistoryIndex < historyProvider.history.length - 1) {
      historyProvider.redo();    
      String state = historyProvider.getCurrentState()!;
      _restoreGameState(state);
    }
  }

  // 保存游戏状态到本地文件
Future<void> _saveGameToFile() async {
  try {
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

    // 创建一个包含所有历史记录的完整数据结构
    Map<String, dynamic> saveData = {
      'currentHistoryIndex': historyProvider.currentHistoryIndex,
      'history': historyProvider.history,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    String jsonString = jsonEncode(saveData);
    
    // 在实际应用中，您可能需要使用path_provider来获取文档目录
    // 并使用File类来写入文件
    // 示例:
    // final directory = await getApplicationDocumentsDirectory();
    // final file = File('${directory.path}/game_save.json');
    // await file.writeAsString(jsonString);
    
    // 临时使用日志输出来演示功能
    // 实际应用中应替换为文件保存逻辑
    Logger().i('Game saved with ${historyProvider.history.length} history states');
    Logger().d(jsonString);
    
    // 显示保存成功的提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('游戏状态已保存')),
    );
  } catch (e) {
    Logger().e('保存游戏状态失败: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('保存失败: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SnS Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 顶部操作栏 - 改为自适应宽度排列
  LayoutBuilder(
    builder: (context, constraints) {
      // 根据屏幕宽度决定按钮排列方式
      bool isWideScreen = constraints.maxWidth > 600;
      
      if (isWideScreen) {
        // 宽屏：水平排列
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showDropdownMenu(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('添加角色'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: selectedIndex != null ? _deleteSelectedRow : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('删除角色'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: game.players.keys.length < 3 ? null : () => _showAddActionDialog(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('添加行动'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: game.players.keys.length < 3 ? null : () => _changeGameTurn(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('轮次变更'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _resetGameTurn(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('重置计分'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                  return historyProvider.currentHistoryIndex > 0 ? _undo() : null;
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('撤销'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                  return historyProvider.currentHistoryIndex < historyProvider.history.length - 1 ? _redo() : null;
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('重做'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _saveGameToFile(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('保存'),
              ),
            ),
          ],
        );
      } else {
        // 窄屏：网格排列
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showDropdownMenu(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('添加角色'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedIndex != null ? _deleteSelectedRow : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('删除角色'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: game.players.keys.length < 3 ? null : () => _showAddActionDialog(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('添加行动'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: game.players.keys.length < 3 ? null : () => _changeGameTurn(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('轮次变更'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _resetGameTurn(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('重置计分'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                      return historyProvider.currentHistoryIndex > 0 ? _undo() : null;
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('撤销'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                      return historyProvider.currentHistoryIndex < historyProvider.history.length - 1 ? _redo() : null;
                    },                    
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('重做'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveGameToFile(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('保存'),
                  ),
                ),
              ]
            )
          ],
        );
      }
    },
  ),
            const SizedBox(height: 16),
            // 2. 表格区域（用Expanded避免溢出）
            Text('当前回合：${game.round}',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold)
                ),
            const SizedBox(height: 4),
            Text('当前轮次：${game.turn}',
              style: TextStyle( 
                fontSize: 18,
                fontWeight: FontWeight.bold)
                ),
            const SizedBox(height: 4),
            Text('额外回合：${game.extra}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold)
                ),
            Expanded(
              child: Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                        // 修复点2：设置最小宽度约束
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width,
                        ),
                    child: DataTable(
                      // 固定列定义（列名可自定义）
                      columns: [
                        DataColumn(label: Text('角色')),
                        DataColumn(label: Text('生命')),
                        DataColumn(label: Text('攻击')),                      
                        DataColumn(label: Text('防御')),
                        DataColumn(label: Text('行动点')),
                        DataColumn(label: Text('手牌数')),
                        DataColumn(label: Text('状态')),
                        DataColumn(label: Text('技能'))
                      ],
                      columnSpacing: 28.0,
                      // 表格行数据
                      rows: tableData.asMap().entries.map((entry) {
                        final int rowIndex = entry.key;
                        final Map<String, dynamic> rowData = entry.value;
                        final String roleName = rowData['column1'];
                        //final List<dynamic>? roleInfo = characterData![roleName];
                        int health = game.players[roleName]!.health;
                        int armor = game.players[roleName]!.armor;
                        int attack = game.players[roleName]!.attack;
                        int defence = game.players[roleName]!.defence;
                        int movePoint = game.players[roleName]!.movePoint;
                        int maxMovePoint = game.players[roleName]!.maxMove;
                        int cardCount = game.players[roleName]!.cardCount;
                        Map<String, List<dynamic>> status = game.players[roleName]!.status;
                        Map<String, List<dynamic>> hiddenStatus = game.players[roleName]!.hiddenStatus;
                        Map<String, int> skill = game.players[roleName]!.skill;
                        String statusText = "", skillText = "";
                        for(var key in status.keys){
                          statusText += "$key[${status[key]![0]}](${status[key]![1]}) ";
                        }
                        for(var key in hiddenStatus.keys){
                          statusText += "$key[${hiddenStatus[key]![0]}](${hiddenStatus[key]![1]}) ";
                        }                        
                        for(var key in skill.keys){
                          skillText += "$key[${skill[key]!}] ";
                        }
                        return DataRow(
                          // 行选中状态（绑定selectedIndex）
                          selected: selectedIndex == rowIndex,
                          // 行选择回调（更新选中状态）
                          onSelectChanged: (bool? isSelected) {
                            setState(() {
                              selectedIndex = isSelected == true ? rowIndex : null;
                            });
                          },
                          // 行单元格（第一列显示下拉选中值，其他列留空）
                          cells: [
                            DataCell(Text(roleName, style: TextStyle(color: game.players[roleName]!.isDead ? Colors.grey : null))),
                            DataCell(Text('${health.toString()}(${armor.toString()})')),
                            DataCell(Text(attack.toString())),
                            DataCell(Text(defence.toString())),
                            DataCell(Text('${movePoint.toString()}/${maxMovePoint.toString()}')),
                            DataCell(Text(cardCount.toString())),
                            DataCell(Text(statusText)),
                            DataCell(Text(skillText)),
                          ]
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. 弹出下拉菜单（选择项后添加行）
  void _showDropdownMenu() {
    showMenu(
      context: context,
      // 菜单位置（相对于“添加行”按钮）
      position: const RelativeRect.fromLTRB(0, 0, 0, 0),
      items: dropdownItems.map((String item) {
        return PopupMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
    ).then((String? selectedValue) {
      if (selectedValue != null && !game.players.keys.contains(selectedValue)) {
        setState(() {
          // 初始化角色数据
          int health = characterTypeData?[characterData?[selectedValue][0]][0];
          int attack = characterTypeData?[characterData?[selectedValue][0]][1];
          int defence = characterTypeData?[characterData?[selectedValue][0]][2];
          int movePoint = 0;
          int maxMove = regenerateTypeData?[characterData?[selectedValue][1]][0];
          int moveRegen = regenerateTypeData?[characterData?[selectedValue][1]][1];
          int regenType = regenerateTypeData?[characterData?[selectedValue][1]][2];
          int regenTurn = regenerateTypeData?[characterData?[selectedValue][1]][3];
          // 新建角色
          Character character = Character(selectedValue, health, attack, defence, movePoint, maxMove, moveRegen, regenType, regenTurn);
          game.addPlayer(character);
          // 向表格添加一行（第一列为选中的下拉值）
          tableData.add({'column1': selectedValue});          
        });
      }
    });
  }

  // 4. 删除选中行（更新表格数据和选中状态）
  void _deleteSelectedRow() {
    setState(() {
      String roleName = tableData[selectedIndex!]['column1'];
      game.removePlayer(game.players[roleName]!);
      tableData.removeAt(selectedIndex!);
      selectedIndex = null; // 重置选中状态
    });
  }

  // 新增方法：显示添加行动的弹窗
  void _showAddActionDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AddActionDialog(
        characterList: tableData.map((data) => data['column1'] as String).toList(),
        onActionCompleted:(){
          setState(() {
            _saveCurrentStateToHistory();
          });
        }
      );
    },
  );
}
  void _changeGameTurn(){
    game.endTurn();
    _saveCurrentStateToHistory();
  }

  void _resetGameTurn(){
    final recordProvider = Provider.of<RecordProvider>(context, listen: false);
    game.clearGame();
    tableData.clear();
    game.refresh();
    recordProvider.clearRecords();
    _saveCurrentStateToHistory();
  }

  @override
  void dispose() {
    // 释放控制器避免内存泄漏
    game.removeListener(_handleGameChange);
    _horizontalScrollController.dispose();
    super.dispose();
  }
}