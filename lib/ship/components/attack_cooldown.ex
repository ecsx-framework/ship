defmodule Ship.Components.AttackCooldown do
  @moduledoc """
  Documentation for AttackCooldown components.
  """
  use ECSx.Component,
    value: :datetime,
    unique: true
end
