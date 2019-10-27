defmodule VirusWarsWeb.GameChannelTest do
  use VirusWarsWeb.ChannelCase
  alias VirusWars.Lobby
  alias VirusWars.GameServer
  alias VirusWarsWeb.GameChannel
  alias VirusWarsWeb.UserSocket

  setup do
    room = Lobby.init_room()

    Lobby.add(room)

    {:ok, %{id: player_1_id, player: :player_1}} = GameServer.join(room.id)

    {:ok, %{id: player_2_id, player: :player_2}} = GameServer.join(room.id)

    %{game_id: room.id, player_1_id: player_1_id, player_2_id: player_2_id}
  end

  test "join game", %{game_id: game_id, player_1_id: player_1_id, player_2_id: player_2_id} do
    {:ok, %{id: player_1_id, player: :player_1}, socket} =
      socket(UserSocket)
      |> subscribe_and_join(GameChannel, "game:" <> game_id, %{"playerId" => player_1_id})

    {:ok, %{id: player_2_id, player: :player_2}, socket} =
      socket(UserSocket)
      |> subscribe_and_join(GameChannel, "game:" <> game_id, %{"playerId" => player_2_id})
  end

  test "join game with invalid credentials", %{game_id: game_id} do
    {:error, %{reason: :no_such_player}} =
      socket(UserSocket)
      |> subscribe_and_join(GameChannel, "game:" <> game_id, %{"playerId" => "hehehe"})

    {:error, %{reason: :no_such_room}} =
      socket(UserSocket)
      |> subscribe_and_join(GameChannel, "game:" <> "hehehehe")
  end
end
