defmodule VirusWarsWeb.Router do
  use VirusWarsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", VirusWarsWeb do
    pipe_through :api
  end
end
