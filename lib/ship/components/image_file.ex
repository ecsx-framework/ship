defmodule Ship.Components.ImageFile do
  @moduledoc """
  Documentation for ImageFile components.
  """
  use ECSx.Component,
    value: :binary,
    unique: true
end
