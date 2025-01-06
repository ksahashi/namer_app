import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
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

  void getNext() {
    current = WordPair.random(); // 新しいランダム文字列
    notifyListeners(); // 通知する
  }

  var favorites = <WordPair>[]; // WordPairの配列でなく，空配列をジェネクリスで制限してんのね

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

    return LayoutBuilder(builder: (context, constraints) {
      // 制約(ウィンドウサイズ変更など)の変化で呼ばれるコールバック
      return Scaffold(
          // buildメソッドはウィジェット(かウィジェットのネストツリー)を返す．Scaffoldはウィジェットだと
          body: Row(
        children: [
          SafeArea(
            // SafeAreaは子供がステータスバーなどに隠れないようするもの
            child: NavigationRail(
              extended:
                  constraints.maxWidth >= 600, // レスポンシブ対応(アイコン右のラベルを表示するorしない)
              destinations: [
                // ナビゲーション内のアイテムだろう
                NavigationRailDestination(
                    icon: Icon(Icons.home), label: Text('Home')),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite),
                  label: Text('Favorites'),
                ),
              ],
              selectedIndex: selectedIndex, // 選択するディスティネーション
              onDestinationSelected: (value) {
                // 選択したらこれが実行
                //print('selected: $value');  // $valueは選択インデックス
                setState(() {
                  // UIを更新するためのメソッドか?
                  selectedIndex = value;
                });
              },
            ),
          ),
          Expanded(
            // Rowの残りのスペースを埋めるウィジェット
            child: Container(
              // コンテナウィジェットっていうのかな?
              color: Theme.of(context).colorScheme.primaryContainer, // 結果的に背景色
              child: page, // メインのウィジェット
            ),
          ),
        ],
      ));
    });
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      // スクロールするリスト
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          // コレクションリテラル(children)の中でforが使える(関数型の場合はどうやんの?)
          ListTile(
              leading: Icon(Icons.favorite),
              title: Text(
                  pair.asLowerCase)) // 良くListの中で使う左にアイコンなどが付くタイトルウィジェットのようだ
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
          BigCard(pair: pair), // 別ウィジェットに外出し
          SizedBox(height: 10), // スペース埋め用ウィジェット
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
                  label: Text('Like')),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext(); // 新規ランダム文字列
                },
                child: Text('Next'),
              ),
            ],
          ),
        ], // Flutterは行末カンマを推奨してる
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    // Widget生成時にパラメータが必要な場合はコンストラクタで受ける必要がある
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 現在のテーマ
    final style = theme.textTheme.displayMedium!.copyWith(
      // フォントテーマの大きめスタイルをコピーしてテキスト色のみ変更
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary, // プライマリカラー
      child: Padding(
        // パディングごときがTextの属性でなくウィジェットなのは継承しない為らしい
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase, // Stateオブジェクトのメンバーにアクセス
          style: style,
          semanticsLabel:
              "${pair.first} ${pair.second}", // スクリーンリーダーの為のようでわからないが，どうでも良い
        ),
      ),
    );
  }
}
