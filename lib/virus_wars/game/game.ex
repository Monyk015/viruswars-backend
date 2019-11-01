defmodule VirusWars.Game do
  import Ecto
  alias __MODULE__

  defimpl String.Chars, for: Tuple do
    def to_string(tuple) do
      String.Chars.to_string(Tuple.to_list(tuple))
    end
  end

  defimpl Jason.Encoder, for: Tuple do
    def encode(value, opts) do
      Jason.Encoder.List.encode(Tuple.to_list(value), opts)
    end
  end

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
          message:
            :ok
            | {:cannot_move_on_armor, coords()}
            | {:move_not_available, coords()}
            | {:loss, player_type()}
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

  defimpl Jason.Encoder, for: Game do
    alias Jason.Encode

    def encode(value, opts) do
      board =
        value.board
        |> Enum.map(fn {{i, j}, val} ->
          {"#{i},#{j}", Tuple.to_list(val)}
        end)
        |> Enum.into(%{})

      message = if value.message == :ok, do: :ok, else: Tuple.to_list(value.message)

      value = %Game{value | board: board, message: message}
      res = Encode.map(Map.take(value, [:current_player, :moves_left, :board, :message]), opts)
      res
    end
  end

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

  def get_player_by_id(game, nil) do
    {:none}
  end

  def get_player_by_id(game, player_id) do
    cond do
      game.player_1 != nil and game.player_1.id == player_id ->
        {:some, game.player_1}

      game.player_2 != nil and game.player_2.id == player_id ->
        {:some, game.player_2}

      true ->
        {:none}
    end
  end

  def make_move(%{is_first_moves: true} = game, coords) do
    board = game.board
    cell = board[coords]

    case cell do
      {:empty, false} ->
        %{game | message: {:move_not_available, coords}}

      {:empty, true} ->
        cell = {:living, game.current_player, false}
        board = %{board | coords => cell}

        is_first_moves =
          if game.current_player == :player_1 do
            true
          else
            false
          end

        moves_left =
          if is_first_moves do
            1
          else
            3
          end

        next_player = change_player(game.current_player)

        board =
          if not is_first_moves do
            {board, _} = recalculate_available(board, next_player)
            board
          else
            board
          end

        game = %{
          game
          | message: :ok,
            board: board,
            current_player: next_player,
            is_first_moves: is_first_moves,
            moves_left: moves_left
        }

        game
    end
  end

  def make_move(game, coords) do
    other_player = change_player(game.current_player)
    cell = game.board[coords]

    case cell do
      {:armor, _, _} ->
        %{game | message: {:cannot_move_on_armor, coords}}

      {:living, _, false} ->
        %{game | message: {:move_not_available, coords}}

      {:empty, false} ->
        %{game | message: {:move_not_available, coords}}

      {:empty, true} ->
        cell = {:living, game.current_player, false}
        put_cell_and_recalculate(game, coords, cell)

      {:living, ^other_player, true} ->
        cell = {:armor, game.current_player, false}
        put_cell_and_recalculate(game, coords, cell)
    end
  end

  defp put_cell_and_recalculate(game, coords, cell) do
    board = game.board

    board = %{board | coords => cell}

    moves_left = game.moves_left - 1

    {moves_left, next_player} =
      if moves_left == 0 do
        {3, change_player(game.current_player)}
      else
        {moves_left, game.current_player}
      end

    board =
      board
      |> disconnect_all_armor()
      |> recalculate_connected_armor()

    {board, is_there_available} = recalculate_available(board, next_player)

    message = if is_there_available, do: :ok, else: {:loss, next_player}

    game = %{
      game
      | message: message,
        board: board,
        moves_left: moves_left,
        current_player: next_player
    }

    game
  end

  def recalculate_available(board, next_player) do
    board =
      board
      |> Enum.map(fn
        {coords, {:empty, _}} -> {coords, {:empty, false}}
        {coords, {:living, player, _}} -> {coords, {:living, player, false}}
        {coords, otherwise} -> {coords, otherwise}
      end)
      |> Enum.into(%{})

    other_player = change_player(next_player)

    board =
      board
      |> Enum.map(fn
        {coords, {:empty, _}} ->
          {coords,
           {:empty,
            living_cell_nearby?(board, coords, next_player) or
              connected_armor_nearby?(board, coords, next_player)}}

        # looking for cells belonging to other player with next_player cells nearby
        {coords, {:living, ^other_player, _}} ->
          {coords,
           {:living, other_player,
            living_cell_nearby?(board, coords, next_player) or
              connected_armor_nearby?(board, coords, next_player)}}

        {coords, otherwise} ->
          {coords, otherwise}
      end)
      |> Enum.into(%{})

    is_there_available =
      Enum.any?(board, fn
        {_coords, {:empty, true}} -> true
        {_coords, {:living, _, true}} -> true
        _ -> false
      end)

    {board, is_there_available}
  end

  defp right({@max_coord, _}), do: :none
  defp right({i, j}), do: {:some, {i + 1, j}}

  defp left({0, _}), do: :none
  defp left({i, j}), do: {:some, {i - 1, j}}

  defp up({_, @max_coord}), do: :none
  defp up({i, j}), do: {:some, {i, j + 1}}

  defp down({_, 0}), do: :none
  defp down({i, j}), do: {:some, {i, j - 1}}

  defp living_cell_nearby?(board, coords, player) do
    cond do
      living_cell_in_direction?(board, coords, player, &up(&1)) -> true
      living_cell_in_direction?(board, coords, player, &down(&1)) -> true
      living_cell_in_direction?(board, coords, player, &right(&1)) -> true
      living_cell_in_direction?(board, coords, player, &left(&1)) -> true
      true -> false
    end
  end

  defp living_cell_in_direction?(board, coords, player, func) do
    with {:some, coords} <- func.(coords),
         {:living, ^player, _} <- board[coords] do
      true
    else
      _ ->
        false
    end
  end

  defp connected_armor_nearby?(board, coords, player) do
    cond do
      connected_armor_in_direction?(board, coords, player, &up(&1)) -> true
      connected_armor_in_direction?(board, coords, player, &down(&1)) -> true
      connected_armor_in_direction?(board, coords, player, &right(&1)) -> true
      connected_armor_in_direction?(board, coords, player, &left(&1)) -> true
      true -> false
    end
  end

  defp connected_armor_in_direction?(board, coords, player, func) do
    with {:some, coords} <- func.(coords),
         {:armor, ^player, true} <- board[coords] do
      true
    else
      _ ->
        false
    end
  end

  defp disconnect_all_armor(board) do
    board
    |> Enum.map(fn
      {coords, {:armor, player, _}} -> {coords, {:armor, player, false}}
      otherwise -> otherwise
    end)
    |> Enum.into(%{})
  end

  defp recalculate_connected_armor(board) do
    {board_list, acc} =
      board
      |> Enum.map_reduce(0, fn
        {coords, {:armor, next_player, false}}, acc ->
          is_connected =
            living_cell_nearby?(board, coords, next_player) or
              connected_armor_nearby?(board, coords, next_player)

          acc = if is_connected, do: acc + 1, else: acc

          cell = {:armor, next_player, is_connected}

          {{coords, cell}, acc}

        otherwise, acc ->
          {otherwise, acc}
      end)

    board = board_list |> Enum.into(%{})

    if acc == 0 do
      board
    else
      recalculate_connected_armor(board)
    end
  end

  @spec change_player(:player_1 | :player_2) :: :player_1 | :player_2
  def change_player(:player_1), do: :player_2
  def change_player(:player_2), do: :player_1
end
