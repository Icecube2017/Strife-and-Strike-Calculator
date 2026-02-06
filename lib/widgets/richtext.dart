import 'dart:core';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:sns_calculator/core.dart';

abstract class RichtextNode {}

class TextNode extends RichtextNode {
  final String content;
  TextNode(this.content);
}

class TagTextNode extends RichtextNode {
  final List<String> tagTypes;
  final String contentA;
  final String contentB;

  TagTextNode({
    required this.tagTypes,
    required this.contentA,
    required this.contentB,
  });
}

// 设定文本标记
/*
  st(a):          状态
  ob(j):          特异物&其他攻击特效
  l(a)y:          层数
  in(t):          强度
  - p/n:          正面/负面

  hp/at/df/mp:    四维
  sh:             护盾
  dc(...):        骰子
  -- x/4/6/8/0/t/v    ?/4/6/8/10/12/20面骰子
  dr(...):        骰点
  -- 1/2/3/4/5/6      D6结果
  dp/dm/dt:       物理/法术/真实伤害
  cd:             CD
  - i/d/n:        增/减/普通

  crd:            卡牌
  skl:            技能
  eff:            附加特效
  mov:            行动/行为
  nul:            无效化
*/
// 语法与渲染
/*
  标记语法
  - 文本段落1#文本段落2@tag1_tag2_tag3@文本段落3#文本段落4
  渲染效果
  - 文本段落1[文本段落2[icon1][icon2][icon3]文本段落3]文本段落4
*/
// 1. 定义标签配置类，封装所有样式属性
class TagConfig {
  final IconData icon;
  final Color? iconColor;
  final Color? bgColor;
  final Color? textColor;

  TagConfig({
    required this.icon,
    this.iconColor,
    this.bgColor,
    this.textColor,
  });
}

