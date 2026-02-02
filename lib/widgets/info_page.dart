import 'dart:math';
import 'dart:ui_web';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sns_calculator/history.dart';
import 'package:sns_calculator/record.dart';
import 'package:sns_calculator/game.dart';
import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/core.dart';
import 'package:sns_calculator/logger.dart';
import 'package:sns_calculator/widgets/add_action.dart';
import 'package:sns_calculator/widgets/history_page.dart';
import 'package:sns_calculator/widgets/attribute_settings.dart';
import 'package:sns_calculator/widgets/game_logger.dart';
import 'package:sns_calculator/widgets/skill_rolling.dart';
import 'package:lpinyin/lpinyin.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  // 表格数据（每行包含各列内容）
  List<Map<String, dynamic>> tableData = [];
  final ScrollController _horizontalScrollController = ScrollController();
  // 当前选中的卡片 id（null表示无选中）
  String? selectedIndex;
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
  // 自动加载标志
  bool _autoLoadingInProgress = false;
  
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
    dropdownItems.remove('角色');
    game = GameManager().game;
    final recordProvider = Provider.of<RecordProvider>(context, listen: false);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    final gameLogger = Provider.of<GameLogger>(context, listen: false);
    GameManager().game.setRecordProvider(recordProvider);
    GameManager().game.setHistoryProvider(historyProvider);
    GameManager().game.setGameLogger(gameLogger);

    // 添加监听器来响应游戏状态变化
    game.addListener(_handleGameChange);
    // 自动加载上次的存档
    _autoLoadingInProgress = true;
    _autoLoadLastSave();
  }

  // 处理游戏状态变化的回调函数
  void _handleGameChange() {
    // 使用 setState 来触发 UI 更新
    setState(() {
      // 这里不需要做任何事情，只需要触发重建    
    });
  }

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
    'gameType': game.gameType.name,
    'gameState': game.gameState.name,
    'gameSequence': game.gameSequence,
    'players': {},
    'playerDied': game.playerDied,
    // teams 需要转换为 Map<String, List<String>> 才能被 jsonEncode 正常处理
    'teams': game.teams.map((k, v) => MapEntry(k.toString(), v.toList())),
    'playerCount': game.playerCount,
    'playerDiedCount': game.playerDiedCount,
    'turn': game.turn,
    'round': game.round,
    'teamCount': game.teamCount,
    'extra': game.extra,
    'gameTurnList': game.gameTurnList.map((turn) => turn.toJson()).toList(),
    'records': recordProvider.serializeRecords(),
    'countdown': {
      'damocles': game.countdown.damocles,
      'reinforcedDamocles': game.countdown.reinforcedDamocles,
      'eden': game.countdown.eden,
      'reinforcedEden': game.countdown.reinforcedEden,
      'extraturn':game.countdown.extraTurn, 
      'antiGravity': game.countdown.antiGravity,
      'deftTouchSkill': game.countdown.deftTouchSkill,
      'deftTouchTarget': game.countdown.deftTouchTarget
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
      'maxCard': character.maxCard,
      'actionTime': character.actionTime,
      'damageReceivedTotal': character.damageReceivedTotal,
      'damageDealtTotal': character.damageDealtTotal,
      'damageReceivedRound' : character.damageReceivedRound,
      'damageDealtRound': character.damageDealtRound,
      'damageReceivedTurn' : character.damageReceivedTurn,
      'damageDealtTurn': character.damageDealtTurn,
      'cureReceivedTotal': character.cureReceivedTotal,
      'cureDealtTotal': character.cureDealtTotal,
      'cureReceivedRound' : character.cureReceivedRound,
      'cureDealtRound': character.cureDealtRound,
      'cureReceivedTurn' : character.cureReceivedTurn,
      'cureDealtTurn': character.cureDealtTurn,
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
  try {
    final recordProvider = Provider.of<RecordProvider>(context, listen: false);

    Map<String, dynamic> gameState = jsonDecode(stateJson);
    
    // 恢复游戏基本属性
    game.id = gameState['gameId'];
    game.gameSequence = List<String>.from(gameState['gameSequence']);
    game.playerDied = gameState['playerDied'];
  // 恢复队伍（确保类型为 Map<int, Set<String>>）
  game.teams.clear();
  if (gameState['teams'] is Map) {
    (gameState['teams'] as Map).forEach((k, v){
      try{
        int teamId = int.parse(k.toString());
        Set<String> members = {};
        if (v is List) {members = v.map((e) => e.toString()).toSet();}
        else if (v is Set) {members = v.map((e) => e.toString()).toSet();}
        game.teams[teamId] = members;
      } catch (e) {
        // 忽略解析错误
      }
    });
  }
  game.gameType = GameType.values.firstWhere((e) => e.name == gameState['gameType'], orElse: () => GameType.single);
  game.gameState = GameState.values.firstWhere((e) => e.name == gameState['gameState'], orElse: () => GameState.waiting);
  game.playerCount = gameState['playerCount'];
  game.playerDiedCount = gameState['playerDiedCount'];
  game.turn = gameState['turn'];
  game.round = gameState['round'];
  game.teamCount = gameState['teamCount'];
  game.extra = gameState['extra'];
  game.countdown.damocles = gameState['countdown']['damocles'];
  game.countdown.reinforcedDamocles = gameState['countdown']['reinforcedDamocles'];
  game.countdown.eden = gameState['countdown']['eden'];
  game.countdown.reinforcedEden = gameState['countdown']['reinforcedEden'];
  game.countdown.extraTurn = gameState['countdown']['extraturn'];

  if (gameState.containsKey('gameTurnList')) {
    game.gameTurnList.clear();
    List<dynamic> turnListData = gameState['gameTurnList'];
    for (var turnData in turnListData) {
      game.gameTurnList.add(GameTurn.fromJson(Map<String, dynamic>.from(turnData)));
    }
  }

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
    character.maxCard = playerData['maxCard'];
    character.actionTime = playerData['actionTime'];
    character.damageReceivedTotal = playerData['damageReceivedTotal'];
    character.damageDealtTotal = playerData['damageDealtTotal'];
    character.damageReceivedRound = playerData['damageReceivedRound'];
    character.damageDealtRound = playerData['damageDealtRound'];
    character.damageReceivedTurn = playerData['damageReceivedTurn'];
    character.damageDealtTurn = playerData['damageDealtTurn'];
    character.cureReceivedTotal = playerData['cureReceivedTotal'];
    character.cureDealtTotal = playerData['cureDealtTotal'];
    character.cureReceivedRound = playerData['cureReceivedRound'];
    character.cureDealtRound = playerData['cureDealtRound'];
    character.cureReceivedTurn = playerData['cureReceivedTurn'];
    character.cureDealtTurn = playerData['cureDealtTurn'];
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
  } catch (e) {
    rethrow;
  }
}

  // 打开加载对话框
  void _showLoadDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: HistoryPage(
          onSaveSelected: _onSaveFileSelected,
        ),
      ),
    );
  }

  // 自动加载上次打开的存档
  Future<void> _autoLoadLastSave() async {
    try {      
      // 添加延迟以确保插件已初始化
      await Future.delayed(const Duration(milliseconds: 500));
      
      final prefs = await SharedPreferences.getInstance();
      final lastSaveId = prefs.getString('lastSaveId');
      
      if (lastSaveId == null || lastSaveId.isEmpty) {
        if (mounted) {
          setState(() {
            _autoLoadingInProgress = false;
          });
        }
        return;
      }  
      
      // 获取应用文档目录
      final documentsDir = await getApplicationDocumentsDirectory();
      final savesDir = Directory('${documentsDir.path}/saves');
      final file = File('${savesDir.path}/$lastSaveId.json');
      
      if (!await file.exists()) {
        _logger.w('Last save file not found: ${file.path}');
        if (mounted) {
          setState(() {
            _autoLoadingInProgress = false;
          });
        }
        return;
      }
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      if (!json.containsKey('history') || !json.containsKey('currentHistoryIndex')) {
        throw Exception('存档数据结构不完整');
      }
      
      _processLoadedSaveData(json);
    } catch (e) {
      _logger.e('Auto-load last save failed: $e', error: e, stackTrace: StackTrace.current);
      if (mounted) {
        setState(() {
          _autoLoadingInProgress = false;
        });
      }
    }
  }

  // 保存最后打开的存档ID
  Future<void> _saveLastSaveId(String saveId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastSaveId', saveId);
    } catch (e) {
      _logger.e('Failed to save last save ID: $e');
      // 静默失败，不影响正常游戏流程
    }
  }

  // 存档被选择时的 callback
  void _onSaveFileSelected(Map<String, dynamic> saveData) {
    // 处理加载的存档数据
    _processLoadedSaveData(saveData);
  }

  // 处理加载的存档数据
  void _processLoadedSaveData(Map<String, dynamic> result) {
    try {
      final currentHistoryIndex = result['currentHistoryIndex'] as int;
      final history = List<String>.from(result['history'] as List);
      
      
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
      historyProvider.setHistory(history, currentHistoryIndex);
      
      
      // 恢复当前游戏状态
      if (currentHistoryIndex >= 0 && currentHistoryIndex < history.length) {
        String currentState = history[currentHistoryIndex];
        _restoreGameState(currentState);      
        
        // 重新构建表格数据
        tableData.clear();
        for (var playerId in game.gameSequence) {
          tableData.add({"column1": playerId});
        }
        
        setState(() {
          _autoLoadingInProgress = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已加载存档: ${result['timestamp'] ?? "未知时间"}')),
        );
        
        // 保存这次打开的存档ID
        _saveLastSaveId(game.id);
      } else {
        throw Exception('历史记录索引无效: $currentHistoryIndex, length: ${history.length}');
      }
    } catch (e) {
      _logger.e('处理存档数据失败: $e', error: e, stackTrace: StackTrace.current);
      if (mounted) {
        setState(() {
          _autoLoadingInProgress = false;
        });
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('加载失败: $e')),
          );
        } catch (snackBarError) {
          _logger.e('Failed to show error snackbar: $snackBarError');
        }
      }
    }
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

  // 生成新的游戏ID
  String _generateNewGameId() {
    DateTime now = DateTime.now();
    String timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
    String randomString = 'abcdefghijklmnopqrstuvwxyz0123456789';
    String randomId = List.generate(6, (index) => randomString[Random().nextInt(randomString.length)]).join();
    return '$timestamp-$randomId';
  }

  // 新建存档
  void _createNewSave() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('新建存档'),
          content: const Text('确定要创建一个新存档吗？这将清空当前游戏状态。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {                  
                  final recordProvider = Provider.of<RecordProvider>(context, listen: false);
                  final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                  
                  // 清空游戏状态
                  game.clearGame();
                  tableData.clear();
                  selectedIndex = null;
                  recordProvider.clearRecords();
                  
                  // 生成新的游戏ID
                  game.id = _generateNewGameId();
                  
                  // 初始化历史记录
                  String initialState = _serializeGameState();
                  historyProvider.resetHistory();
                  historyProvider.saveCurrentStateToHistory(initialState);
                  
                  // 创建新存档文件
                  Map<String, dynamic> saveData = {
                    'currentHistoryIndex': historyProvider.currentHistoryIndex,
                    'history': historyProvider.history,
                    'timestamp': DateTime.now().toIso8601String(),
                  };
                  
                  String jsonString = jsonEncode(saveData);
                  final documentsDir = await getApplicationDocumentsDirectory();
                  final savesDir = Directory('${documentsDir.path}/saves');
                  if (!await savesDir.exists()) {
                    await savesDir.create(recursive: true);
                  }
                  
                  final file = File('${savesDir.path}/${game.id}.json');
                  await file.writeAsString(jsonString, flush: true);
                  
                  // 保存新存档ID到本地存储
                  await _saveLastSaveId(game.id);
                  
                  // 更新UI
                  setState(() {});
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('新存档已创建: ${game.id}')),
                  );
                } catch (e) {
                  _logger.e('Failed to create new save: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('创建新存档失败: $e')),
                  );
                }
              },
              child: const Text('确认', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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

      // 获取应用文档目录
      final documentsDir = await getApplicationDocumentsDirectory();
      final savesDir = Directory('${documentsDir.path}/saves');
      if (!await savesDir.exists()) {
        await savesDir.create(recursive: true);
      }

      String safeId = game.id;
      final file = File('${savesDir.path}/$safeId.json');
      await file.writeAsString(jsonString, flush: true);

      // 将当前游戏与存档对应起来：将 game.id 保持不变并提示保存成功
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('游戏已保存到: $safeId')),
      );
      
      // 保存最后打开的存档ID
      _saveLastSaveId(safeId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  Color _getTeamColor(int? teamId) { 
    switch (teamId) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.yellow[700]!;
      default:
        return Colors.black;
    }
  }



  @override
  Widget build(BuildContext context) {
    // 保证 tableData 与 game.gameSequence 同步：页面切换或重建时恢复卡片列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final seq = game.gameSequence;
      final needsSync = (tableData.isEmpty && seq.isNotEmpty) || tableData.length != seq.length || tableData.any((e) => !seq.contains(e['column1']));
      if (needsSync) {
        setState(() {
          tableData = seq.map((id) => {'column1': id}).toList();
          if (selectedIndex != null && !game.players.containsKey(selectedIndex)) selectedIndex = null;
        });
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnS Info'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () => _resetGameTurn(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('重置计分'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const GameLoggerWindow(),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('查看日志'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 顶部操作栏 - 自适应矩阵式按钮
            LayoutBuilder(
              builder: (context, constraints) {
                const double narrowWidthThreshold = 600; // 窄屏阈值（px）
                final double width = constraints.maxWidth;

                // 自适应列数：窄屏强制 2 列，宽屏按宽度计算列数并限制在 3-6 列
                int columns;
                if (width < narrowWidthThreshold) {
                  columns = 3;
                } else {
                  columns = (width / 180).floor();
                  if (columns < 3) columns = 3;
                  if (columns > 6) columns = 6;
                }

                // 按钮规格：label 与对应的 onPressed（为 null 表示禁用）
                // 已将部分按钮移动到回合卡片或 AppBar，因此这里移除它们
                final List<Map<String, dynamic>> specs = [
                  {'label': '添加角色', 'on': game.gameState == GameState.waiting ? () => _showAddCharacterDialog() : null},
                  {'label': '删除角色', 'on': (selectedIndex != null && game.gameState == GameState.waiting) ? _deleteSelectedRow : null},
                  {'label': '编辑属性', 'on': (selectedIndex != null) ? _showAttributeSettingsDialog : null},
                  {'label': '切换模式\n${game.gameType.name}', 'on': game.gameState == GameState.waiting ? () => game.toggleGameType() : null},
                  {'label': '队伍管理', 'on': (game.gameState == GameState.waiting && game.gameType == GameType.team) ? () => _showTeamManagerDialog() : null},
                  {'label': '新建', 'on': () => _createNewSave()},
                  {'label': '加载', 'on': () => _showLoadDialog()},
                  {'label': '保存', 'on': () => _saveGameToFile()},
                  {'label': '抽取技能', 'on': () { showDialog(context: context, builder: (context) => const SkillRollingDialog()); }},
                ];

                // 固定按钮高度并让按钮填充单元格
                const double buttonHeight = 36;

                // 统一按钮样式构造器：按钮会扩展填充格子
                Widget buildActionButton(Map<String, dynamic> spec) {
                  final VoidCallback? onPressed = spec['on'] as VoidCallback?;
                  return SizedBox.expand(
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 14),
                        minimumSize: const Size(64, buttonHeight),
                      ),
                      child: Center(child: Text(spec['label'].toString(), textAlign: TextAlign.center)),
                    ),
                  );
                }

                // 使用 GridView 并通过 SliverGridDelegate 设置每个格子的固定高度（mainAxisExtent）
                return GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: buttonHeight,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: specs.map(buildActionButton).toList(),
                );
              },
            ),
            
            const SizedBox(height: 16.0),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // 2. 当前回合进度显示区域
                Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('当前回合       ${game.round}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('当前轮次       ${game.turn}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('额外回合       ${game.extra}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),

                Builder(
                  builder: (context) {
                  // 统一获取历史提供者和判断撤销/重做可用性
                    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                    final bool canUndo = historyProvider.currentHistoryIndex > 0;
                    final bool canRedo = historyProvider.currentHistoryIndex < historyProvider.history.length - 1;
                    const double smallButtonHeight = 36;

                    return Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              height: smallButtonHeight,
                              child: ElevatedButton(
                                onPressed: canUndo ? _undo : null,
                                style: ElevatedButton.styleFrom(minimumSize: const Size(120, smallButtonHeight)),
                                child: const Text('撤销'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: smallButtonHeight,
                              child: ElevatedButton(
                                onPressed: canRedo ? _redo : null,
                                style: ElevatedButton.styleFrom(minimumSize: const Size(120, smallButtonHeight)),
                                child: const Text('重做'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            SizedBox(
                              height: smallButtonHeight,
                              child: ElevatedButton(
                                onPressed: game.players.keys.length < 3 ? null : () => _showAddActionDialog(),
                                style: ElevatedButton.styleFrom(minimumSize: const Size(120, smallButtonHeight)),
                                child: const Text('添加行动'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: smallButtonHeight,
                              child: ElevatedButton(
                                onPressed: game.players.keys.length < 3 ? null : () => _changeGameTurn(),
                                style: ElevatedButton.styleFrom(minimumSize: const Size(120, smallButtonHeight)),
                                child: const Text('轮次变更'),
                              ),
                            ),
                          ],
                        ),
                      ],      
                    );
                  },
                ),
              ],
            ),
            

            // 卡片式显示角色信息（响应式：当单个卡片宽度超过1100时分两列），卡片高度自适应
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final int columns = width > 1100 ? 2 : 1;
                final double spacing = 12;
                final double itemWidth = (width - (columns - 1) * spacing) / columns;
                final roles = tableData.map((e) => e['column1'] as String).where((r) => game.players.containsKey(r)).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: roles.map((roleName) {
                      final character = game.players[roleName]!;
                      int health = character.health;
                      int armor = character.armor;
                      int attack = character.attack;
                      int defence = character.defence;
                      int movePoint = character.movePoint;
                      int maxMovePoint = character.maxMove;
                      int cardCount = character.cardCount;
                      Map<String, List<dynamic>> status = character.status;
                      Map<String, List<dynamic>> hiddenStatus = character.hiddenStatus;
                      Map<String, int> skill = character.skill;

                      final bool isSelected = selectedIndex == roleName;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = isSelected ? null : roleName;
                          });
                        },
                        child: SizedBox(
                          width: itemWidth,
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8.0),
                              border: isSelected
                                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                                  : Border.all(color: Colors.grey.shade300, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 顶部: 名称 + 血量/护盾指示
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        roleName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: character.isDead ? Colors.grey : _getTeamColor(game.getPlayerTeam(roleName))),
                                      ),
                                    ),
                                    // 简短的生命数值和护盾图标
                                    Row(
                                      children: [
                                        if (armor > 0) ...[
                                          const Icon(Icons.health_and_safety, color: Colors.blueGrey, size: 16),
                                          const SizedBox(width: 4),
                                          Text('$armor', style: const TextStyle(fontSize: 14)),
                                          const SizedBox(width: 8),
                                        ],
                                        const Icon(Icons.water_drop, color: Colors.redAccent, size: 16),
                                        const SizedBox(width: 4),
                                        Text('$health / ${character.maxHealth}', style: const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ],
                                ),

                                // 生命值
                                if (!character.isDead) LayoutBuilder(builder: (context, box) {
                                  final double fullW = box.maxWidth;
                                  final double pct = (character.maxHealth > 0) ? (health / character.maxHealth).clamp(0.0, 1.0) : 0.0;
                                  final double greenW = fullW * pct;
                                  final double armorPct = (character.maxHealth > 0) ? (armor / character.maxHealth).clamp(0.0, 1.0) : 0.0;
                                  double armorW = fullW * armorPct;
                                  if (armor > health) armorW = greenW;

                                  return SizedBox(
                                    height: 6,
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        // 健康背景（淡绿色、左对齐）
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: greenW,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: Colors.lightBlue,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                        // 护盾叠加在血量上，右侧与血量右边界对齐（白色）
                                        if (armor > 0)
                                          Positioned(
                                            left: (greenW - armorW).clamp(0.0, fullW),
                                            top: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: armorW,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: Colors.lightBlue[100],
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.blueGrey[200]!, width: 0.5),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 4),

                                // 属性行
                                Row(
                                  children: [
                                    Icon(Icons.gps_fixed, color: Colors.blue, size: 16),
                                    const SizedBox(width: 4),
                                    Text('$attack', style: const TextStyle(fontSize: 15)),
                                    const Spacer(),
                                    Icon(Icons.shield, color: Colors.blue, size: 16),
                                    const SizedBox(width: 4),
                                    Text('$defence', style: const TextStyle(fontSize: 15)),
                                    const Spacer(),
                                    Icon(Icons.bolt, color: Colors.blue, size: 20),
                                    Text('$movePoint / $maxMovePoint', style: const TextStyle(fontSize: 15)),
                                    const Spacer(),
                                    Icon(Icons.style, color: Colors.blue, size: 16),
                                    const SizedBox(width: 4),
                                    Text('$cardCount', style: const TextStyle(fontSize: 15)),
                                    const Spacer(),
                                  ],
                                ),

                                // 状态组（图标与具体状态同一行，具体状态每行四个）
                                if (!character.isDead && (status.isNotEmpty || hiddenStatus.isNotEmpty)) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.auto_awesome, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: LayoutBuilder(builder: (context, box) {
                                          final double innerW = box.maxWidth;
                                          final double smallSpacing = 6;
                                          final double smallItemW = (innerW - smallSpacing * 3) / 4;
                                          List<Widget> chips = [];

                                          status.forEach((k, v) {
                                            final int layers = (v.isNotEmpty) ? (v[0] as int) : 0;
                                            final dynamic intensity = (v.length > 1) ? v[1] : '';
                                            chips.add(_buildStatusCard(k, intensity, layers.toString(), smallItemW, hidden: false));
                                          });
                                          hiddenStatus.forEach((k, v) {
                                            final int layers = (v.isNotEmpty) ? (v[0] as int) : 0;
                                            final dynamic intensity = (v.length > 1) ? v[1] : '';
                                            chips.add(_buildStatusCard(k, intensity, layers.toString(), smallItemW, hidden: true));
                                          });

                                          return Wrap(spacing: smallSpacing, runSpacing: smallSpacing, children: chips);
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                // 技能组（图标与具体技能同一行，具体技能每行四个）
                                if (skill.isNotEmpty) ...[
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.auto_fix_high, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: LayoutBuilder(builder: (context, box) {
                                          final double innerW = box.maxWidth;
                                          final double smallSpacing = 6;
                                          final double smallItemW = (innerW - smallSpacing * 3) / 4;
                                          List<Widget> chips = [];
                                          skill.forEach((k, v) {
                                            chips.add(_buildSkillCard(k, v.toString(), smallItemW));
                                          });
                                          return Wrap(spacing: smallSpacing, runSpacing: smallSpacing, children: chips);
                                        }),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // 2. 弹出添加角色对话框（长列表：按拼音首字母分组、每组内矩阵排列、可滚动）
  void _showAddCharacterDialog() {
    // 准备数据源：所有可添加的角色名（来自 characterData keys），剔除已在游戏中的
    final allNames = characterData?.keys.toList() ?? [];
    allNames.remove('角色');
    final available = allNames.where((name) => !game.players.keys.contains(name)).toList();

    // 生成分组 map：首字母 -> list of names
    Map<String, List<String>> groups = {};
    for (var name in available) {
      String initial;
      try {
        final short = PinyinHelper.getShortPinyin(name);
        initial = short.isNotEmpty ? short[0].toUpperCase() : name[0].toUpperCase();
      } catch (_) {
        initial = name.isNotEmpty ? name[0].toUpperCase() : '#';
      }
      if (!RegExp(r'[A-Z]').hasMatch(initial)) initial = '#';
      groups.putIfAbsent(initial, () => []).add(name);
    }

    // 对每个组内按完整拼音排序
    for (var key in groups.keys) {
      groups[key]!.sort((a, b) {
        final pa = PinyinHelper.getPinyinE(a, separator: '');
        final pb = PinyinHelper.getPinyinE(b, separator: '');
        return pa.compareTo(pb);
      });
    }

    // 组 keys 排序（字母顺序，# 放最后）
    final sortedKeys = groups.keys.toList()..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          child: LayoutBuilder(builder: (context, constraints) {
            final double maxW = constraints.maxWidth > 600 ? 600 : constraints.maxWidth;
            return SizedBox(
              width: maxW,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Expanded(child: Text('添加角色', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Scrollbar(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, idx) {
                          final key = sortedKeys[idx];
                          final names = groups[key]!;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 分组标题
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Text(key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                                // 矩阵：自适应列数（3-6）
                                LayoutBuilder(builder: (context, box) {
                                  final double w = box.maxWidth;
                                  int columns = (w / 140).floor();
                                  if (columns < 3) columns = 3;
                                  if (columns > 6) columns = 6;

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      mainAxisExtent: 40,
                                    ),
                                    itemCount: names.length,
                                    itemBuilder: (context, i) {
                                      final name = names[i];
                                      return ElevatedButton(
                                        onPressed: () {
                                          // 添加角色并关闭对话框
                                          setState(() {
                                            int health = characterTypeData?[characterData?[name][0]][0] ?? 0;
                                            int attack = characterTypeData?[characterData?[name][0]][1] ?? 0;
                                            int defence = characterTypeData?[characterData?[name][0]][2] ?? 0;
                                            int movePoint = 0;
                                            int maxMove = regenerateTypeData?[characterData?[name][1]][0] ?? 0;
                                            int moveRegen = regenerateTypeData?[characterData?[name][1]][1] ?? 0;
                                            int regenType = regenerateTypeData?[characterData?[name][1]][2] ?? 0;
                                            int regenTurn = regenerateTypeData?[characterData?[name][1]][3] ?? 0;
                                            Character character = Character(name, health, attack, defence, movePoint, maxMove, moveRegen, regenType, regenTurn);
                                            game.addPlayer(character);
                                            tableData.add({'column1': name});
                                          });
                                          Navigator.of(ctx).pop();
                                        },
                                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                                        child: Text(name, textAlign: TextAlign.center),
                                      );
                                    },
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      }
    );
  }

  /*
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
  */

  // 队伍管理弹窗
  void _showTeamManagerDialog(){
    showDialog(
      context: context,
      builder: (BuildContext context){
        return StatefulBuilder(
          builder: (context, setStateDialog){
            var teamKeys = game.teams.keys.toList()..sort();
            final allPlayers = game.gameSequence.toList();

            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('  队伍管理', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          ElevatedButton.icon(
                            onPressed: (){
                              setStateDialog((){
                                game.addTeam();
                              });
                              game.refresh();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('添加队伍'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: teamKeys.isEmpty ? null : (){
                              setStateDialog((){
                                // 删除最后一个队伍
                                final last = teamKeys.isNotEmpty ? teamKeys.last : null;
                                if (last != null) game.removeTeam(last);
                              });
                              game.refresh();
                            },
                            icon: const Icon(Icons.remove, color: Colors.white),
                            label: const Text('减少队伍', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // 列出每个队伍：标题 + 网格按钮（每个角色一个按钮，已选中表示在该队伍中）
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: teamKeys.map((tid) {
                              final members = game.teams[tid] ?? <String>{};
                              return Card(
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('  队伍 $tid', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const Spacer(),
                                          IconButton(
                                            onPressed: (){
                                              setStateDialog((){
                                                game.removeTeam(tid);
                                              });
                                              game.refresh();
                                            },
                                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                                          )
                                        ],
                                      ),

                                      // 按钮网格：每个角色为按钮，四列
                                      LayoutBuilder(builder: (context, box) {
                                        final double w = box.maxWidth;
                                        final int columns = 3;
                                        final double itemW = (w - (columns - 1) * 8) / columns;
                                        return Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: allPlayers.map((p) {
                                            final bool selected = members.contains(p);
                                            return SizedBox(
                                              width: itemW,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: selected ? Theme.of(context).colorScheme.primary : null,
                                                  foregroundColor: selected ? Colors.white : null,
                                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                                ),
                                                onPressed: (){
                                                  setStateDialog((){
                                                    if (selected) {
                                                      // 从当前队伍移除
                                                      game.removePlayerFromTeam(tid, p);
                                                    } else {
                                                      // 确保该角色在其他队伍中被移除
                                                      for (var key in game.teams.keys.toList()){
                                                        if (game.teams[key]!.contains(p)) {
                                                          game.removePlayerFromTeam(key, p);
                                                        }
                                                      }
                                                      game.addPlayerToTeam(tid, p);
                                                    }
                                                  });
                                                  game.refresh();
                                                },
                                                child: Text(p, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('关闭'))),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  // 4. 删除选中行（更新表格数据和选中状态）
  void _deleteSelectedRow() {
    setState(() {
      if (selectedIndex == null) return;
      String roleName = selectedIndex!;
      game.removePlayer(game.players[roleName]!);
      final idx = tableData.indexWhere((e) => e['column1'] == roleName);
      if (idx != -1) tableData.removeAt(idx);
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

  // 新增方法：显示编辑属性的弹窗
  void _showAttributeSettingsDialog() {
    if (selectedIndex == null || tableData.indexWhere((e) => e['column1'] == selectedIndex) == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个角色')),
      );
      return;
    }
    String roleName = selectedIndex!;
    Character? character = game.players[roleName];

    if (character == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('角色不存在')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AttributeSettingsDialog(
          character: character,
          onSave: () {
            setState(() {
              _saveCurrentStateToHistory();
            });
          },
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
    _saveCurrentStateToHistory(); // 此处仍然存在问题：清空后添加角色，删除角色再回退会导致报错
  }

  // 小卡片：状态展示（右上角圈点表示层数，卡片内部右侧显示强度；hidden 为 true 时文字灰色）
  Widget _buildStatusCard(String name, int layers, String intensity, double width, {bool hidden = false}) {
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            decoration: BoxDecoration(
              color: hidden ? Colors.grey.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 12, color: hidden ? Colors.grey : Colors.black87,),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(intensity, style: TextStyle(fontSize: 12, color: hidden ? Colors.grey : Colors.black87, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),              
              ],
            ),
          ),
          // 右上角圈点表示层数
          if (layers > 0)
            Positioned(
              right: -4,
              top: -4,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: Colors.cyan[900],
                child: Text(layers.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  // 小卡片：技能展示（卡片内部右侧显示数值）
  Widget _buildSkillCard(String name, String value, double width) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 0.8),
        ),
        child: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 释放控制器避免内存泄漏
    game.removeListener(_handleGameChange);
    _horizontalScrollController.dispose();
    super.dispose();
  }
}