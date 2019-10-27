defmodule VirusWarsWeb.HomeController do
  use VirusWarsWeb, :controller
  alias VirusWars.Lobby
  alias VirusWars.GameServer

  def index(conn, _params), do: json(conn, %{message: "hi"})

  def create(conn, _params) do
    room = Lobby.init_room()
    Lobby.add(room)
    conn |> json(room)
  end

  def join(conn, %{"id" => id}) do
    case GameServer.join(id) do
      {:ok, player} -> conn |> json(player)
      {:err, :all_busy} -> conn |> put_status(400) |> json(%{error: :all_busy})
    end
  end
end
