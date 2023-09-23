defmodule Ship.SystemUtils do
  @moduledoc """
  Useful math functions used by multiple systems.
  """

  alias Ship.Components.XPosition
  alias Ship.Components.YPosition

  def distance_between(entity_1, entity_2) do
    x_1 = XPosition.get(entity_1)
    x_2 = XPosition.get(entity_2)
    y_1 = YPosition.get(entity_1)
    y_2 = YPosition.get(entity_2)

    x = abs(x_1 - x_2)
    y = abs(y_1 - y_2)

    :math.sqrt(x ** 2 + y ** 2)
  end
end