// 2. 全局标签配置映射表
final Map<String, TagConfig> _tagConfigMap = {
  'sta': TagConfig(icon: Icons.bubble_chart),
  'stp': TagConfig(icon: Icons.bubble_chart, bgColor: Colors.blue[50]),
  'stn': TagConfig(icon: Icons.bubble_chart, bgColor: Colors.red[50]),
  'obj': TagConfig(icon: Icons.palette),
  'eff': TagConfig(icon: MdiIcons.hospital, iconColor: Colors.amber),
  'mov': TagConfig(icon: Icons.back_hand),
  'nul': TagConfig(icon: MdiIcons.circleOffOutline),

  'lay': TagConfig(icon: Icons.layers),
  'lyp': TagConfig(icon: Icons.layers, bgColor: Colors.blue[50]),
  'lyn': TagConfig(icon: Icons.layers, bgColor: Colors.red[50]),
  'int': TagConfig(icon: MdiIcons.signalCellular3),
  'inp': TagConfig(icon: MdiIcons.signalCellular3, bgColor: Colors.blue[50]),
  'inn': TagConfig(icon: MdiIcons.signalCellular3, bgColor: Colors.red[50]),

  'hpi': TagConfig(icon: Icons.favorite,bgColor: Colors.blue[50]),
  'hpd': TagConfig(icon: Icons.favorite_border, iconColor: Colors.red, bgColor: Colors.red[50]),
  'hpn': TagConfig(icon: Icons.favorite,),
  'ati': TagConfig(icon: MdiIcons.sword, bgColor: Colors.blue[50]),
  'atd': TagConfig(icon: MdiIcons.sword, bgColor: Colors.red[50]),
  'atn': TagConfig(icon: MdiIcons.sword),
  'dfi': TagConfig(icon: Icons.shield, bgColor: Colors.blue[50]),
  'dfd': TagConfig(icon: Icons.shield, bgColor: Colors.red[50]),
  'dfn': TagConfig(icon: Icons.shield),
  'mpi': TagConfig(icon: Icons.bolt, bgColor: Colors.blue[50]),
  'mpd': TagConfig(icon: Icons.bolt, bgColor: Colors.red[50]),
  'mpn': TagConfig(icon: Icons.bolt),
  'shi': TagConfig(icon: Icons.health_and_safety, bgColor: Colors.blue[50]),
  'shd': TagConfig(icon: Icons.health_and_safety, bgColor: Colors.red[50]),
  'shn': TagConfig(icon: Icons.health_and_safety),

  'dcxi': TagConfig(icon: Icons.help_center, bgColor: Colors.blue[50]),
  'dcxd': TagConfig(icon: Icons.help_center, bgColor: Colors.red[50]),
  'dcxn': TagConfig(icon: Icons.help_center),
  'dc4n': TagConfig(icon: MdiIcons.diceD4),
  'dc4i': TagConfig(icon: MdiIcons.diceD4, bgColor: Colors.blue[50]),
  'dc4d': TagConfig(icon: MdiIcons.diceD4, bgColor: Colors.red[50]),
  'dc6n': TagConfig(icon: MdiIcons.diceD6),
  'dc6i': TagConfig(icon: MdiIcons.diceD6, bgColor: Colors.blue[50]),
  'dc6d': TagConfig(icon: MdiIcons.diceD6, bgColor: Colors.red[50]),
  'dc8n': TagConfig(icon: MdiIcons.diceD8),
  'dc8i': TagConfig(icon: MdiIcons.diceD8, bgColor: Colors.blue[50]),
  'dc8d': TagConfig(icon: MdiIcons.diceD8, bgColor: Colors.red[50]),
  'dc0n': TagConfig(icon: MdiIcons.diceD10),
  'dc0i': TagConfig(icon: MdiIcons.diceD10, bgColor: Colors.blue[50]),
  'dc0d': TagConfig(icon: MdiIcons.diceD10, bgColor: Colors.red[50]),
  'dctn': TagConfig(icon: MdiIcons.diceD12),
  'dcti': TagConfig(icon: MdiIcons.diceD12, bgColor: Colors.blue[50]),
  'dctd': TagConfig(icon: MdiIcons.diceD12, bgColor: Colors.red[50]),
  'dcvn': TagConfig(icon: MdiIcons.diceD20),
  'dcvi': TagConfig(icon: MdiIcons.diceD20, bgColor: Colors.blue[50]),
  'dcvd': TagConfig(icon: MdiIcons.diceD20, bgColor: Colors.red[50]),

  'dr1n': TagConfig(icon: MdiIcons.dice1),
  'dr1i': TagConfig(icon: MdiIcons.dice1, bgColor: Colors.blue[50]),
  'dr1d': TagConfig(icon: MdiIcons.dice1, bgColor: Colors.red[50]),
  'dr2n': TagConfig(icon: MdiIcons.dice2),
  'dr2i': TagConfig(icon: MdiIcons.dice2, bgColor: Colors.blue[50]),
  'dr2d': TagConfig(icon: MdiIcons.dice2, bgColor: Colors.red[50]),
  'dr3n': TagConfig(icon: MdiIcons.dice3),
  'dr3i': TagConfig(icon: MdiIcons.dice3, bgColor: Colors.blue[50]),
  'dr3d': TagConfig(icon: MdiIcons.dice3, bgColor: Colors.red[50]),
  'dr4n': TagConfig(icon: MdiIcons.dice4),
  'dr4i': TagConfig(icon: MdiIcons.dice4, bgColor: Colors.blue[50]),
  'dr4d': TagConfig(icon: MdiIcons.dice4, bgColor: Colors.red[50]),
  'dr5n': TagConfig(icon: MdiIcons.dice5),
  'dr5i': TagConfig(icon: MdiIcons.dice5, bgColor: Colors.blue[50]),
  'dr5d': TagConfig(icon: MdiIcons.dice5, bgColor: Colors.red[50]),
  'dr6n': TagConfig(icon: MdiIcons.dice6),
  'dr6i': TagConfig(icon: MdiIcons.dice6, bgColor: Colors.blue[50]),
  'dr6d': TagConfig(icon: MdiIcons.dice6, bgColor: Colors.red[50]),

  'dpi': TagConfig(icon: MdiIcons.swordCross, bgColor: Colors.blue[50]),
  'dpd': TagConfig(icon: MdiIcons.swordCross, bgColor: Colors.red[50]),
  'dpn': TagConfig(icon: MdiIcons.swordCross),
  'dmi': TagConfig(icon: Icons.auto_awesome, bgColor: Colors.blue[50]),
  'dmd': TagConfig(icon: Icons.auto_awesome, bgColor: Colors.red[50]),
  'dmn': TagConfig(icon: Icons.auto_awesome),
  'dti': TagConfig(icon: MdiIcons.heartHalfFull, bgColor: Colors.blue[50]),
  'dtd': TagConfig(icon: MdiIcons.heartHalfFull, bgColor: Colors.red[50]),
  'dtn': TagConfig(icon: MdiIcons.heartHalfFull),

  'crd': TagConfig(icon: MdiIcons.cards),
  'skl': TagConfig(icon: Icons.auto_fix_high),
  'cdi': TagConfig(icon: Icons.change_circle, bgColor: Colors.blue[50]),
  'cdd': TagConfig(icon: Icons.change_circle, bgColor: Colors.red[50]),
  'cdn': TagConfig(icon: Icons.change_circle),
};

