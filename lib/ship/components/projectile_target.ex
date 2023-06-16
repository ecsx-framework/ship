defmodule Ship.Components.ProjectileTarget do
  @moduledoc """
  Documentation for ProjectileTarget components.
  """
  use ECSx.Component,
    value: :binary,
    unique: true
end
