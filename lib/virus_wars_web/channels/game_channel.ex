defmodule VirusWarsWeb.GameChannel do
  use Phoenix.Channel
  alias VirusWars.GameServer

  def join("game:" <> game_id, message, socket) do
    player_id = message["playerId"]

    try do
      case GameServer.get_player_by_id(game_id, player_id) do
        {:some, player} -> {:ok, player, socket}
        {:none} -> {:error, %{reason: :no_such_player}}
        otherwise -> IO.inspect(otherwise)
      end
    catch
      :exit, reason ->
        {:error, %{reason: :no_such_room}}
    end
  end
end
