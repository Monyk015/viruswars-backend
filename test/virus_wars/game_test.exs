defmodule VirusWars.GameTest do
  use ExUnit.Case, async: true
  alias VirusWars.Game
  import Ecto
  @max_coord 12

  setup do
    id = Ecto.UUID.generate()
    game = Game.init(id)

    %{game: game}
  end

  test "player can join", %{game: game} do
    assert game.player_1 == game.player_2
    assert game.player_1 == nil

    {:ok, player_1, game} = Game.join(game)
    {:ok, player_2, game} = Game.join(game)

    assert player_1.id != player_2.id
    assert game.player_1 == player_1

    {:err, :all_busy, game_2} = Game.join(game)

    assert game == game_2
  end

  test "new game has board", %{game: game} do
    assert game.board != nil

    board = game.board

    cell = Game.init_cell({0, 0})

    assert board[{0, 0}] == cell

    assert board[{@max_coord, @max_coord}] == cell

    assert game.moves_left == 1
    assert game.current_player == :player_1
  end

  test "new cell" do
    assert {:empty, false} == Game.init_cell({0, 2})
    assert {:empty, false} == Game.init_cell({2, 2})
    assert {:empty, true} == Game.init_cell({@max_coord, @max_coord})
    assert {:empty, true} == Game.init_cell({@max_coord, 0})
  end

  test "should make a first move", %{game: game} do
    game =
      game
      |> Game.make_move({0, 1})

    assert game.message == {:move_not_available, {0, 1}}

    game = game |> Game.make_move({0, 0})

    assert game.board[{0, 0}] == {:living, :player_1, false}
    assert game.current_player == :player_2
    assert game.is_first_moves == true
    assert game.board[{@max_coord, @max_coord}] == {:empty, true}
    assert game.moves_left == 1

    game = game |> Game.make_move({@max_coord, @max_coord})

    assert game.board[{@max_coord, @max_coord}] == {:living, :player_2, false}
    assert game.board[{@max_coord, 0}] == {:empty, false}
    assert game.is_first_moves == false
    assert game.current_player == :player_1
    assert game.moves_left == 3
    assert game.board[{0, 1}] == {:empty, true}
    assert game.board[{1, 0}] == {:empty, true}
    assert game.board[{@max_coord, @max_coord - 1}] == {:empty, false}

    game = game |> Game.make_move({0, 2})

    assert game.message == {:move_not_available, {0, 2}}

    game = game |> Game.make_move({1, 0})

    assert game.board[{1, 0}] == {:living, :player_1, false}
    assert game.moves_left == 2
    assert game.current_player == :player_1
    assert game.board[{2, 0}] == {:empty, true}

    game =
      game
      |> Game.make_move({2, 0})
      |> Game.make_move({2, 1})

    assert game.message == :ok
    assert game.current_player == :player_2
    assert game.board[{0, 3}] == {:empty, false}
    assert game.board[{@max_coord, @max_coord - 1}] == {:empty, true}

    game =
      game
      # player_2
      |> Game.make_move({12, 11})
      |> Game.make_move({12, 10})
      |> Game.make_move({11, 10})
      # player_1
      |> Game.make_move({2, 2})
      |> Game.make_move({2, 3})
      |> Game.make_move({2, 4})
      # player_2
      |> Game.make_move({11, 9})
      |> Game.make_move({11, 8})
      |> Game.make_move({11, 7})

    IO.inspect(game.board)
    assert game.current_player == :player_1
    assert game.message == :ok
    assert game.board[{2, 3}] == {:living, :player_1, false}

    game =
      game
      # player_1
      |> Game.make_move({2, 5})
      |> Game.make_move({3, 5})
      |> Game.make_move({4, 5})
      # player_2
      |> Game.make_move({11, 6})
      |> Game.make_move({10, 6})
      |> Game.make_move({9, 6})
      # player_1
      |> Game.make_move({5, 5})
      |> Game.make_move({5, 6})
      |> Game.make_move({5, 4})
      # player_2
      |> Game.make_move({8, 6})
      |> Game.make_move({8, 7})
      |> Game.make_move({8, 5})
      # player_1
      |> Game.make_move({5, 3})
      |> Game.make_move({5, 2})
      |> Game.make_move({5, 7})
      # player_2
      |> Game.make_move({8, 4})
      |> Game.make_move({8, 3})
      |> Game.make_move({8, 2})

    assert game.message == :ok

    # start first attack

    game =
      game
      # player 1
      |> Game.make_move({6, 5})
      |> Game.make_move({7, 5})

    assert game.message == :ok
    assert game.board[{8, 5}] == {:living, :player_2, true}

    game =
      game
      |> Game.make_move({8, 5})

    assert game.message == :ok
    assert game.board[{8, 5}] == {:armor, :player_1, false}

    game =
      game
      # player_2
      |> Game.make_move({7, 7})
      |> Game.make_move({6, 7})
      |> Game.make_move({5, 7})

    assert game.message == :ok
    assert game.board[{5, 7}] == {:armor, :player_2, false}
    assert game.board[{8, 5}] == {:armor, :player_1, true}

    game =
      game
      # player_1
      |> Game.make_move({8, 4})

    assert game.message == :ok
    assert game.board[{8, 4}] == {:armor, :player_1, true}
    assert game.board[{9, 4}] == {:empty, true}

    game =
      game
      |> Game.make_move({8, 3})
      |> Game.make_move({8, 6})

    assert game.message == :ok

    game =
      game
      # player_2
      |> Game.make_move({7, 6})
      |> Game.make_move({7, 5})
      |> Game.make_move({6, 5})

    assert game.message == :ok
    assert game.board[{8, 3}] == {:armor, :player_1, false}
  end
end
