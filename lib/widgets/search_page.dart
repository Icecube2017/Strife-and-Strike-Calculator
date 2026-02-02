import 'package:flutter/material.dart';
import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/core.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  @override
  Widget build(BuildContext context) {
    final assets = AssetsManager();
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索页面'),
      ),
    );
  }
}