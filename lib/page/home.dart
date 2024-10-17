import 'package:flutter/material.dart';
import 'package:flutter_fire_engine/example/checkers.dart';
import 'package:flutter_fire_engine/example/connect_four.dart';
import 'package:flutter_fire_engine/example/draw_my_thing.dart';
import 'package:flutter_fire_engine/example/endangered.dart';
import 'package:flutter_fire_engine/example/last_card.dart';
import 'package:flutter_fire_engine/example/memory_match.dart';
import 'package:flutter_fire_engine/example/rock_paper_scissors.dart';
import 'package:flutter_fire_engine/example/tic_tac_toe.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/game_manager.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Add more games to game hub via this list.
  List<Game> games = [
    TicTacToe(),
    ConnectFour(),
    Checkers(),
    RockPaperScissors(),
    LastCard(),
    MemoryMatch(),
    DrawMyThing(),
    Endangered(),
  ];

  late GameManager gameManager;

  @override
  void initState() {
    super.initState();
    gameManager = GameManager.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Select Game"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                  children: games
                      .map((game) => _gameListItem(context, game))
                      .toList())),
        ));
  }

  Widget _gameListItem(BuildContext context, Game game) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
              child: ElevatedButton(
                  onPressed: () async {
                    gameManager.setGame(game);
                    Navigator.of(context).pushNamed("/rooms");
                  },
                  child: Text(game.name)))
        ],
      ),
    );
  }
}
