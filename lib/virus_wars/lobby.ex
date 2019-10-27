defmodule VirusWars.Lobby do
  use Agent
  import Ecto
  alias VirusWars.GameSupevisor

  def init_room() do
    id = Ecto.UUID.generate()
    %{id: id}
  end

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def all do
    Agent.get(__MODULE__, & &1)
  end

  def add(room) do
    {:ok, _pid} = GameSupevisor.start_child(room.id)
    Agent.update(__MODULE__, fn rooms -> [room | rooms] end)
  end
end
