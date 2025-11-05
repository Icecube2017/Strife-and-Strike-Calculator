import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:sns_calculator/history.dart';
import 'package:sns_calculator/settings.dart';
import 'dart:convert';
import 'game.dart';
import 'assets.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MyAppState()),
        ChangeNotifierProvider(create: (context) => HistoryProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = InfoPage();
        break;
      case 1:
        page = Placeholder();
        break;
      case 2:
        page = Placeholder();
        break;
    default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search),
                      label: Text('Search'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history),
                      label: Text('History'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

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
    _loadAssetsData();
    game = GameManager().game;

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

  // 读取并解析JSON文件
  Future<void> _loadAssetsData() async {
    AssetsManager assets = AssetsManager();
    await assets.loadData();

    langMap = assets.langMap;
    characterData = assets.characterData;
    characterTypeData = assets.characterTypeData;
    regenerateTypeData = assets.regenerateTypeData;

    dropdownItems = characterData!.keys.toList();
  }

  // 保存当前游戏状态到历史记录
void _saveCurrentStateToHistory() {
  final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
  String currentState = _serializeGameState();
  historyProvider.saveCurrentStateToHistory(currentState);  
}

// 将游戏状态序列化为JSON字符串
String _serializeGameState() {
  Map<String, dynamic> gameState = {
    'gameId': game.id,
    'gameSequence': game.gameSequence,
    'players': {},
    'playerDied': game.playerDied,
    'teams': game.teams,
    'gameType': game.gameType,
    'playerCount': game.playerCount,
    'turn': game.turn,
    'round': game.round,
    'teamCount': game.teamCount,
    'countdown': {
      'damocles': game.countdown.damocles,
      'eden': game.countdown.eden,
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
      'damageReceivedTotal': character.damageReceivedTotal,
      'damageDealtTotal': character.damageDealtTotal,
      'damageReceivedRound' : character.damageReceivedRound,
      'damageDealtRound': character.damageDealtRound,
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
  Map<String, dynamic> gameState = jsonDecode(stateJson);
  
  // 恢复游戏基本属性
  game.gameSequence = List<String>.from(gameState['gameSequence']);
  game.playerDied = gameState['playerDied'];
  game.teams = gameState['teams'];
  game.gameType = gameState['gameType'];
  game.playerCount = gameState['playerCount'];
  game.turn = gameState['turn'];
  game.round = gameState['round'];
  game.teamCount = gameState['teamCount'];
  game.countdown.damocles = gameState['countdown']['damocles'];
  game.countdown.eden = gameState['countdown']['eden'];
  
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
    character.damageReceivedTotal = playerData['damageReceivedTotal'];
    character.damageDealtTotal = playerData['damageDealtTotal'];
    character.damageReceivedRound = playerData['damageReceivedRound'];
    character.damageDealtRound = playerData['damageDealtRound'];
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
                        //_logger.d(statusText);
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
                            DataCell(Text(roleName)),
                            DataCell(Text('${health.toString()}(${armor.toString()})')),
                            DataCell(Text(attack.toString())),
                            DataCell(Text(defence.toString())),
                            DataCell(Text('${movePoint.toString()}/${maxMovePoint.toString()}')),
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
      if (selectedValue != null) {
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
    game.clearGame();
    tableData.clear();
    game.refresh();
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

class AddActionDialog extends StatefulWidget {
  final List<String> characterList;
  final VoidCallback? onActionCompleted; 

  const AddActionDialog({
    Key? key, 
    required this.characterList,
    this.onActionCompleted,
  }) : super(key: key);

  @override
  _AddActionDialogState createState() => _AddActionDialogState();
}

class _AddActionDialogState extends State<AddActionDialog> {
  // 第一个下拉菜单选项
  final List<String> _actionTypes = ['行动', '技能', '特质'];
  
  // 各个下拉菜单的当前选中值
  String? _actionType;
  String? _source;
  String? _target;
  String? _selectedSkill;

  // 技能额外目标列表
  final List<String> _skillTargetList = [];
  
  // 道具卡数据
  List<String>? cardTypes;

  // 技能数据
  Map<String, dynamic>? skillData;

  // 语言数据
  Map<String, dynamic>? langMap;
  
  // 道具卡表格数据
  final List<Map<String, dynamic>> _cardTableData = [];

  // 攻击特效表格数据
  final List<Map<String, dynamic>> _attackEffectTableData = [];
  
  // 防守特效表格数据
  final List<Map<String, dynamic>> _defenceEffectTableData = [];

  // 技能设置
  // 仁慈
  String? _benevolenceChoice;
  // 恐吓
  int? _intimidationPoint;

  // 日志系统
  static final Logger _logger = Logger();

  // 点数输入控制器
  final TextEditingController _pointController = TextEditingController();

  // 游戏数据读取
  Game game = GameManager().game;

  @override
  void initState() {
    super.initState();
    _loadAssetsData();
    // 限制只能输入数字
    _pointController.addListener(() {
      final text = _pointController.text;
      if (text.isNotEmpty && int.tryParse(text) == null) {
        _pointController.value = TextEditingValue(
          text: text.replaceAll(RegExp(r'[^0-9]'), ''),
          selection: TextSelection.fromPosition(
            TextPosition(offset: text.replaceAll(RegExp(r'[^0-9]'), '').length),
          ),
        );
      }
    });
  }

  // 读取并解析JSON文件
  Future<void> _loadAssetsData() async {
    AssetsManager assets = AssetsManager();
    await assets.loadData();

    cardTypes = assets.cardTypes;
    skillData = assets.skillData;
    langMap = assets.langMap;
  }

  // 显示道具卡选择菜单
  void _showCardSelectionMenu() {
    if (cardTypes == null) return;
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(0, 0, 0, 0),
      items: cardTypes!.map((String item) {
        return PopupMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
    ).then((String? selectedValue) {
      if (selectedValue != null) {
        setState(() {
          // 添加到表格数据中
          _cardTableData.add({
            'cardName': selectedValue,
            'settings': <String, dynamic>{}, // 可用于存储该行的设置
          });
        });
      }
    });
  }

  // 删除道具卡行
  void _deleteCardRow(int index) {
    setState(() {
      _cardTableData.removeAt(index);
    });
  }

  // 显示道具卡设置窗口
  void _showCardSettingsDialog(int index, String cardName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CardSettingsDialog(
          cardName: cardName,
          initialSettings: Map<String, dynamic>.from(_cardTableData[index]['settings']),
          onSettingsChanged: (settings) {
            setState(() {
              _cardTableData[index]['settings'] = settings;
            });
          },
          source: _source,
          target: _target,
        );
      },
    );
  }

  // 显示攻击特效选择菜单
  void _showAttackEffectSelectionMenu() {
    final List<AttackEffect> attackEffects = AttackEffect.values;
  
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromCenter(
          center: Offset(0, MediaQuery.of(context).size.height / 2), 
          width: 200, 
          height: 300),
          Offset.zero & MediaQuery.of(context).size,
      ),
      items: attackEffects.map((AttackEffect effect) {
        return PopupMenuItem(
          value: effect,
          child: Text(effect.effectId),
        );
      }).toList(),
    ).then((AttackEffect? selectedEffect) {
      if (selectedEffect != null) {
        setState(() {
          // 添加到攻击特效表格数据中
          _attackEffectTableData.add({
            'effect': selectedEffect,
            'settings': <String, dynamic>{}, // 可用于存储该行的设置
          });
        });
      }
    });
  }

  // 删除攻击特效行
  void _deleteAttackEffectRow(int index) {
    setState(() {
      _attackEffectTableData.removeAt(index);
    });
  }

  // 显示攻击特效设置窗口
  void _showAttackEffectSettingsDialog(int index, AttackEffect effect) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AttackEffectSettingsDialog(
          effect: effect,
          initialSettings: Map<String, dynamic>.from(_attackEffectTableData[index]['settings']),
          onSettingsChanged: (settings) {
            setState(() {
              _attackEffectTableData[index]['settings'] = settings;
            });
          },
        );
      },
    );
  }

  // 显示防守特效选择菜单
  void _showDefenceEffectSelectionMenu() {
    final List<DefenceEffect> defenceEffects = DefenceEffect.values;
  
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromCenter(
          center: Offset(0, MediaQuery.of(context).size.height / 2), 
          width: 200, 
          height: 300),
          Offset.zero & MediaQuery.of(context).size,
      ),
      items: defenceEffects.map((DefenceEffect effect) {
        return PopupMenuItem(
          value: effect,
          child: Text(effect.effectId),
        );
      }).toList(),
    ).then((DefenceEffect? selectedEffect) {
      if (selectedEffect != null) {
        setState(() {
          // 添加到防守特效表格数据中
          _defenceEffectTableData.add({
            'effect': selectedEffect,
            'settings': <String, dynamic>{}, // 可用于存储该行的设置
          });
        });
      }
    });
  }

  // 删除防守特效行
  void _deleteDefenceEffectRow(int index) {
    setState(() {
      _defenceEffectTableData.removeAt(index);
    });
  }

  // 显示防守特效设置窗口
  void _showDefenceEffectSettingsDialog(int index, DefenceEffect effect) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DefenceEffectSettingsDialog(
          effect: effect,
          initialSettings: Map<String, dynamic>.from(_defenceEffectTableData[index]['settings']),
          onSettingsChanged: (settings) {
            setState(() {
              _defenceEffectTableData[index]['settings'] = settings;
            });
          },
        );
      },
    );
  }

  // 添加技能目标的方法
  void _addSkillTarget(String target) {
    setState(() {
      _skillTargetList.add(target);
    });
  }

  // 删除技能目标的方法
  void _removeSkillTarget(int index) {
    setState(() {
      _skillTargetList.removeAt(index);
    });
  }

  // 显示技能目标选择菜单
  void _showSkillTargetSelectionMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(0, 0, 0, 0),
      items: widget.characterList.map((String item) {
        return PopupMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
    ).then((String? selectedValue) {
      if (selectedValue != null) {
        _addSkillTarget(selectedValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('添加行动'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一个下拉菜单
              Text('行动类型', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _actionType,
                hint: Text('请选择行动类型'),
                items: _actionTypes.map((String item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _actionType = newValue;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
              
              // 第二个下拉菜单（来自表格第一列）
              Text('进攻角色', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _source,
                hint: Text('请选择第一个角色'),
                items: widget.characterList.map((String item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _source = newValue;
                    // 如果第三个下拉菜单选择了与第二个相同的角色，则重置
                    if (_target == newValue) {
                      _target = null;
                    }
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
              
              // 第三个下拉菜单（来自表格第一列，但排除第二个菜单已选择的项）
              Text('防守角色', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _target,
                hint: Text('请选择第二个角色'),
                items: widget.characterList
                    .where((item) => item != _source)
                    .map((String item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _target = newValue;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
              
              // 条件性显示的道具卡选择区域（仅在选择"行动"时显示）
              if (_actionType == '行动') ...[
                Text('道具卡', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),

                // 点数输入框
                TextFormField(
                  controller: _pointController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '点数',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                      return '请输入有效数字';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),

                ElevatedButton(
                  onPressed: _showCardSelectionMenu,
                  child: Text('添加道具卡'),
                ),
                SizedBox(height: 8),
                
                // 道具卡表格
                if (_cardTableData.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('名称')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: _cardTableData.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final Map<String, dynamic> rowData = entry.value;
                          final String cardName = rowData['cardName'];
                          
                          return DataRow(
                            cells: [
                              DataCell(Text(cardName)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 18),
                                      onPressed: () => _deleteCardRow(index),
                                      tooltip: '删除',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.settings, size: 18),
                                      onPressed: () => _showCardSettingsDialog(index, cardName),
                                      tooltip: '设置',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 16),
                // 添加攻击特效按钮
                ElevatedButton(
                  onPressed: _showAttackEffectSelectionMenu,
                  child: Text('添加攻击特效'),
                ),
                SizedBox(height: 8),
  
                // 攻击特效表格
                if (_attackEffectTableData.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('攻击特效')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: _attackEffectTableData.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final Map<String, dynamic> rowData = entry.value;
                          final AttackEffect effect = rowData['effect'];
            
                          return DataRow(
                            cells: [
                              DataCell(Text(effect.effectId)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 18),
                                      onPressed: () => _deleteAttackEffectRow(index),
                                      tooltip: '删除',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.settings, size: 18),
                                      onPressed: () => _showAttackEffectSettingsDialog(index, effect),
                                      tooltip: '设置',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 16),
                // 添加防守特效按钮
                ElevatedButton(
                  onPressed: _showDefenceEffectSelectionMenu,
                  child: Text('添加防守特效'),
                ),
                SizedBox(height: 8),
  
                // 防守特效表格
                if (_defenceEffectTableData.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('防守特效')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: _defenceEffectTableData.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final Map<String, dynamic> rowData = entry.value;
                          final DefenceEffect effect = rowData['effect'];
            
                          return DataRow(
                            cells: [
                              DataCell(Text(effect.effectId)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 18),
                                      onPressed: () => _deleteDefenceEffectRow(index),
                                      tooltip: '删除',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.settings, size: 18),
                                      onPressed: () => _showDefenceEffectSettingsDialog(index, effect),
                                      tooltip: '设置',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 16),
              ] else if (_actionType == '技能') ...[
                Text('技能目标', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _showSkillTargetSelectionMenu,
                  child: Text('添加技能目标')),
                SizedBox(height: 8),

                if(_skillTargetList.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('技能目标')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: _skillTargetList.asMap().entries.map((entry) { 
                          final int index = entry.key;
                          final String target = entry.value;
                            return DataRow(
                              cells: [
                                DataCell(Text(target)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 18),
                                        onPressed: () => _removeSkillTarget(index),
                                    )                                    ]
                                )
                              )
                            ]
                          );
                        }).toList(),
                      )
                    )
                  )
                ],
                SizedBox(height: 16),

                Text('技能选择', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  value: _selectedSkill,
                  hint: Text('请选择技能'),
                  items: skillData!.keys.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(), 
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSkill = newValue;
                    });
                  },
                  isExpanded: true,
                ),
                SizedBox(height: 16),

                if(_selectedSkill != null) ...[
                  Text('技能设置', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  if(_selectedSkill == langMap!['benevolence']) ... [
                    Text('仁慈选择', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      value: _benevolenceChoice,
                      hint: Text('请选择仁慈的效果'),
                      items: [
                        DropdownMenuItem(value: 'regen', child: Text('回复20%生命值')),
                        DropdownMenuItem(value: 'card', child: Text('抽2张牌')),
                      ], 
                      onChanged: (String? newValue) {
                        setState(() {
                          _benevolenceChoice = newValue;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16)
                  ] else if (_selectedSkill == langMap!['intimidation']) ...[
                    Text('恐吓点数', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      value: _intimidationPoint,
                      hint: Text('请选择恐吓点数'),
                      items: [
                        DropdownMenuItem(value: 1, child: Text('1')),
                        DropdownMenuItem(value: 2, child: Text('2')),
                        DropdownMenuItem(value: 3, child: Text('3')),
                        DropdownMenuItem(value: 4, child: Text('4')),
                        DropdownMenuItem(value: 5, child: Text('5')),
                        DropdownMenuItem(value: 6, child: Text('6'))
                      ],          
                      onChanged: (int? newValue) {
                        setState(() {
                          _intimidationPoint = newValue;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16)
                  ]
                ]
              ]              
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 关闭弹窗
          },
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            // 检查是否有 redstone 道具卡但未设置 statusProlonged
          bool hasInvalidRedstone = false;
          for (var rowData in _cardTableData) {
            String cardName = rowData['cardName'];
            Map<String, dynamic> settings = rowData['settings'];
      
            if (cardName == langMap!['redstone']) {
              try {
                String statusProlonged = settings['statusProlonged'] ?? '';
                if (statusProlonged.isEmpty) {
                  hasInvalidRedstone = true;
                  break;
                }
              } catch (e) {
                hasInvalidRedstone = true;
                break;
              }
            }
          }
    
          // 如果存在未正确设置的 redstone 道具卡，显示错误提示
          if (hasInvalidRedstone) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('设置不完整'),
            content: Text('检测到"后日谈"道具卡未正确设置，请打开道具卡设置页面完成设置。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('确定'),
              ),
            ],
          );
        },
      );
      return; // 阻止继续执行
            }
            if (_actionType == '行动') {
              String pointText = _pointController.text;
              if (pointText.isNotEmpty) {
                int? points = int.tryParse(pointText);
                if (points == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('请输入有效的点数')),
                  );
                  return;
                }
                // 伤害计算初始化
                int attack = 0;
                int defence = 0;
                int attackPlus = 0;
                double attackMulti = 1;
                // 遍历道具
                int cost = 0;
                for (var rowData in _cardTableData) {
                  cost += 1;
                  String cardName = rowData['cardName'];
                  Map<String, dynamic> settings = rowData['settings'];
                  // 破片水晶
                  if(cardName == langMap!['end_crystal']){                    
                    int crystalSelf = settings['crystalSelf'] as int? ?? 1;
                    int crystalMagic = settings['crystalMagic'] as int? ?? 1;                 
                    game.damagePlayer(_source!, _source!, (30 + 15 * crystalSelf), DamageType.magical);
                    for(Character chara in game.players.values){
                      if(chara.id != _source) game.damagePlayer(_source!, chara.id, (40 + 15 * crystalMagic), DamageType.magical);
                    }
                  }
                  // 阿波罗之箭
                  else if(cardName == langMap!['apollo_arrow']){
                    int minDefence = game.players[_target]!.defence;
                    for(Character chara in game.players.values){
                      if(chara.defence < minDefence){
                        minDefence = chara.defence;
                      }                      
                    }
                    if(minDefence == game.players[_target]!.defence){
                      game.addHiddenStatus(_target!, 'damageplus', 100, 1);
                    }
                  }
                  // 巴别塔
                  else if(cardName == langMap!['babel_tower']){
                    for(Character chara in game.players.values){
                      game.addHiddenStatus(chara.id, 'babel', 0, 1);
                    }
                  }
                  // 达摩克利斯之剑
                  else if(cardName == langMap!['damocles_sword']){
                    game.countdown.damocles += 1;                    
                  }
                  // 短刀
                  else if(cardName == langMap!['wood_sword']){
                    game.addAttribute(_source!, AttributeType.attack, 10);
                    if (game.players[_source]!.hasHiddenStatus('reinforcement')){
                      game.addAttribute(_source!, AttributeType.attack, 10);
                    }
                    // attackPlus += 10;
                  }
                  // 钝化术
                  else if(cardName == langMap!['slowness_spell']){
                    game.addStatus(_target!, langMap!['slowness'], 1, 2);
                  }
                  // 堕灵吊坠
                  else if(cardName == langMap!['corrupt_pendant']){
                    game.addAttribute(_source!, AttributeType.attack, 5);
                    game.addAttribute(_target!, AttributeType.attack, -5);
                    game.damagePlayer(_source!, _source!, 60, DamageType.heal);
                    game.damagePlayer(_source!, _target!, 60, DamageType.magical);                    
                  }
                  // 飞鸟·紫烈
                  else if(cardName == langMap!['violent_violet']){
                    int sequence = game.gameSequence.indexOf(_source!);
                    if(sequence == 0) {sequence = game.gameSequence.length - 1;}
                    else {sequence--;}
                    Character previousChara = game.players[game.gameSequence[sequence]]!;
                    // _logger.d(previousChara.id);
                    game.addHiddenStatus(_target!, 'damageplus', previousChara.defence * 2, 1);
                  }
                  // 复合弓
                  else if(cardName == langMap!['bow']){                    
                    int ammoCount = settings['ammoCount'] as int? ?? 1;
                    game.damagePlayer(_source!, _target!, 75 * ammoCount, DamageType.magical);
                    game.players[_source]!.cardCount = 0;
                  }
                  // 高帽子
                  else if(cardName == langMap!['high_cap']){
                    game.addStatus(_target!, langMap!['tigris_dilemma'], 0, 1);
                  }
                  // 高能罐头
                  else if(cardName == langMap!['high_energy_can']){
                    game.addAttribute(_source!, AttributeType.movepoint, 1);
                    game.addAttribute(_source!, AttributeType.maxmove, 2);
                  }
                  // 鼓舞
                  else if(cardName == langMap!['hero_legend']){
                    game.damagePlayer(_source!, _source!, 100, DamageType.heal);
                    game.addHiddenStatus(_source!, 'hero_legend', 0, 1);
                  }
                  // 过往凝视
                  else if(cardName == langMap!['passing_gaze']){
                    game.addHiddenStatus(_target!, 'damageplus', 100, 1);
                    game.addStatus(_target!, langMap!['dissociated'], 0, 2);
                  }
                  // 寒绝凝冰
                  else if(cardName == langMap!['cryotheum']){
                    game.addStatus(_target!, langMap!['frost'], 5, 2);
                  }
                  // 后日谈
                  else if(cardName == langMap!['redstone']){
                    String statusProlonged = settings['statusProlonged'];
                    String playerProlonged = settings['playerProlonged'];         
                    if(statusProlonged != ''){
                      game.addStatus(playerProlonged, statusProlonged, 0, 1);
                    }                               
                  }
                  // 护身符
                  else if(cardName == langMap!['heart_locket']){
                    game.addAttribute(_source!, AttributeType.defence, 10);
                  }
                  // 缓生
                  else if(cardName == langMap!['regenerating']){
                    game.addStatus(_source!, langMap!['regeneration'], 4, 2);
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  // 混沌电钻
                  else if(cardName == langMap!['chaotic_drill']){
                    game.addStatus(_target!, langMap!['confusion'], 0, 1);
                  }
                  // 混乱力场
                  else if(cardName == langMap!['ascension_stair']){
                    Map ascensionPoints = settings['ascensionPoints'];
                    _logger.d(ascensionPoints);
                    int minPoint = 6;
                    int maxPoint = 1;
                    List<String> ascensionChara = [];
                    for(String chara in ascensionPoints.keys){ 
                      if(ascensionPoints[chara] == minPoint){
                        ascensionChara.add(chara);
                      }
                      else if(ascensionPoints[chara] < minPoint){
                        minPoint = ascensionPoints[chara];
                        ascensionChara = [chara];
                      }
                      if(ascensionPoints[chara] > maxPoint){
                        maxPoint = ascensionPoints[chara];
                      }
                    }
                    _logger.d(ascensionChara);
                    for(String chara in ascensionChara){
                      game.damagePlayer(_source!, chara, 50 * maxPoint, DamageType.physical);
                    }
                  }
                  // 极北之心
                  else if(cardName == langMap!['arctic_heart']){                    
                  }
                  // 极光震荡
                  else if(cardName == langMap!['aurora_concussion']){       
                    Map<String, int> auroraPoints = settings['auroraPoints'];
                    for(String chara in auroraPoints.keys){ 
                      if(auroraPoints[chara] == 1){
                        game.addStatus(chara, langMap!['exhausted'], 0, 1);
                      }
                    }
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  // 加护
                  else if(cardName == langMap!['dream_shelter']){
                    game.damagePlayer(_source!, _source!, 100, DamageType.heal);
                    game.addHiddenStatus(_source!, 'dream_shelter', 0, 1);
                  }
                  // 箭
                  else if(cardName == langMap!['arrow']){
                    game.addHiddenStatus(_target!, 'damageplus', 50, 1);
                  }
                  // 狼牙棒
                  else if(cardName == langMap!['mace']){
                    game.addHiddenStatus(_target!, 'damageplus', 90, 1);
                    game.addStatus(_target!, langMap!['fractured'], 0, 2);
                  }
                  // 猎魔灵刃
                  else if(cardName == langMap!['track']){                    
                    if(game.players[_target]!.hasStatus(langMap!['dodge'])){
                      game.removeStatus(_target!, langMap!['dodge']);
                      game.addHiddenStatus(_target!, 'track', 0, 1);
                    }               
                  }
                  // 林鸟·赤掠
                  else if(cardName == langMap!['crimson_swoop']){
                    int sequence = game.gameSequence.indexOf(_source!);
                    if(sequence == 0) {sequence = game.gameSequence.length - 1;}
                    else {sequence--;}
                    Character previousChara = game.players[game.gameSequence[sequence]]!;                    
                    game.addHiddenStatus(_target!, 'damageplus', previousChara.attack, 1);
                  }
                  // 聆音掠影
                  else if(cardName == langMap!['echo_glimpse']){
                    game.addStatus(_target!, langMap!['distant'], 0, 1);
                  }
                  // 蛮力术
                  else if(cardName == langMap!['strength_spell']){
                    game.addStatus(_source!, langMap!['strength'], 3, 2);
                  }
                  // 蛮力术II
                  else if(cardName == langMap!['strength_spell_ii']){
                    game.addStatus(_source!, langMap!['strength'], 6, 2);
                  }
                  // 纳米渗透
                  else if(cardName == langMap!['nano_permeation']){
                    game.addHiddenStatus(_source!, 'nano', 0, 1);
                  }
                  // 潘多拉魔盒
                  else if(cardName == langMap!['pandora_box']){
                    int pandoraPoint = settings['pandoraPoint'] as int? ?? 1;
                    if([3, 6].contains(pandoraPoint)){
                      for(Character chara in game.players.values){
                        game.damagePlayer(emptyCharacter.id, chara.id, 100, DamageType.heal);
                      }
                    }
                    else{
                      for(Character chara in game.players.values){
                        game.damagePlayer(emptyCharacter.id, chara.id, 300, DamageType.magical);
                      }
                    }
                    game.addHiddenStatus(_source!, 'void', 0, 1);   
                  }
                  // 全息投影
                  else if(cardName == langMap!['hologram']){
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  // 荣光循途
                  else if(cardName == langMap!['glory_road']){
                    game.addStatus(_source!, langMap!['teroxis'], 1, 1);
                  }
                  // 融甲宝珠
                  else if(cardName == langMap!['penetrate']){
                    if(game.players[_target]!.armor > 0){
                      game.players[_target]!.armor = 0;
                      game.addHiddenStatus(_target!, 'penetrate', 0, 1);
                    }
                  }
                  // 刷新
                  else if(cardName == langMap!['refreshment']){
                  }
                  // 水波荡漾
                  else if(cardName == langMap!['rippling_water']){
                    game.addStatus(_target!, langMap!['nebula'], 1, 1);
                  }
                  // 瞬疗
                  else if(cardName == langMap!['curing']){
                    game.damagePlayer(_source!, _source!, 120, DamageType.heal);
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  // 天穹尘埃之障
                  else if(cardName == langMap!['aether_shroud']){
                    game.addStatus(_target!, langMap!['oculus_veil'], 0, 1);
                  }
                  // 同调
                  else if(cardName == langMap!['homology']){
                    for(Character chara in game.players.values){
                      if(chara.id != _source){
                        for(String status in chara.status.keys){
                          game.addStatus(_source!, status, chara.getStatusIntensity(status), 
                          chara.getStatusLayer(status));
                        }
                      }
                    }
                  }
                  // 无敌贯通
                  else if(cardName == langMap!['critical_strike']){
                    game.addHiddenStatus(_source!, 'critical', 0, 1);
                  }
                  // 西西弗斯之石头
                  else if(cardName == langMap!['sisyphus_stone']){
                    game.addStatus(_target!, langMap!['grind'], 0, 1);
                  }
                  // 休憩
                  else if(cardName == langMap!['rest']){
                    cost -= 2;
                  }
                  // 迅捷术
                  else if(cardName == langMap!['swift_spell']){
                    game.addStatus(_source!, langMap!['swift'], 1, 2);
                  }
                  // 炎极烈火
                  else if(cardName == langMap!['pyrotheum']){
                    game.addStatus(_target!, langMap!['flaming'], 5, 3);
                  }
                  // 伊甸园
                  else if(cardName == "伊甸园"){
                    game.countdown.eden += 1;
                  }
                  // 遗失碎片
                  else if(cardName == langMap!['fragment']){
                    game.addAttribute(_source!,AttributeType.card, 2);
                    game.addHiddenStatus(_target!, 'damageplus', 45, 1);
                  }
                  // 隐身术
                  else if(cardName == langMap!['invisibility_spell']){
                    game.addStatus(_source!, langMap!['dodge'], 0, 1);
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  // 御术者长矛·炎
                  else if(cardName == langMap!['flame_spear']){
                    game.addStatus(_source!, langMap!['lumen_flare'], 0, 1);
                  }
                  // 御术者重盾·霜
                  else if(cardName == langMap!['frost_shield']){
                    game.addStatus(_source!, langMap!['erode_gelid'], 0, 1);
                  }
                  // 圆盾
                  else if(cardName == langMap!['shield']){
                    game.addAttribute(_source!, AttributeType.armor, 100);
                    game.addAttribute(_source!, AttributeType.defence, 5);
                  }
                  // 长剑
                  else if(cardName == langMap!['rapier']){
                    game.addAttribute(_source!, AttributeType.attack, 15);
                    // attackPlus += 15;
                  }
                  // 折射水晶
                  else if(cardName == langMap!['amethyst']){
                    int amethystPoint = settings['amethystPoint'] as int? ?? 1;
                    if (amethystPoint == 1){
                      game.addHiddenStatus(_target!, 'damageplus', 80, 1);
                    }
                    else{
                      game.addHiddenStatus(_target!, 'damageplus', -40, 1);
                    }
                  }
                  // 终焉长戟
                  else if(cardName == langMap!['end_halberd']){

                    game.addHiddenStatus(_target!, 'end', 0, 1);
                  }
                }

                // 行动点扣除
                if(game.players[_source]!.movePoint >= cost){
                  game.addAttribute(_source!, AttributeType.movepoint, -cost);
                }

                // 【烛焱】状态
                if(game.players[_source]!.hasStatus(langMap!['lumen_flare']) && 
                !game.players[_source]!.hasHiddenStatus('void')){
                  game.players[_source]!.status[langMap!['lumen_flare']]![3] += 1;
                }
                // 【磨砺】状态
                if(game.players[_source]!.hasStatus(langMap!['teroxis']) && 
                !game.players[_source]!.hasHiddenStatus('void')){
                  game.addStatus(_source!, langMap!['teroxis'], 1, 1);
                }

                // 应用攻击特效
                for (var effectData in _attackEffectTableData) {
                  AttackEffect effect = effectData['effect'];
                  Map<String, dynamic> settings = effectData['settings'];
  
                  // 【烛焱】特效
                  if (effect == AttackEffect.lumenFlare && game.players[_source]!.hasStatus(langMap!['lumen_flare'])) {
                    int lumenFlarePoint = settings['lumenFlarePoint'] as int? ?? 10;
                    if(game.players[_source]!.getStatusIntData(langMap!['lumen_flare']) % 3 == 0 &&
                      lumenFlarePoint <= 8 || lumenFlarePoint <= 2){
                        game.addStatus(_target!, langMap!['flaming'], 3, 1);
                    }
                  }
                  // 【障目】特效
                  if (effect == AttackEffect.oculusVeil && game.players[_source]!.hasStatus(langMap!['oculus_veil'])) {
                    int oculusVeilPoint = settings['oculusVeilPoint'] as int? ?? 2;
                    if (oculusVeilPoint == 1){
                      game.addHiddenStatus(_source!, 'void', 0, 1);
                    }
                  }
                }

                // 应用防守特效
                for (var effectData in _defenceEffectTableData) {
                  DefenceEffect effect = effectData['effect'];
                  Map<String, dynamic> settings = effectData['settings'];

                  // 【蚀凛】特效
                  if (effect == DefenceEffect.erodeGelid && game.players[_target]!.hasStatus(langMap!['erode_gelid'])) {
                    int erodeGelidPoint = settings['erodeGelidPoint'] as int? ?? 1;
                    if (erodeGelidPoint >= 9 - game.players[_target]!.getStatusIntData(langMap!['erode_gelid']) * 2){
                      game.addStatus(_source!, langMap!['frost'], 2, 1);
                      game.players[_target]!.status[langMap!['erode_gelid']]![3] = 0;
                    }
                    else {
                      game.players[_target]!.status[langMap!['erode_gelid']]![3] += 1;
                    }
                  }
                }
                
                // 计算伤害
                if(game.players[_source]!.hasHiddenStatus('hero_legend')){
                  attackPlus += 10;
                  game.removeHiddenStatus(_source!, 'hero_legend');
                }
                if(game.players[_target]!.hasHiddenStatus('dream_shelter')){
                  attackPlus -= 10;
                  game.removeHiddenStatus(_target!, 'dream_shelter');
                }
                if(game.players[_source]!.hasHiddenStatus('nano')){
                  attackPlus += game.players[_target]!.defence;
                  game.removeHiddenStatus(_source!, 'nano');
                }
                attack = game.players[_source]!.attack;
                defence = game.players[_target]!.defence;
                double baseDamage = ((attack + attackPlus) * attackMulti - defence) * points;
                game.damagePlayer(_source!, _target!, baseDamage.toInt(), DamageType.action);                     
              }
            }
            else if (_actionType == '技能') {
              final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

              // 技能是否可用
              bool skillAble = true;

              if (game.players[_source]!.skill.keys.contains(_selectedSkill)){
                if (game.players[_source]!.skill[_selectedSkill]! > 0){
                  skillAble = false;
                }
              }

              if (skillAble) {            
              // 仁慈
              if (_selectedSkill == langMap!['benevolence']) {
                String history = historyProvider.getStateAt(historyProvider.currentIndex - 1);
                Map<String, dynamic> gameState = jsonDecode(history);
                int previousHp = gameState['players'][_target]!['health'];
                game.addAttribute(_target!, AttributeType.health, previousHp - game.players[_target]!.health);
                if (_benevolenceChoice == 'card') {
                  game.addAttribute(_source!, AttributeType.card, 2);
                }
                else {
                  game.damagePlayer(_source!, _source!, (game.players[_source!]!.maxHealth * 0.2).toInt(), DamageType.heal);
                }
              }
              // 相转移
              else if (_selectedSkill == langMap!['phase_transition']){
                String history = historyProvider.getStateAt(historyProvider.currentIndex - 1);
                Map<String, dynamic> gameState = jsonDecode(history);
                int previousHp = gameState['players'][_source]!['health'];
                int transDamage = previousHp - game.players[_source]!.health;
                game.addAttribute(_source!, AttributeType.health, transDamage);
                game.damagePlayer(_source!, _target!, transDamage, DamageType.physical);
                // game.addHiddenStatus(_source!, 'transition', 0, 1);
              }
              // 天国邮递员
              else if (_selectedSkill == langMap!['heaven_delivery']){
                game.addHiddenStatus(_source!, 'heaven', 0, 1);
                game.addHiddenStatus(_target!, 'heaven', 0, 1);
              }
              // 净化
              else if (_selectedSkill == langMap!['purification']){
                List<dynamic> statusKeys = game.players[_target]!.status.keys.toList();
                for (var stat in statusKeys) {
                  if (![langMap!['teroxis'], langMap!['lumen_flare'], langMap!['erode_gelid']].contains(stat)){
                    game.removeStatus(_target!, stat);
                  }
                }
              }
              // 嗜血
              else if (_selectedSkill == langMap!['blood_thirsty']){
                String history = historyProvider.getStateAt(historyProvider.currentIndex - 1);
                Map<String, dynamic> gameState = jsonDecode(history);
                int damageDealt = gameState['players'][_source]!['damageDealtRound'];
                game.damagePlayer(_source!, _source!, ((game.players[_source]!.damageDealtRound - damageDealt) * 0.5).toInt(), DamageType.heal);
              }
              // 外星人
              else if (_selectedSkill == langMap!['stellar']) {
                game.addStatus(_target!, langMap!['stellar_cage'], 0, 1);
              }
              // 恐吓
              else if (_selectedSkill == langMap!['intimidation']){
                if ([3, 6].contains(_intimidationPoint)){
                  game.addHiddenStatus(_source!, 'intimidation', 0, 1);
                }
              }
              // 阈限
              else if (_selectedSkill == langMap!['threshold']){
                String history = historyProvider.getStateAt(historyProvider.currentIndex - 1);
                Map<String, dynamic> gameState = jsonDecode(history);
                int previousHp = gameState['players'][_source]!['health'];
                int thresholdDamage = previousHp - game.players[_source]!.health;
                if (thresholdDamage >= 250){
                  game.addAttribute(_source!, AttributeType.health, thresholdDamage - 100);
                }                
              }
              // 强化
              else if (_selectedSkill == langMap!['reinforcement']){
                game.addHiddenStatus(_source!, 'reinforcement', 0, 1);
              }
              // 技能进入CD
              if(_selectedSkill != null){
                game.players[_source]!.skill[_selectedSkill!] = skillData![_selectedSkill!][0];
              } 
              }             
            }
            // 调用回调函数通知 InfoPageState 保存历史记录
            if (widget.onActionCompleted != null) {
              widget.onActionCompleted!();
            }
            Navigator.of(context).pop(); // 关闭弹窗
          },
          child: Text('确定'),
        ),
      ],
    );
  }
}

// 道具卡设置对话框组件
class CardSettingsDialog extends StatefulWidget {
  final String cardName;
  final Map<String, dynamic> initialSettings;
  final Function(Map<String, dynamic>) onSettingsChanged;
  final String? source, target;

  const CardSettingsDialog({
    Key? key,
    required this.cardName,
    required this.initialSettings,
    required this.onSettingsChanged,
    this.source,
    this.target,

  }) : super(key: key);

  @override
  _CardSettingsDialogState createState() => _CardSettingsDialogState();
}

class _CardSettingsDialogState extends State<CardSettingsDialog> {
  late Map<String, dynamic> _settings;

  Game game = GameManager().game;

  Map<String, dynamic> ?langMap;

  //Logger _logger = Logger();
  
  // 破片水晶
  final List<String> _endCrystalOptions = ['1', '2', '3', '4', '5', '6', '7', '8'];
  int _crystalMagic = 1;
  int _crystalSelf = 1;
  // 复合弓
  final List<String> _bowOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  int _ammoCount = 1;
  // 后日谈
  List<String> _redstoneOptions = [];
  List<String> _redstonePlayerOptions = [];
  String _statusProlonged = '';
  String _playerProlonged = '';
  // 混乱力场
  final List<String> _ascensionStairOptions = ['1', '2', '3', '4', '5', '6'];
  Map<String, int> _ascensionPoints = {};
  // 极光震荡
  final List<String> _auroraOptions = ['1', '2'];
  Map<String, int> _auroraPoints = {};
  // 潘多拉魔盒
  final List<String> _pandoraBoxOptions = ['1', '2', '3', '4', '5', '6'];
  int _pandoraPoint = 1;
  // 折射水晶
  final List<String> _amethystOptions = ['1', '2'];
  int _amethystPoint = 1;

  @override
  void initState() {
    super.initState();
    _loadAssetsData();
    _settings = Map<String, dynamic>.from(widget.initialSettings);

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _crystalMagic = _settings['crystalMagic'] ?? settingsProvider.crystalMagic;
    _crystalSelf = _settings['crystalSelf'] ?? settingsProvider.crystalSelf;
    _ammoCount = _settings['ammoCount'] ?? settingsProvider.ammoCount;
    _redstonePlayerOptions = [widget.source!, widget.target!];
    _updateRedstoneOptions();
    _statusProlonged = _settings['statusProlonged'] ?? settingsProvider.statusProlonged;
    _playerProlonged = _settings['playerProlonged'] ?? settingsProvider.playerProlonged;
    if (_settings['ascensionPoints'] != null) {
      _ascensionPoints = Map<String, int>.from(_settings['ascensionPoints']);
    } else {
      _ascensionPoints = Map<String, int>.from(settingsProvider.ascensionPoints);
    }
    if (_settings['auroraPoints'] != null) {
      _auroraPoints = Map<String, int>.from(_settings['auroraPoints']);
    } else {
      _auroraPoints = Map<String, int>.from(settingsProvider.auroraPoints);
    }
    _pandoraPoint = _settings['pandoraPoint'] ?? settingsProvider.pandoraPoint;
    _amethystPoint = _settings['amethystPoint'] ?? settingsProvider.amethystPoint;
  }

  Future<void> _loadAssetsData() async {
    AssetsManager assets = AssetsManager();
    await assets.loadData();
    langMap = assets.langMap;
  }

  void _saveSettings() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    settingsProvider.setCrystalMagic(_crystalMagic);
    settingsProvider.setCrystalSelf(_crystalSelf);
    settingsProvider.setAmmoCount(_ammoCount);
    settingsProvider.setStatusProlonged(_statusProlonged);
    settingsProvider.setPlayerProlonged(_playerProlonged);
    settingsProvider.setAscensionPoints(_ascensionPoints);
    settingsProvider.setAuroraPoints(_auroraPoints);
    settingsProvider.setPandoraPoint(_pandoraPoint);
    settingsProvider.setAmethystPoint(_amethystPoint);

    Map<String, dynamic> _newSettings = {
      'crystalMagic': _crystalMagic,
      'crystalSelf': _crystalSelf,
      'ammoCount': _ammoCount,
      'statusProlonged': _statusProlonged,
      'playerProlonged': _playerProlonged,
      'ascensionPoints': _ascensionPoints,
      'auroraPoints': _auroraPoints,
      'pandoraPoint': _pandoraPoint,
      'amethystPoint': _amethystPoint,
    };
    widget.onSettingsChanged(_newSettings);
    Navigator.of(context).pop();
  }

  void _updateRedstoneOptions() {
    setState(() {
      if (_playerProlonged.isNotEmpty && game.players.containsKey(_playerProlonged)) {
        _redstoneOptions = game.players[_playerProlonged]!.status.keys.toList();
      } else {
        _redstoneOptions = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.cardName} 设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [                    
            // 仅当 cardName 为 "破片水晶" 时显示
            if (widget.cardName == "破片水晶") ...[
              Text('水晶2d4损血', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _crystalSelf,
                hint: Text('水晶2d4损血'),
                items: _endCrystalOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _crystalSelf = newValue ?? 0;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
              Text('水晶d8伤害', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _crystalMagic,
                hint: Text('水晶d8伤害'),
                items: _endCrystalOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _crystalMagic = newValue ?? 0;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ]
            else if (widget.cardName == "复合弓")...[
              Text('弃牌张数', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _ammoCount,
                hint: Text('弃牌张数'),
                items: _bowOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _ammoCount = newValue ?? 0;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ]
            else if(widget.cardName == "后日谈")...[
              Text('延长目标', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _playerProlonged.isEmpty ? null : _playerProlonged,
                hint: Text('延长目标'),
                items: _redstonePlayerOptions.map((String item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _playerProlonged = newValue ?? '';
                    _statusProlonged = '';
                    _updateRedstoneOptions();
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
              Text('状态延长', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _statusProlonged.isEmpty ? null : _statusProlonged,
                hint: Text('状态延长'),
                items: (_playerProlonged.isEmpty) ? [] :
                _redstoneOptions.map((String item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _statusProlonged = newValue ?? '';
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ]
            else if(widget.cardName == '混乱力场')...[
              Text('混乱点数', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ...game.gameSequence.map((playerId) {
              final player = game.players[playerId]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${player.id}:'),
                  DropdownButtonFormField<int>(
                    value: _ascensionPoints[playerId],
                    hint: Text('选择点数'),
                    items: _ascensionStairOptions.map((option) {
                      int value = int.parse(option);
                      return DropdownMenuItem(
                        value: value,
                        child: Text('$value'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        _ascensionPoints[playerId] = newValue ?? 1;
                      });
                    },
                    isExpanded: true,
                  ),
                 SizedBox(height: 8),
                ],
              );
             }),
            ]
            else if(widget.cardName == '极光震荡')...[
              Text('极光点数', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ...game.gameSequence.map((playerId) {
              final player = game.players[playerId]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${player.id}:'),
                  DropdownButtonFormField<int>(
                    value: _auroraPoints[playerId],
                    hint: Text('选择点数'),
                    items: _auroraOptions.map((option) {
                      int value = int.parse(option);
                      return DropdownMenuItem(
                        value: value,
                        child: Text('$value'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        _auroraPoints[playerId] = newValue ?? 1;
                      });
                    },
                    isExpanded: true,
                  ),
                 SizedBox(height: 8),
                ],
              );
             }),
            ]
            else if(widget.cardName == '潘多拉魔盒')...[
              Text('魔盒点数', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _pandoraPoint,
                hint: Text('魔盒点数'),
                items: _pandoraBoxOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _pandoraPoint = newValue ?? 0;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ] else if(widget.cardName == '折射水晶')...[
              Text('折射点数', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _amethystPoint,
                hint: Text('折射点数'),
                items: _amethystOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _amethystPoint = newValue ?? 0;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: Text('确定'),
        ),
      ],
    );
  }
}

// 攻击特效设置对话框组件
class AttackEffectSettingsDialog extends StatefulWidget {
  final AttackEffect effect;
  final Map<String, dynamic> initialSettings;
  final Function(Map<String, dynamic>) onSettingsChanged;
  final String? source, target;

  const AttackEffectSettingsDialog({
    Key? key,
    required this.effect,
    required this.initialSettings,
    required this.onSettingsChanged,
    this.source,
    this.target,
  }) : super(key: key);

  @override
  _AttackEffectSettingsDialogState createState() => _AttackEffectSettingsDialogState();
}

class _AttackEffectSettingsDialogState extends State<AttackEffectSettingsDialog> {
  late Map<String, dynamic> _settings;

  Game game = GameManager().game;

  Map<String, dynamic> ?langMap;

  // 烛焱
  final List<String> _lumenFlareOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  int _lumenFlarePoint = 1;
  // 障目
  final List<String> _oculusVeilOptions = ['1', '2'];
  int _oculusVeilPoint = 1;

  @override
  void initState() {
    super.initState();
    _settings = Map<String, dynamic>.from(widget.initialSettings);
    _lumenFlarePoint = _settings['lumenFlarePoint'] ?? 1;
    _oculusVeilPoint = _settings['oculusVeilPoint'] ?? 1;
  }

  void _saveSettings() {
    _settings['lumenFlarePoint'] = _lumenFlarePoint;
    _settings['oculusVeilPoint'] = _oculusVeilPoint;
    widget.onSettingsChanged(_settings);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.effect.effectId} 设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 根据不同的攻击特效显示不同的设置选项
            if (widget.effect == AttackEffect.lumenFlare) ...[
              Text('烛焱点数', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _lumenFlarePoint,
                hint: Text('烛焱点数'),
                items: _lumenFlareOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _lumenFlarePoint = newValue ?? 0;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ] else if (widget.effect == AttackEffect.oculusVeil) ...[
              Text('障目点数', style: TextStyle(fontWeight: FontWeight.bold)), 
              DropdownButtonFormField<int>(
                value: _oculusVeilPoint,
                hint: Text('障目点数'),
                items: _oculusVeilOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _oculusVeilPoint = newValue ?? 0;
                  });
                },
                isExpanded: true,
              ),
            ] else ...[
              Text('暂无设置选项'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: Text('确定'),
        ),
      ],
    );
  }
}

// 防守特效设置对话框组件
class DefenceEffectSettingsDialog extends StatefulWidget {
  final DefenceEffect effect;
  final Map<String, dynamic> initialSettings;
  final Function(Map<String, dynamic>) onSettingsChanged;
  final String? source, target;

  const DefenceEffectSettingsDialog({
    Key? key,
    required this.effect,
    required this.initialSettings,
    required this.onSettingsChanged,
    this.source,
    this.target,
  }) : super(key: key);

  @override
  _DefenceEffectSettingsDialogState createState() => _DefenceEffectSettingsDialogState();
}

class _DefenceEffectSettingsDialogState extends State<DefenceEffectSettingsDialog> {
  late Map<String, dynamic> _settings;

  Game game = GameManager().game;

  Map<String, dynamic> ?langMap;

  // 蚀凛
  final List<String> _erodeGelidOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  int _erodeGelidPoint = 1;

  @override
  void initState() {
    super.initState();
    _settings = Map<String, dynamic>.from(widget.initialSettings);    
    _erodeGelidPoint = _settings['erodeGelidPoint'] ?? 1;
  }

  void _saveSettings() {    
    _settings['erodeGelidPoint'] = _erodeGelidPoint;
    widget.onSettingsChanged(_settings);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.effect.effectId} 设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 根据不同的攻击特效显示不同的设置选项
            if (widget.effect == DefenceEffect.erodeGelid) ...[
              Text('蚀凛点数', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _erodeGelidPoint,
                hint: Text('蚀凛点数'),
                items: _erodeGelidOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _erodeGelidPoint = newValue ?? 0;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ] else ...[
              Text('暂无设置选项'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: Text('确定'),
        ),
      ],
    );
  }
}