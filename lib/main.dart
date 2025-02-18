import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // ChangeNotifierProviderを通じてアプリ全体に通知されるらしい
      create: (context) => MyAppState(),
      child: MaterialApp(
        // アプリのRouteやThemeなどApp全体の管理ができるWidget
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  // ChangeNotifierは自分の変更を通知できる
  var current = WordPair.random();
  var history = <WordPair>[];

  GlobalKey? historyListKey;

  void getNext() {
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    current = WordPair.random(); // 新しいランダム文字列
    notifyListeners(); // 通知する
  }

  var favorites = <WordPair>[]; // WordPairの配列でなく，空配列をジェネクリスで制限してんのね

  void toggleFavorite([WordPair? pair]) {
    pair = pair ?? current;
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
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
    // 状態変化の度にbuildが呼ばれる
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage(); // 本体のウィジェット
        break;
      case 1:
        page =
            FavoritesPage(); // お気に入りのウィジェット Placeholder(); // まだUIが未完を示すウィジェット
        break;
      default: // フェイルファストの原則でスローしてバグを防ぐ
        throw UnimplementedError('no widget for $selectedIndex');
    }

    // The container for the current page, with its background color
    // and subtle switching animation.
    var mainArea = ColoredBox(
      //color: ColorScheme.surfaceVariant,
      color: Theme.of(context).colorScheme.primaryContainer, //結果的に背景色
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,            // メインのウィジェット
      ),
    );

    return Scaffold(
      // buildメソッドはウィジェット(かウィジェットのネストツリー)を返す．Scaffoldはウィジェットだと
      body: LayoutBuilder(
        // 制約(ウィンドウサイズ変更など)の変化で呼ばれるコールバック
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            // Use a more mobile-friendly layout with BottomNavigationBar
            // on narrow screens.
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                  // SafeAreaは子供がステータスバーなどに隠れないようするもの
                  child: BottomNavigationBar(
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.favorite),
                        label: 'Favorites',
                      ),
                    ],
                    currentIndex: selectedIndex,
                    onTap: (value) {
                      setState(() {
                          selectedIndex = value;
                      });
                    },
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 600, // レスポンシブ対応(アイコン右のラベルを表示するorしない)
                    destinations: [
                      // ナビゲーション内のアイテムだろう
                      NavigationRailDestination(
                        icon: Icon(Icons.home), label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.favorite),
                        label: Text('Favorites'),
                      ),
                    ],
                    selectedIndex: selectedIndex, // 選択するディスティネーション
                    onDestinationSelected: (value) {
                      // 選択したらこれが実行
                      setState(() {
                          // UIを更新するためのメソッドか?
                          selectedIndex = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  // Rowの残りのスペースを埋めるウィジェット
                  child: mainArea),
              ],
            );
          }
        },
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Text('You have '
            '${appState.favorites.length} favorites:'),
        ),
        Expanded(
          // Make better use of wide windows with a grid.
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 400 / 80,
            ),
            children: [
              for (var pair in appState.favorites)
                // コレクションリテラル(children)の中でforが使える(関数型の場合はどうやんの?)
                ListTile(
                  leading: IconButton(
                    icon: Icon(Icons.delete_outline, semanticLabel: 'Delete'),
                    color: theme.colorScheme.primary,
                    onPressed: () {
                      appState.removeFavorite(pair);
                    },
                  ),
                title: Text(
                  pair.asLowerCase, // 良くListの中で使う左にアイコンなどが付くタイトルウィジェットのようだ
                  semanticsLabel: pair.asPascalCase,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GeneratorPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>(); // 現在の状態に対する変化を追跡
    var pair = appState.current;

    IconData icon; // アイコン
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      // 中央寄せ(縦横かな?)
      child: Column(
        // 上から下へのレイアウトウィジェット
        mainAxisAlignment: MainAxisAlignment.center, // 主軸(縦軸)中央
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView(),
          ),
          SizedBox(height: 10), // スペース埋め用ウィジェット
          BigCard(pair: pair), // 別ウィジェットに外出し
          SizedBox(height: 10),
          Row(
            // 左から右へのレイアウトウィジェット
            mainAxisSize: MainAxisSize.min, // スペースをすべてで埋めない
            children: [
              ElevatedButton.icon(
                // iconコンストラクタで作るアイコン付きボタン
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext(); // 新規ランダム文字列
                },
                child: Text('Next'),
              ),
            ],
          ),
          Spacer(flex: 2),
        ], // Flutterは行末カンマを推奨してる
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard ({
    // Widget生成時にパラメータが必要な場合はコンストラクタで受ける必要がある
    //Key? key,
    super.key,
    required this.pair,
  }); // : super(key: key);

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 現在のテーマ
    var style = theme.textTheme.displayMedium!.copyWith(
      // フォントテーマの大きめスタイルをコピーしてテキスト色のみ変更
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary, // プライマリカラー
      child: Padding(
        // パディングごときがTextの属性でなくウィジェットなのは継承しない為らしい
        padding: const EdgeInsets.all(20),
        child: AnimatedSize(
          duration: Duration(milliseconds: 200),
          // Make sure that the compound word wraps correctly when the window
          // is too narrow.
          child: MergeSemantics(
            child: Wrap(
              children: [
                Text(
                  pair.first,
                  style: style.copyWith(fontWeight: FontWeight.w200),
                ),
                Text(
                  pair.second,
                  style: style.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryListView extends StatefulWidget {
  //const HistoryListView({Key? key}) : super(key: key);
  const HistoryListView({super.key});

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  /// Needed so that [MyAppState] can tell [AnimatedList] below to animate
  /// new items.
  final _key = GlobalKey();

  /// Used to "fade out" the history items at the top, to suggest continuation.
  static const Gradient _maskingGradient = LinearGradient(
    // This gradient goes from fully transparent to fully opaque black...
    colors: [Colors.transparent, Colors.black],
    // ... from the top (transparent) to half (0.5) of the way to the bottom.
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) =>
      _maskingGradient.createShader(bounds),
      // This blend mode takes the opacity of the shader (i.e. our gradient)
      // and applies it to the destination (i.e. our animated list).
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.history[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  appState.toggleFavorite(pair);
                },
                icon: appState.favorites.contains(pair) ? Icon(Icons.favorite, size: 12) : SizedBox(),
                label: Text(
                  pair.asLowerCase,
                  semanticsLabel: pair.asPascalCase,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
