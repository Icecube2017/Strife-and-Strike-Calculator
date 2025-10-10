import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'game.dart';
import 'assets.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
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
  //
  //static final Logger _logger = Logger();
  //final columnWidth = MediaQuery.of(context).size.width / columnCount * 0.8;

  @override
  void initState() {
    super.initState();
    _loadAssetsData();
    game = GameManager().game;

    // 添加监听器来响应游戏状态变化
    game.addListener(_handleGameChange);
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
              ],
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
                        Map<String, List<int>> status = game.players[roleName]!.status;
                        Map<String, List<int>> hiddenStatus = game.players[roleName]!.hiddenStatus;
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
      );
    },
  );
}
  void _changeGameTurn(){
    game.endTurn();
  }

  void _resetGameTurn(){
    game.clearGame();
    tableData.clear();
    game.refresh();
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

  const AddActionDialog({Key? key, required this.characterList}) : super(key: key);

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
  
  // 道具卡数据
  List<String>? cardTypes;

  // 语言数据
  Map<String, dynamic>? langMap;
  
  // 道具卡表格数据
  List<Map<String, dynamic>> _cardTableData = [];

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
              ],
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
                int attack = game.players[_source]!.attack;
                int defence = game.players[_target]!.defence;
                int attackPlus = 0;
                double attackMulti = 1;
                // 遍历道具
                int cost = 0;
                for (var rowData in _cardTableData) {
                  cost += 1;
                  String cardName = rowData['cardName'];
                  Map<String, dynamic> settings = rowData['settings'];
                  if(cardName == langMap!['end_crystal']){
                    int crystalSelf = settings['crystalSelf'];
                    int crystalMagic = settings['crystalMagic'];
                    game.damagePlayer(_source!, _source!, (30 + 15 * crystalSelf), 'magical');
                    for(Character chara in game.players.values){
                      if(chara.id != _source) game.damagePlayer(_source!, chara.id, (40 + 15 * crystalMagic), 'magical');
                    }
                  }
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
                  else if(cardName == langMap!['babel_tower']){
                    for(Character chara in game.players.values){
                      game.addHiddenStatus(chara.id, 'babel', 0, 1);
                    }
                  }
                  else if(cardName == langMap!['damocles_sword']){
                    game.addHiddenStatus(_source!, 'damocles', 0, 1);
                  }
                  else if(cardName == langMap!['wood_sword']){
                    game.addAttribute(_source!, 'attack', 10);
                    attackPlus += 10;
                  }
                  else if(cardName == langMap!['slowness_spell']){
                    game.addStatus(_target!, langMap!['slowness'], 1, 2);
                  }
                  else if(cardName == langMap!['corrupt_pendant']){
                    game.addAttribute(_source!, 'attack', 5);
                    game.addAttribute(_target!, 'attack', -5);
                    game.damagePlayer(_source!, _source!, 60, 'heal');
                    game.damagePlayer(_source!, _target!, 60, 'magical');                    
                  }
                  else if(cardName == langMap!['violent_violet']){
                    int sequence = game.gameSequence.indexOf(_source!);
                    if(sequence == 0) {sequence = game.gameSequence.length - 1;}
                    else {sequence--;}
                    Character previousChara = game.players[game.gameSequence[sequence]]!;
                    // _logger.d(previousChara.id);
                    game.addHiddenStatus(_target!, 'damageplus', previousChara.defence * 2, 1);
                  }
                  else if(cardName == langMap!['bow']){
                    int ammoCount = settings['ammoCount'];
                    game.damagePlayer(_source!, _target!, 75 * ammoCount, 'magical');
                    game.players[_source]!.cardCount = 0;
                  }
                  else if(cardName == langMap!['high_cap']){
                    game.addStatus(_target!, langMap!['tigris_dilemma'], 0, 1);
                  }
                  else if(cardName == langMap!['high_energy_can']){
                    game.addAttribute(_source!, 'movepoint', 1);
                    game.addAttribute(_source!, 'maxmove', 2);
                  }
                  else if(cardName == langMap!['hero_legend']){


                    game.damagePlayer(_source!, _source!, 100, 'heal');
                    game.addHiddenStatus(_source!, 'hero_legend', 0, 1);
                  }
                  else if(cardName == langMap!['passing_gaze']){
                    game.addHiddenStatus(_target!, 'damageplus', 100, 1);
                    game.addStatus(_target!, langMap!['dissociated'], 0, 2);
                  }
                  else if(cardName == langMap!['cryotheum']){
                    game.addStatus(_target!, langMap!['frost'], 5, 2);
                  }
                  else if(cardName == langMap!['redstone']){
                    String statusProlonged = settings['statusProlonged'];
                    String playerProlonged = settings['playerProlonged'];         
                    if(statusProlonged != ''){
                      game.addStatus(playerProlonged, statusProlonged, 0, 1);
                    }                               
                  }
                  else if(cardName == langMap!['heart_locket']){
                    game.addAttribute(_source!, 'defence', 10);
                  }
                  else if(cardName == langMap!['regenerating']){
                    game.addStatus(_source!, langMap!['regeneration'], 4, 2);
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  else if(cardName == langMap!['chaotic_drill']){
                    game.addStatus(_target!, langMap!['confusion'], 0, 1);
                  }
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
                      game.damagePlayer(_source!, chara, 50 * maxPoint, 'physical');
                    }
                  }
                  else if(cardName == langMap!['arctic_heart']){                    
                  }
                  else if(cardName == langMap!['aurora_concussion']){       
                    Map<String, int> auroraPoints = settings['auroraPoints'];
                    for(String chara in auroraPoints.keys){ 
                      if(auroraPoints[chara] == 1){
                        game.addStatus(chara, langMap!['exhausted'], 0, 1);
                      }
                    }
                    game.addStatus(_source!, 'void', 0, 1);
                  }
                  else if(cardName == langMap!['dream_shelter']){
                    game.damagePlayer(_source!, _source!, 100, 'heal');
                    game.addHiddenStatus(_source!, 'dream_shelter', 0, 1);
                  }
                  else if(cardName == langMap!['arrow']){
                    game.addHiddenStatus(_target!, 'damageplus', 50, 1);
                  }
                  else if(cardName == langMap!['mace']){
                    game.addHiddenStatus(_target!, 'damageplus', 90, 1);
                    game.addStatus(_target!, langMap!['fractured'], 0, 2);
                  }
                  else if(cardName == "猎魔灵刃"){                    
                  }
                  else if(cardName == "林鸟·赤掠"){
                  }
                  else if(cardName == "聆音掠影"){
                    game.addStatus(_target!, '恍惚', 0, 1);
                  }
                  else if(cardName == "蛮力术"){
                    game.addStatus(_source!, '力量', 1, 2);
                  }
                  else if(cardName == "蛮力术II"){
                    game.addStatus(_source!, '力量', 2, 2);
                  }
                  else if(cardName == "纳米渗透"){
                    game.addHiddenStatus(_target!, '穿透', 0, 2);
                  }
                  else if(cardName == "潘多拉魔盒"){                    
                  }
                  else if(cardName == "全息投影"){
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  else if(cardName == "荣光循途"){                    
                  }
                  else if(cardName == "融甲宝珠"){ 
                  }
                  else if(cardName == "刷新"){                  
                  }
                  else if(cardName == "水波荡漾"){
                    game.addStatus(_target!, '氤氲', 1, 1);
                  }
                  else if(cardName == "瞬疗"){
                    game.damagePlayer(_source!, _source!, 120, 'heal');
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  else if(cardName == "天穹尘埃之障"){
                    game.addStatus(_target!, '障目', 0, 1);
                  }
                  else if(cardName == "同调"){
                  }
                  else if(cardName == "无敌贯通"){
                  }
                  else if(cardName == "西西弗斯之石头"){
                    game.addStatus(_target!, '消磨', 0, 1);
                  }
                  else if(cardName == "休憩"){
                    cost -= 2;
                  }
                  else if(cardName == "迅捷术"){
                    game.addStatus(_target!, '迅捷', 1, 2);
                  }
                  else if(cardName == langMap!['pyrotheum']){
                    game.addStatus(_target!, langMap!['flaming'], 5, 3);
                  }
                  else if(cardName == "伊甸园"){}
                  else if(cardName == "遗失碎片"){
                    game.addHiddenStatus(_target!, 'damageplus', 45, 1);
                  }
                  else if(cardName == "隐身术"){
                    game.addStatus(_source!, '闪避', 0, 1);
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  else if(cardName == "御术者长矛·炎"){}
                  else if(cardName == "御术者重盾·霜"){}
                  else if(cardName == "圆盾"){
                    game.addAttribute(_source!, 'armor', 100);
                    game.addAttribute(_source!, 'defence', 5);
                  }
                  else if(cardName == "长剑"){
                    game.addAttribute(_source!, 'attack', 15);
                    attackPlus += 15;
                  }
                  else if(cardName == "折射水晶"){ 
                  }
                  else if(cardName == "终焉长戟"){
                    game.addHiddenStatus(_target!, 'end', 0, 1);
                  }
                }
                // 行动点扣除
                if(game.players[_source]!.movePoint >= cost){
                  game.addAttribute(_source!, 'movepoint', -cost);
                }
                
                // 计算伤害
                if(game.players[_source]!.hasHiddenStatus('hero_legend')){
                  attackPlus += 10;
                  game.removeHiddenStatus(_source!, 'hero_legend');
                }
                if(game.players[_source]!.hasHiddenStatus('dream_shelter')){
                  attackPlus -= 10;
                  game.removeHiddenStatus(_source!, 'dream_shelter');
                }
                double baseDamage = ((attack + attackPlus) * attackMulti - defence) * points;
                game.damagePlayer(_source!, _target!, baseDamage.toInt(), 'physical');                
              }
            }
            // 这里可以处理添加行动的逻辑
            // 例如：保存数据、更新状态等
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
  @override

  void initState() {
    super.initState();
    _loadAssetsData();
    _settings = Map<String, dynamic>.from(widget.initialSettings);
    _crystalMagic = _settings['crystalMagic'] ?? 1;
    _crystalSelf = _settings['crystalSelf'] ?? 1;
    _ammoCount = _settings['ammoCount'] ?? 1;
    _redstonePlayerOptions = [widget.source!, widget.target!];
    _updateRedstoneOptions();
    _statusProlonged = _settings['statusProlonged'] ?? '';
    _playerProlonged = _settings['playerProlonged'] ?? '';
    if (_settings['ascensionPoints'] != null) {
      _ascensionPoints = Map<String, int>.from(_settings['ascensionPoints']);
    } else {
      _ascensionPoints = {};
      for (var playerId in game.gameSequence) {
        _ascensionPoints[playerId] = 1;
      }
    }
    if (_settings['auroraPoints'] != null) {
      _auroraPoints = Map<String, int>.from(_settings['auroraPoints']);
    } else {
      _auroraPoints = {};
      for (var playerId in game.gameSequence) {
        _auroraPoints[playerId] = 1;
      }
    }
  }

  Future<void> _loadAssetsData() async {
    AssetsManager assets = AssetsManager();
    await assets.loadData();
    langMap = assets.langMap;
  }

  void _saveSettings() {
    _settings['crystalMagic'] = _crystalMagic;
    _settings['crystalSelf'] = _crystalSelf;
    _settings['ammoCount'] = _ammoCount;
    _settings['statusProlonged'] = _statusProlonged;
    _settings['playerProlonged'] = _playerProlonged;
    _settings['ascensionPoints'] = _ascensionPoints;
    _settings['auroraPoints'] = _auroraPoints;
    widget.onSettingsChanged(_settings);
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
            ],
            if (widget.cardName == "复合弓")...[
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
            ],
            if(widget.cardName == "后日谈")...[
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
            ],
            if(widget.cardName == '混乱力场')...[
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
             }).toList(),
            ],
            if(widget.cardName == '极光震荡')...[
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
             }).toList(),
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