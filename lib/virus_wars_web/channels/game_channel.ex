defmodule VirusWarsWeb.GameChannel do
  use Phoenix.Channel
  alias VirusWars.GameServer
  alias Phoenix.Socket

  def join("game:" <> game_id, message, socket) do
    player_id = message["playerId"]

    try do
      case GameServer.get_player_by_id(game_id, player_id) do
        {:some, player} ->
          socket =
            socket |> Socket.assign(:player_id, player_id) |> Socket.assign(:game_id, game_id)

          send(Kernel.self(), :after_join)
          {:ok, player, socket}

        {:none} ->
          {:error, %{reason: :no_such_player}}

        otherwise ->
          {:error, %{reason: otherwise}}
      end
    catch
      :exit, reason ->
        {:error, %{reason: :no_such_room}}
    end
  end

  def handle_info(:after_join, socket) do
    game_id = socket.assigns.game_id
    broadcast!(socket, "game", %{game: GameServer.get_game(game_id)})
    {:noreply, socket}
  end

  def handle_in("move", %{"coords" => [i, j], "playerId" => player_id}, socket) do
    game_id = socket.assigns.game_id

    case(GameServer.move(game_id, {i, j}, player_id)) do
      {:ok, game} ->
        broadcast!(socket, "game", %{game: game})

      {:err, :wrong_player} ->
        IO.inspect("wrong_player")
        broadcast!(socket, "wrong_player", %{})
    end

    {:noreply, socket}
  end
end
