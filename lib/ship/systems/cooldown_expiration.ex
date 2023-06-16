defmodule Ship.Systems.CooldownExpiration do
  @moduledoc """
  Documentation for CooldownExpiration system.
  """
  @behaviour ECSx.System

  alias Ship.Components.AttackCooldown

  @impl ECSx.System
  def run do
    now = DateTime.utc_now()
    cooldowns = AttackCooldown.get_all()

    Enum.each(cooldowns, &remove_when_expired(&1, now))
  end

  defp remove_when_expired({entity, timestamp}, now) do
    case DateTime.compare(now, timestamp) do
      :lt -> :noop
      _ -> AttackCooldown.remove(entity)
    end
  end
end
