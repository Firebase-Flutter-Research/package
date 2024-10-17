import 'dart:math';

import 'package:either_dart/either.dart';
import 'package:flutter_fire_engine/example/endangered_questions.dart';
import 'package:flutter_fire_engine/model/event.dart';
import 'package:flutter_fire_engine/model/game.dart';
import 'package:flutter_fire_engine/model/player.dart';
import 'package:pair/pair.dart';
import 'package:collection/collection.dart';

class Endangered extends Game {
  @override
  String get name => "Endangered";

  @override
  int get requiredPlayers => 2;

  @override
  int get playerLimit => 4;

  @override
  Map<String, dynamic> getInitialGameState(
      {required List<Player> players,
      required Player host,
      required Random random}) {
    Set<String> categories = {};
    while (categories.length < 5) {
      final category =
          questions.keys.toList()[random.nextInt(questions.length)];
      if (!categories.contains(category)) categories.add(category);
    }
    for (var category in categories) {
      for (var question in questions[category]!.values) {
        final answers = question["answers"] as List<String>;
        final answer = answers[question["correctIndex"]];
        answers.shuffle(random);
        question["correctIndex"] = answers.indexOf(answer);
      }
    }
    return {
      "categories": categories,
      "scores": {for (var player in players) player: 0},
      "answeredQuestions": <Pair<String, String>>{},
      "state": "selecting", // {"selecting", "buzzing", "answering"}
      "buzzedIn": null, // Ordered list of players
      "notBuzzedIn": null, // Set of players that did not buzz in time
      "currentQuestion": null, // Pair<Category, Difficulty>
      "currentSelector": host,
      "currentAnswerer": null, // Index of buzzedIn
      "currentAnswers": null, // Set of indexes
    };
  }

  @override
  Either<CheckResultFailure, dynamic> getGameResponse(
      {required Map<String, dynamic> request,
      required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    switch (request["type"]) {
      case "getQuestions":
        return Right({
          for (var c in gameState["categories"] as Set<String>) c: questions[c]!
        });
      case "getCurrentQuestion":
        final question = gameState["currentQuestion"] as Pair<String, String>;
        return Right(questions[question.key]![question.value]!);
      case "getCurrentCorrectIndex":
        final question = gameState["currentQuestion"] as Pair<String, String>;
        return Right(questions[question.key]![question.value]!["correctIndex"]);
      case "getDifficulties":
        return const Right(["1", "2", "3", "4", "5"]);
    }
    return super.getGameResponse(
        request: request,
        player: player,
        gameState: gameState,
        players: players,
        host: host);
  }

  @override
  void processEvent(
      {required GameEvent event,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    switch (event.payload["type"]) {
      case "selectQuestion":
        final selectedQuestion =
            Pair(event["category"] as String, event["difficulty"] as String);
        gameState["currentQuestion"] = selectedQuestion;
        gameState["state"] = "buzzing";
        gameState["buzzedIn"] = <Player>[];
        gameState["notBuzzedIn"] = <Player>{};
        break;
      case "buzzIn":
        if (event["status"]) {
          (gameState["buzzedIn"] as List).add(event.author);
        } else {
          (gameState["notBuzzedIn"] as Set).add(event.author);
        }
        if ((gameState["buzzedIn"] as List).length +
                (gameState["notBuzzedIn"] as Set).length >=
            players.length) {
          gameState["state"] = "answering";
          gameState["currentAnswerer"] = 0;
          gameState["currentAnswers"] = <int>{};
        }
        break;
      case "answerQuestion":
        Pair<String, String> question = gameState["currentQuestion"];
        (gameState["currentAnswers"] as Set).add(event["index"]);
        if (questions[question.key]![question.value]!["correctIndex"] ==
            event["index"]) {
          gameState["scores"][event.author] += int.parse(question.value);
          gameState["currentSelector"] = event.author;
          gameState["state"] = "selecting";
          gameState["answeredQuestions"].add(question);
        } else {
          gameState["currentAnswerer"]++;
          if (gameState["currentAnswerer"] >=
              (gameState["buzzedIn"] as List).length) {
            gameState["currentSelector"] = gameState["buzzedIn"][0];
            gameState["state"] = "selecting";
            gameState["answeredQuestions"].add(question);
          }
        }
        break;
    }
  }

  @override
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host}) {
    switch (event["type"]) {
      case "selectQuestion":
        if (gameState["state"] != "selecting") {
          return const CheckResultFailure("Invalid state");
        }
        if (player != gameState["currentSelector"]) {
          return const CheckResultFailure("It is not your turn to select");
        }
        if ((gameState["answeredQuestions"] as Set)
            .contains(Pair(event["category"], event["difficulty"]))) {
          return const CheckResultFailure("Question has already been answered");
        }
        break;
      case "buzzIn":
        if (gameState["state"] != "buzzing") {
          return const CheckResultFailure("Invalid state");
        }
        if ((gameState["buzzedIn"] as List).contains(player)) {
          return const CheckResultFailure("Already buzzed in");
        }
        break;
      case "answerQuestion":
        if (gameState["state"] != "answering") {
          return const CheckResultFailure("Invalid state");
        }
        if (player != gameState["buzzedIn"][gameState["currentAnswerer"]]) {
          return const CheckResultFailure("It is not your turn to answer");
        }
        if (gameState["currentAnswers"].contains(event["index"])) {
          return const CheckResultFailure("Answer has already been picked");
        }
        break;
      default:
        return const CheckResultFailure("Event type does not exist");
    }
    return const CheckResultSuccess();
  }

  @override
  void onPlayerLeave(
      {required Player player,
      required Map<String, dynamic> gameState,
      required List<Player> players,
      required List<Player> oldPlayers,
      required Player host,
      required Random random}) {
    switch (gameState["state"]) {
      case "selecting":
        if (gameState["currentSelector"] == player) {
          gameState["currentSelector"] = players.firstOrNull;
        }
        break;
      case "buzzing":
        final buzzedIn = gameState["buzzedIn"] as List;
        final notBuzzedIn = gameState["notBuzzedIn"] as Set;
        if (buzzedIn.contains(player)) buzzedIn.remove(player);
        if (notBuzzedIn.contains(player)) notBuzzedIn.remove(player);
        if (buzzedIn.length + notBuzzedIn.length >= players.length) {
          gameState["state"] = "answering";
          gameState["currentAnswerer"] = 0;
          gameState["currentAnswers"] = <int>{};
        }
        break;
      case "answering":
        final buzzedIn = gameState["buzzedIn"] as List<Player>;
        final index = buzzedIn.indexOf(player);
        buzzedIn.remove(player);
        if (index > -1 && index < gameState["currentAnswerer"]) {
          gameState["currentAnswerer"]--;
        }
        if (gameState["currentAnswerer"] >=
            (gameState["buzzedIn"] as List).length) {
          gameState["currentSelector"] = gameState["buzzedIn"][0];
          gameState["state"] = "selecting";
          gameState["answeredQuestions"].add(gameState["currentQuestion"]);
        }
        break;
    }
  }

  @override
  Map<String, dynamic>? checkGameEnd(
      {required Map<String, dynamic> gameState,
      required List<Player> players,
      required Player host,
      required Random random}) {
    if ((gameState["answeredQuestions"] as Set).length >=
        (gameState["categories"] as Set).length * 5) {
      final scores = gameState["scores"] as Map<Player, int>;
      final winners = scores.entries
          .where((pair) => pair.value == scores.values.max)
          .map((pair) => pair.key.name);
      return {"winnerName": winners.join(", "), "draw": false};
    }
    return null;
  }
}
