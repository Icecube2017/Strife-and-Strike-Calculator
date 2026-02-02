import 'package:flutter/material.dart';
// import 'package:sns_calculator/core.dart';
import 'package:sns_calculator/game.dart';

class AttributeSettingsDialog extends StatefulWidget {
  final Character character;
  final VoidCallback onSave;

  const AttributeSettingsDialog({
    Key? key,
    required this.character,
    required this.onSave,
  }) : super(key: key);

  @override
  _AttributeSettingsDialogState createState() => _AttributeSettingsDialogState();
}

class _AttributeSettingsDialogState extends State<AttributeSettingsDialog> {
  late TextEditingController healthController;
  late TextEditingController maxHealthController;
  late TextEditingController attackController;
  late TextEditingController defenceController;
  late TextEditingController armorController;
  late TextEditingController movePointController;
  late TextEditingController maxMoveController;
  late TextEditingController moveRegenController;
  late TextEditingController cardCountController;
  late TextEditingController maxCardController;
  late TextEditingController actionTimeController;

  late Map<String, TextEditingController> skillControllers;
  late Map<String, List<TextEditingController>> statusControllers;
  late Map<String, List<TextEditingController>> hiddenStatusControllers;
  
  // 用于新增技能/状态的临时控制器
  late TextEditingController newSkillNameController;
  late TextEditingController newSkillCooldownController;
  late TextEditingController newStatusNameController;
  late TextEditingController newStatusIntensityController;
  late TextEditingController newStatusLayerController;
  late TextEditingController newHiddenStatusNameController;
  late TextEditingController newHiddenStatusIntensityController;
  late TextEditingController newHiddenStatusLayerController;

  @override
  void initState() {
    super.initState();
    
    healthController = TextEditingController(text: widget.character.health.toString());
    maxHealthController = TextEditingController(text: widget.character.maxHealth.toString());
    attackController = TextEditingController(text: widget.character.attack.toString());
    defenceController = TextEditingController(text: widget.character.defence.toString());
    armorController = TextEditingController(text: widget.character.armor.toString());
    movePointController = TextEditingController(text: widget.character.movePoint.toString());
    maxMoveController = TextEditingController(text: widget.character.maxMove.toString());
    moveRegenController = TextEditingController(text: widget.character.moveRegen.toString());
    cardCountController = TextEditingController(text: widget.character.cardCount.toString());
    maxCardController = TextEditingController(text: widget.character.maxCard.toString());
    actionTimeController = TextEditingController(text: widget.character.actionTime.toString());

    // 初始化技能控制器
    skillControllers = {};
    widget.character.skill.forEach((key, value) {
      skillControllers[key] = TextEditingController(text: value.toString());
    });

    // 初始化状态控制器
    statusControllers = {};
    widget.character.status.forEach((key, value) {
      statusControllers[key] = [
        TextEditingController(text: value[0].toString()),
        TextEditingController(text: value[1].toString()),
      ];
    });

    // 初始化隐藏状态控制器
    hiddenStatusControllers = {};
    widget.character.hiddenStatus.forEach((key, value) {
      hiddenStatusControllers[key] = [
        TextEditingController(text: value[0].toString()),
        TextEditingController(text: value[1].toString()),
      ];
    });
    
    // 初始化新增项的控制器
    newSkillNameController = TextEditingController();
    newSkillCooldownController = TextEditingController();
    newStatusNameController = TextEditingController();
    newStatusIntensityController = TextEditingController();
    newStatusLayerController = TextEditingController();
    newHiddenStatusNameController = TextEditingController();
    newHiddenStatusIntensityController = TextEditingController();
    newHiddenStatusLayerController = TextEditingController();
  }

  @override
  void dispose() {
    healthController.dispose();
    maxHealthController.dispose();
    attackController.dispose();
    defenceController.dispose();
    armorController.dispose();
    movePointController.dispose();
    maxMoveController.dispose();
    moveRegenController.dispose();
    cardCountController.dispose();
    maxCardController.dispose();
    actionTimeController.dispose();

    skillControllers.forEach((_, controller) => controller.dispose());
    statusControllers.forEach((_, controllers) {
      controllers.forEach((controller) => controller.dispose());
    });
    hiddenStatusControllers.forEach((_, controllers) {
      controllers.forEach((controller) => controller.dispose());
    });
    
    newSkillNameController.dispose();
    newSkillCooldownController.dispose();
    newStatusNameController.dispose();
    newStatusIntensityController.dispose();
    newStatusLayerController.dispose();
    newHiddenStatusNameController.dispose();
    newHiddenStatusIntensityController.dispose();
    newHiddenStatusLayerController.dispose();

    super.dispose();
  }

