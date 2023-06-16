defmodule Ship.Components.YVelocity do
  @moduledoc """
  Documentation for YVelocity components.
  """
  use ECSx.Component,
    value: :integer,
    unique: true
end
