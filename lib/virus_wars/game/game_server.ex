defmodule VirusWars.GameServer do
  alias VirusWars.Game
  use GenServer

  def init([id]) do
    game = Game.init(id)
    {:ok, game}
  end

  def start_link([], id: id) do
    GenServer.start_link(__MODULE__, [id], name: name(id))
  end

  def get_player_by_id(game_id, player_id) do
    GenServer.call(name(game_id), {:get_player_by_id, player_id})
  end

  def join(game_id) do
    GenServer.call(name(game_id), {:join})
  end

  def move(game_id, coords, player_id) do
    GenServer.call(name(game_id), {:move, player_id, coords})
  end

  def get_game(game_id) do
    GenServer.call(name(game_id), {:get_game})
  end

  def handle_call({:get_player_by_id, player_id}, _from, game) do
    result = Game.get_player_by_id(game, player_id)

    {:reply, result, game}
  end

  def handle_call({:join}, _from, game) do
    case Game.join(game) do
      {:ok, player, game} -> {:reply, {:ok, player}, game}
      {:err, :all_busy, game} -> {:reply, {:err, :all_busy}, game}
    end
  end

  def handle_call({:move, player_id, coords}, _from, game) do
    with {:some, player} <- Game.get_player_by_id(game, player_id),
         _ <- IO.inspect(player),
         true <-
           player.player ==
             game.current_player do
      game = Game.make_move(game, coords)
      {:reply, {:ok, game}, game}
    else
      false ->
        {:reply, {:err, :wrong_player}, game}

      {:none} ->
        {:reply, {:err, :wrong_player}, game}
    end
  end

  def handle_call({:get_game}, _from, game) do
    {:reply, game, game}
  end

  defp name(id), do: {:via, :global, id}
end
