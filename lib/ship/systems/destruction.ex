defmodule Ship.Systems.Destruction do
  @moduledoc """
  Documentation for Destruction system.
  """
  @behaviour ECSx.System

  alias Ship.Components.ArmorRating
  alias Ship.Components.AttackCooldown
  alias Ship.Components.AttackDamage
  alias Ship.Components.AttackRange
  alias Ship.Components.AttackSpeed
  alias Ship.Components.AttackTarget
  alias Ship.Components.DestroyedAt
  alias Ship.Components.HullPoints
  alias Ship.Components.ProjectileTarget
  alias Ship.Components.SeekingTarget
  alias Ship.Components.XPosition
  alias Ship.Components.XVelocity
  alias Ship.Components.YPosition
  alias Ship.Components.YVelocity

  @impl ECSx.System
  def run do
    ships = HullPoints.get_all()

    Enum.each(ships, fn {entity, hp} ->
      if hp <= 0, do: destroy(entity)
    end)
  end

  defp destroy(entity) do
    ArmorRating.remove(entity)
    AttackCooldown.remove(entity)
    AttackDamage.remove(entity)
    AttackRange.remove(entity)
    AttackSpeed.remove(entity)
    AttackTarget.remove(entity)
    HullPoints.remove(entity)
    SeekingTarget.remove(entity)
    XPosition.remove(entity)
    XVelocity.remove(entity)
    YPosition.remove(entity)
    YVelocity.remove(entity)

    # when a ship is destroyed, other ships should stop targeting it
    untarget(entity)

    DestroyedAt.add(entity, DateTime.utc_now())
  end

  defp untarget(target) do
    for entity <- AttackTarget.search(target) do
      AttackTarget.remove(entity)
      SeekingTarget.add(entity)
    end

    for projectile <- ProjectileTarget.search(target) do
      ProjectileTarget.remove(projectile)
    end
  end
end
