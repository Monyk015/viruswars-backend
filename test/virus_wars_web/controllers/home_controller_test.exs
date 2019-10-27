defmodule VirusWarsWeb.HomeControllerTest do
  use VirusWarsWeb.ConnCase
  alias VirusWars.Lobby
  alias VirusWars.GameServer

  test "create game", %{conn: conn} do
    response =
      conn
      |> post(Routes.home_path(conn, :create))
      |> json_response(200)

    assert %{"id" => id} = response
  end

  test "join game", %{conn: conn} do
    %{"id" => id} = conn |> post(Routes.home_path(conn, :create)) |> json_response(200)

    %{"id" => player_id, "player" => "player_1"} =
      conn |> post(Routes.home_path(conn, :join), %{"id" => id}) |> json_response(200)

    %{"id" => player_id, "player" => "player_2"} =
      conn |> post(Routes.home_path(conn, :join), %{"id" => id}) |> json_response(200)

    %{"error" => "all_busy"} =
      conn |> post(Routes.home_path(conn, :join), %{"id" => id}) |> json_response(400)
  end
end
