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

    assert game.message == :move_not_available

    game = game |> Game.make_move({0, 0})

    assert game.board[{0, 0}] == {:living, :player_1, false}
    assert game.current_player == :player_2
    assert game.is_first_moves == true
    assert game.board[{@max_coord, @max_coord}] == {:empty, true}

    game = game |> Game.make_move({@max_coord, @max_coord})

    assert game.board[{@max_coord, @max_coord}] == {:living, :player_2, false}
    assert game.board[{@max_coord, 0}] == {:empty, false}
    assert game.is_first_moves == false
    assert game.current_player == :player_1
  end
end
