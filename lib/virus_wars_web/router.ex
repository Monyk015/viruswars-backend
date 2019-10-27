defmodule VirusWarsWeb.Router do
  use VirusWarsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", VirusWarsWeb do
    pipe_through :api

    get "/home", HomeController, :index
    post "/create", HomeController, :create
    post "/join", HomeController, :join
  end
end
