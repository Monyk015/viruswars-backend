defmodule VirusWars.Game do
  import Ecto
  alias __MODULE__

  @type player :: %{
          id: String.t(),
          player: :player_1 | :player_2
        }

  @max_coord 12

  @type coords :: {integer(), integer()}

  @type player_type :: :player_1 | :player_2

  @type is_move_available :: bool()

  @type is_connected :: bool()

  @type cell ::
          {:empty, is_move_available()}
          | {:living, player_type(), is_move_available()}
          | {:armor, player_type(), is_connected()}

  @type board :: %{
          required(coords()) => cell()
        }

  @type t :: %Game{
          id: String.t(),
          player_1: player() | nil,
          player_2: player() | nil,
          current_player: player_type(),
          moves_left: 0..3,
          board: board(),
          is_first_moves: bool(),
          message: :ok | :cannot_move_on_armor | :move_not_available
        }
  defstruct [
    :id,
    :player_1,
    :player_2,
    :current_player,
    :moves_left,
    :board,
    :is_first_moves,
    :message
  ]

  def init_player(player) do
    uuid = Ecto.UUID.generate()
    %{id: uuid, player: player}
  end

  defguard is_corner(i, j)
           when (i == j and (j == @max_coord or j == 0)) or
                  (i == 0 and j == @max_coord) or (j == 0 and i == @max_coord)

  def init_cell({i, j}) when not is_corner(i, j) do
    {:empty, false}
  end

  def init_cell({i, j}) when is_corner(i, j) do
    {:empty, true}
  end

  def init_board() do
    for i <- 0..@max_coord,
        j <- 0..@max_coord,
        into: %{},
        do: {{i, j}, init_cell({i, j})}
  end

  def init(id) do
    %Game{
      player_1: nil,
      player_2: nil,
      id: id,
      current_player: :player_1,
      moves_left: 1,
      board: init_board(),
      is_first_moves: true,
      message: :ok
    }
  end

  def join(%Game{player_1: nil, player_2: nil} = game) do
    player_1 = init_player(:player_1)
    {:ok, player_1, %Game{game | player_1: player_1, player_2: nil}}
  end

  def join(%Game{player_1: player_1, player_2: nil} = game) do
    player_2 = init_player(:player_2)
    {:ok, player_2, %Game{game | player_1: player_1, player_2: player_2}}
  end

  def join(%Game{player_1: _, player_2: _} = game) do
    {:err, :all_busy, game}
  end

  def get_player_by_id(game, player_id) do
    cond do
      game.player_1.id == player_id ->
        {:some, game.player_1}

      game.player_2.id == player_id ->
        {:some, game.player_2}

      true ->
        {:none}
    end
  end

  def make_move(game, coords) do
    cell = game.board[coords]

    case cell do
      {:armor, _, _} ->
        %{game | message: :cannot_move_on_armor}

      {:living, _, false} ->
        %{game | message: :move_not_available}

      {:empty, false} ->
        %{game | message: :move_not_available}

      {:empty, true} ->
        cell = {:living, game.current_player, false}
        board = %{game.board | coords => cell}

        game = %{
          game
          | message: :ok,
            board: board,
            current_player: change_player(game.current_player)
        }
    end
  end

  def change_player(:player_1), do: :player_2
  def change_player(:player_2), do: :player_1
end
