import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_calculator/history.dart';
import 'package:sns_calculator/logger.dart';
import 'package:sns_calculator/settings.dart';
import 'package:sns_calculator/record.dart';
import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/widgets/info_page.dart';
import 'package:sns_calculator/widgets/history_page.dart';
import 'package:sns_calculator/widgets/logger_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AssetsManager assets = AssetsManager();
  await assets.loadData();
  
  // 初始化 GameLogger
  final gameLogger = GameLogger();
  await gameLogger.initialize();
  
  runApp(MyApp(assets: assets));
}

class MyApp extends StatelessWidget {
  final AssetsManager assets;
  const MyApp({super.key, required this.assets});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AssetsManager>.value(value: assets),
        ChangeNotifierProvider(create: (context) => MyAppState()),
        ChangeNotifierProvider(create: (context) => HistoryProvider()),        
        ChangeNotifierProvider(create: (context) => GameLogger()),
        ChangeNotifierProvider(create: (context) => RecordProvider()),
        ChangeNotifierProvider(create: (context) => CardSettingsManager()),
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
        page = HistoryPage();
        break;
      case 3:
        page = LoggerPage();
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
                  extended: constraints.maxWidth >= 800,
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
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment),
                      label: Text('Logs'),
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