  void _saveChanges() {
    try {
      // 保存基本属性
      widget.character.health = int.parse(healthController.text);
      widget.character.maxHealth = int.parse(maxHealthController.text);
      widget.character.attack = int.parse(attackController.text);
      widget.character.defence = int.parse(defenceController.text);
      widget.character.armor = int.parse(armorController.text);
      widget.character.movePoint = int.parse(movePointController.text);
      widget.character.maxMove = int.parse(maxMoveController.text);
      widget.character.moveRegen = int.parse(moveRegenController.text);
      widget.character.cardCount = int.parse(cardCountController.text);
      widget.character.maxCard = int.parse(maxCardController.text);
      widget.character.actionTime = int.parse(actionTimeController.text);

      // 保存技能
      widget.character.skill.clear();
      skillControllers.forEach((key, controller) {
        widget.character.skill[key] = int.parse(controller.text);
      });

      // 保存状态
      widget.character.status.clear();
      statusControllers.forEach((key, controllers) {
        widget.character.status[key] = [
          int.parse(controllers[0].text),
          int.parse(controllers[1].text),
          GameManager().game.playerCount,
          0
        ];
      });

      // 保存隐藏状态
      widget.character.hiddenStatus.clear();
      hiddenStatusControllers.forEach((key, controllers) {
        widget.character.hiddenStatus[key] = [
          int.parse(controllers[0].text),
          int.parse(controllers[1].text),
          GameManager().game.playerCount,
          0
        ];
      });

      widget.onSave();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.character.id} 的属性已更新')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  '编辑角色属性: ${widget.character.id}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 基本属性
                const Text('基本属性', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildIntAttributeRow('生命', healthController),
                _buildIntAttributeRow('最大生命', maxHealthController),
                _buildIntAttributeRow('攻击', attackController),
                _buildIntAttributeRow('防御', defenceController),
                _buildIntAttributeRow('护甲', armorController),
                _buildIntAttributeRow('行动点', movePointController),
                _buildIntAttributeRow('最大行动点', maxMoveController),
                _buildIntAttributeRow('行动点恢复', moveRegenController),
                _buildIntAttributeRow('手牌数', cardCountController),
                _buildIntAttributeRow('手牌上限', maxCardController),
                _buildIntAttributeRow('行动次数', actionTimeController),

                const SizedBox(height: 16),

                // 技能
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('技能', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _showAddSkillDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('添加技能'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...skillControllers.entries.map((entry) {
                  return _buildSkillRow(entry.key, entry.value);
                }),

                const SizedBox(height: 16),

                // 状态
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('状态', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _showAddStatusDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('添加状态'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...statusControllers.entries.map((entry) {
                  return _buildStatusRow(entry.key, entry.value);
                }),

                const SizedBox(height: 16),

                // 隐藏状态
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('隐藏状态', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _showAddHiddenStatusDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('添加隐藏状态'),
                    )
                  ]
                ),
                const SizedBox(height: 8),
                ...hiddenStatusControllers.entries.map((entry) {
                  return _buildHiddenStatusRow(entry.key, entry.value);
                }),

                // 按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntAttributeRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillRow(String skillName, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(skillName, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                controller.dispose();
                skillControllers.remove(skillName);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String statusName, List<TextEditingController> controllers) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(statusName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  setState(() {
                    controllers[0].dispose();
                    controllers[1].dispose();
                    statusControllers.remove(statusName);
                  });
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controllers[0],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '强度',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controllers[1],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '层数',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenStatusRow(String statusName, List<TextEditingController> controllers) { 
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(statusName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  setState(() {
                    controllers[0].dispose();
                    controllers[1].dispose();
                    hiddenStatusControllers.remove(statusName);
                  });
                },
              ),
            ]
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controllers[0],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '强度',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  )
                )
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controllers[1],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '层数',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  )
                )
              )
            ]
          )
        ]
      )
    );
  }

  void _showAddSkillDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('添加技能'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newSkillNameController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: '技能名称',
                  border: OutlineInputBorder(),
                  // hintText: '支持中文输入',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newSkillCooldownController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '技能冷却',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newSkillNameController.text.isNotEmpty &&
                    newSkillCooldownController.text.isNotEmpty) {
                  setState(() {
                    String skillName = newSkillNameController.text;
                    int skillValue = int.tryParse(newSkillCooldownController.text) ?? 0;
                    skillControllers[skillName] = TextEditingController(text: skillValue.toString());
                    newSkillNameController.clear();
                    newSkillCooldownController.clear();
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  void _showAddStatusDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('添加状态'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newStatusNameController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: '状态名称',
                  border: OutlineInputBorder(),
                  // hintText: '支持中文输入',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newStatusIntensityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '状态强度',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newStatusLayerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '状态层数',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newStatusNameController.text.isNotEmpty &&
                    newStatusIntensityController.text.isNotEmpty &&
                    newStatusLayerController.text.isNotEmpty) {
                  setState(() {
                    String statusName = newStatusNameController.text;
                    int statusValue = int.tryParse(newStatusIntensityController.text) ?? 0;
                    int statusDuration = int.tryParse(newStatusLayerController.text) ?? 0;
                    statusControllers[statusName] = [
                      TextEditingController(text: statusValue.toString()),
                      TextEditingController(text: statusDuration.toString()),
                    ];
                    newStatusNameController.clear();
                    newStatusIntensityController.clear();
                    newStatusLayerController.clear();
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  void _showAddHiddenStatusDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('添加状态'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newHiddenStatusNameController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: '隐藏状态名称',
                  border: OutlineInputBorder(),                  
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newHiddenStatusIntensityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '状态强度',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newHiddenStatusLayerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '状态层数',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newHiddenStatusNameController.text.isNotEmpty &&
                    newHiddenStatusIntensityController.text.isNotEmpty &&
                    newHiddenStatusLayerController.text.isNotEmpty) {
                  setState(() {
                    String hiddenStatusName = newHiddenStatusNameController.text;
                    int hiddenStatusValue = int.tryParse(newHiddenStatusIntensityController.text) ?? 0;
                    int hiddenStatusLayer = int.tryParse(newHiddenStatusLayerController.text) ?? 0;
                    statusControllers[hiddenStatusName] = [
                      TextEditingController(text: hiddenStatusValue.toString()),
                      TextEditingController(text: hiddenStatusLayer.toString()),
                    ];
                    newHiddenStatusNameController.clear();
                    newHiddenStatusIntensityController.clear();
                    newHiddenStatusLayerController.clear();
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }
}
