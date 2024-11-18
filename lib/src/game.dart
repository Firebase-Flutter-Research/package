import 'dart:math';

import 'package:either_dart/either.dart';
import 'event.dart';
import 'player.dart';

abstract class CheckResult {
  final String? message;

  const CheckResult([this.message]);
}

class CheckResultSuccess extends CheckResult {
  const CheckResultSuccess([super.message]);
}

class CheckResultFailure extends CheckResult {
  const CheckResultFailure([super.message]);
}

class UndefinedGameResponse extends CheckResultFailure {
  const UndefinedGameResponse() : super("Undefined Game Response");
}

abstract class GameState {}

abstract class Game {
  // Game ID name
  String get name;

  // Count of required players to play
  int get requiredPlayers;

  // Number of max allowed players
  int get playerLimit;

  // Return game state before moves are performed.
  GameState getInitialGameState(
      {required List<Player> players,
      required Player host,
      required Random random});

  // Check if player can perform an event and return the result.
  CheckResult checkPerformEvent(
      {required Map<String, dynamic> event,
      required Player player,
      required GameState gameState,
      required List<Player> players,
      required Player host});

  // Process new event and return if it was successful.
  void processEvent(
      {required GameEvent event,
      required GameState gameState,
      required List<Player> players,
      required Player host,
      required Random random});

  // Handle when player leaves room.
  void onPlayerLeave(
      {required Player player,
      required GameState gameState,
      required List<Player> players,
      required List<Player> oldPlayers,
      required Player host,
      required Random random});

  // Determine when the game has ended and return game end data.
  Map<String, dynamic>? checkGameEnd(
      {required GameState gameState,
      required List<Player> players,
      required Player host,
      required Random random});

  Either<CheckResultFailure, dynamic> getGameResponse(
      {required Map<String, dynamic> request,
      required Player player,
      required GameState gameState,
      required List<Player> players,
      required Player host}) {
    return const Left(UndefinedGameResponse());
  }
}