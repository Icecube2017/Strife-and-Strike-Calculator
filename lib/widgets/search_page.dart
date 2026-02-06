import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/widgets/richtext.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {

  static final Logger _logger = Logger();

  final List<String> _tabTitles = ['角色', '道具卡', '技能', '状态效果'];
  final double _minTabWidth = 80;
  final double _fixedTabWidth = 80;

  List<CharacterInfo> characterInfoData = [];
  List<CardInfo> cardInfoData = [];
  List<SkillInfo> skillInfoData = [];
  List<StatusInfo> statusInfoData = [];

  @override
  void initState() {
    super.initState();
    final assets = Provider.of<AssetsManager>(context, listen: false);
    characterInfoData = assets.characterInfoData;
    cardInfoData = assets.cardInfoData;
    skillInfoData = assets.skillInfoData;
    statusInfoData = assets.statusInfoData;
  }

  List<dynamic> _getPageByIndex(int index) {
    switch (index) {
      case 0: return characterInfoData;
      case 1: return cardInfoData;
      case 2: return skillInfoData;
      case 3: return statusInfoData;
      default: return [];
    }
  }

  dynamic _getBuildMethodByIndex(int index) {
    switch (index) {
      case 0: return _buildCharacterInfo;
      case 1: return _buildCardInfo;
      case 2: return _buildSkillInfo;
      case 3: return _buildStatusInfo;
      default: return (dynamic item, double width) => Container();
    }
  }

  // 每个Tab下方的卡片列表
  Widget _buildTabView(int index) {
    final List<dynamic> currentSubpage = _getPageByIndex(index);
    final dynamic currentBuildMethod = _getBuildMethodByIndex(index);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children:[
      Flexible(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double containerWidth = constraints.maxWidth;
          final int crossAxisCount = containerWidth > 1100 ? 2 : 1;
          final double itemWidth = (containerWidth - (crossAxisCount + 1) * 16) / crossAxisCount;

          // 空列表兜底：无数据时显示提示
          if (currentSubpage.isEmpty) {
            return const Center(child: Text("暂无信息"));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children:
              currentSubpage.map((info) {
                return SizedBox(
                  width: itemWidth,
                  child: currentBuildMethod(info, itemWidth),
                );
              }).toList(),
            ),
          );
        }
      ),
    ),],);
  }

  // 构造卡片外壳
  Widget _buildCommonCard({required double width, required Widget child}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.topLeft,
      child: child
    );
  }

  Widget _buildInnerCard({required String text, String? header}) {
    return Container(
      margin: EdgeInsets.only(top: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null)...[
            Text(header, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
          ],
          TagRichtext(content: text),
        ],
      ),
    );
  }

  // 构造标签
  Widget _buildCommonTag({required String text, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      color: color ?? Colors.grey.shade200,
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
        softWrap: false
      ),
    );
  }

  // 角色信息
  Widget _buildCharacterInfo(CharacterInfo info, double width) {
    return _buildCommonCard(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(
                info.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 2,),
              _buildCommonTag(text: info.panelType),
              _buildCommonTag(text: info.species),
              _buildCommonTag(text: info.tags.join(' ')),
              Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(info.traits.length, (index) {
                final TraitInfo trait = info.traits[index];
                return _buildInnerCard(text: trait.description, header: trait.name);
              }),
              ...List.generate(info.skills.length, (index) {
                final SkillInfo skill = info.skills[index];
                return _buildInnerCard(text: skill.description, header: skill.name);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfo(CardInfo info, double width) {
    return _buildCommonCard(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(
                info.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildCommonTag(text: info.tags.join(' ')),
              Spacer(),
            ],
          ),
          _buildInnerCard(text: info.description),
        ],
      ),
    );
  }

  Widget _buildSkillInfo(SkillInfo info, double width) {
    return _buildCommonCard(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(
                info.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildCommonTag(text: info.cd == null ? "CD 不定" : "CD ${info.cd}"),
              if (info.availableTiming != null)...[_buildCommonTag(text: "${info.availableTiming}")],
              if (info.cost != null)...[_buildCommonTag(text: "${info.cost}MP")],
              Spacer(),
            ],
          ),
          _buildInnerCard(text: info.description),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(StatusInfo info, double width) {
    return _buildCommonCard(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(
                info.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildCommonTag(
                text: info.stackable != null ? "强度可叠加" : "强度",
                color: info.hasIntensity ? Colors.green[100] : Colors.grey[100],
              ),
              _buildCommonTag(
                text: '层数',
                color: info.hasStack ? Colors.green[100] : Colors.grey[100],
              ),
              _buildCommonTag(
                text: info.decayOverTurn ? "自然衰减" : "特殊衰减",
                color: info.decayOverTurn ? Colors.grey[100] : Colors.red[100],
              ),
              Spacer(),
            ],
          ),
          _buildInnerCard(text: info.description),
          info.comments != '' ? _buildCommonTag(text: info.comments!) : SizedBox(),
        ],
      ),
    );
  }
    
  @override
  Widget build(BuildContext context) {

    final double screenWitdth = MediaQuery.of(context).size.width;
    final double averageTabWidth = screenWitdth / _tabTitles.length;
    final bool needScroll = averageTabWidth < _minTabWidth;
    
    return DefaultTabController(
      length: _tabTitles.length,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('搜索页面'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.transparent,
              child: TabBar(
                isScrollable: needScroll,
                tabAlignment: needScroll ? TabAlignment.start : TabAlignment.fill,
                labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),

                unselectedLabelColor: Colors.black,
                unselectedLabelStyle: const TextStyle(fontSize: 15),

                indicatorColor: Colors.deepPurple,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: EdgeInsets.zero,
                tabs: _tabTitles.map((title) {
                  if (needScroll) {
                    return SizedBox(
                      width: _fixedTabWidth,
                      child: Tab(
                        text: title,
                      ),
                    );
                  } else {
                    return Tab(text: title,);
                  }
                }).toList(),
              ),
            ),
          ),
        ),

        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children:  _tabTitles.asMap().entries.map((e) => _buildTabView(e.key)).toList(),
        ),
      ),
    );
  }
}