IconData _getTagIcon(String tagType) {
  return _tagConfigMap[tagType]?.icon ?? Icons.question_mark;
}

Color _getTagIconColor(String tagType) {
  return _tagConfigMap[tagType]?.iconColor ?? Colors.blueGrey;
}

Color _getTagBgColor(String tagType) {
  return _tagConfigMap[tagType]?.bgColor ?? const Color(0xFFFFF8E1);
}

Color _getTagTextColor(String tagType) {
  return _tagConfigMap[tagType]?.textColor ?? Colors.grey.shade800;
}


class RichtextParser {
  static final RegExp tagRegExp = RegExp(r'#(.*?)@(\w+)@(.*?)#', caseSensitive: true);
  static final Logger _logger = Logger();

  static List<RichtextNode> parse(String content) {
    List<RichtextNode> nodes = [];
    String remaining = content.trim();
    if (remaining.isEmpty) return nodes;
    
    while (remaining.isNotEmpty) {
      final match = tagRegExp.firstMatch(remaining);
      if (match == null) {
        nodes.add(TextNode(remaining));
        break;
      }

      final start = match.start;
      final end = match.end;
      final tagTypeString = match.group(2)!;
      List<String> tagTypes = tagTypeString.split('_');
      final tagContentA = match.group(1)!;
      final tagContentB = match.group(3)!;

      if (start > 0) {
        nodes.add(TextNode(remaining.substring(0, start)));
      }
      if (tagTypes.isNotEmpty) {
        nodes.add(TagTextNode(tagTypes: tagTypes, contentA: tagContentA, contentB: tagContentB));
      }
      remaining = remaining.substring(end);
    }
    return nodes;
  }
}

class TagRichtext extends StatelessWidget {
  final String content;
  final TextStyle defaultTextStyle;

  const TagRichtext({
    super.key,
    required this.content,
    this.defaultTextStyle = const TextStyle(color: Color(0xFF424242), fontSize: 14)
  });

  @override
  Widget build(BuildContext context) {
    final nodes = RichtextParser.parse(content);
    final spans = _convertNodesToSpans(nodes);
    return RichText(
      text: TextSpan(style: defaultTextStyle, children: spans),
      softWrap: true,
      overflow: TextOverflow.clip,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: true,
        applyHeightToLastDescent: true
      ),
    );
  }

  List<InlineSpan> _convertNodesToSpans(List<RichtextNode> nodes) {
    return nodes.map((node) {
      if (node is TextNode) {
        return TextSpan(text: node.content);
      } else if (node is TagTextNode) {
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _getTagBgColor(node.tagTypes.first),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                node.contentA.isNotEmpty
                  ? Text(node.contentA, style: TextStyle(fontSize: 14, color: _getTagTextColor(node.tagTypes.first,)), softWrap: true,)
                  : SizedBox(),
                for (String tag in node.tagTypes)
                Row(
                  children: [
                    Icon(_getTagIcon(tag), size: 16, color: _getTagIconColor(tag)),
                  ],
                ),
                node.contentB.isNotEmpty
                  ? Text(node.contentB, style: TextStyle(fontSize: 14, color: _getTagTextColor(node.tagTypes.first,)), softWrap: true,)
                  : SizedBox(),
              ],
            ),
          ),
        );
      } else {
        return const TextSpan();
      }
    }).toList();
  }
}