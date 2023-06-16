defmodule Ship.Systems.Driver do
  @moduledoc """
  Documentation for Driver system.
  """
  @behaviour ECSx.System

  alias Ship.Components.XPosition
  alias Ship.Components.YPosition
  alias Ship.Components.XVelocity
  alias Ship.Components.YVelocity

  @impl ECSx.System
  def run do
    for {entity, x_velocity} <- XVelocity.get_all() do
      x_position = XPosition.get_one(entity)
      new_x_position = x_position + x_velocity
      XPosition.update(entity, new_x_position)
    end

    # Once the x-values are updated, do the same for the y-values
    for {entity, y_velocity} <- YVelocity.get_all() do
      y_position = YPosition.get_one(entity)
      new_y_position = y_position + y_velocity
      YPosition.update(entity, new_y_position)
    end

    # run/0 should always return :ok
    :ok
  end
end
