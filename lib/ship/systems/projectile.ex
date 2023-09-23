defmodule Ship.Systems.Projectile do
  @moduledoc """
  Documentation for Projectile system.
  """
  @behaviour ECSx.System

  alias Ship.Components.ArmorRating
  alias Ship.Components.HullPoints
  alias Ship.Components.ImageFile
  alias Ship.Components.IsProjectile
  alias Ship.Components.ProjectileDamage
  alias Ship.Components.ProjectileTarget
  alias Ship.Components.XPosition
  alias Ship.Components.XVelocity
  alias Ship.Components.YPosition
  alias Ship.Components.YVelocity

  @cannonball_speed 3

  @impl ECSx.System
  def run do
    projectiles = IsProjectile.get_all()

    Enum.each(projectiles, fn projectile ->
      case ProjectileTarget.get(projectile, nil) do
        nil ->
          # The target has already been destroyed
          destroy_projectile(projectile)

        target ->
          continue_seeking_target(projectile, target)
      end
    end)
  end

  defp continue_seeking_target(projectile, target) do
    {dx, dy, distance} = get_distance_to_target(projectile, target)

    case distance do
      0 ->
        collision(projectile, target)

      distance when distance / @cannonball_speed <= 1 ->
        move_directly_to_target(projectile, {dx, dy})

      distance ->
        adjust_velocity_towards_target(projectile, {distance, dx, dy})
    end
  end

  defp get_distance_to_target(projectile, target) do
    target_x = XPosition.get(target)
    target_y = YPosition.get(target)
    target_dx = XVelocity.get(target)
    target_dy = YVelocity.get(target)
    target_next_x = target_x + target_dx
    target_next_y = target_y + target_dy

    x = XPosition.get(projectile)
    y = YPosition.get(projectile)

    dx = target_next_x - x
    dy = target_next_y - y

    {dx, dy, ceil(:math.sqrt(dx ** 2 + dy ** 2))}
  end

  defp collision(projectile, target) do
    damage_target(projectile, target)
    destroy_projectile(projectile)
  end

  defp damage_target(projectile, target) do
    damage = ProjectileDamage.get(projectile)
    reduction_from_armor = ArmorRating.get(target)
    final_damage_amount = damage - reduction_from_armor

    target_current_hp = HullPoints.get(target)
    target_new_hp = target_current_hp - final_damage_amount

    HullPoints.update(target, target_new_hp)
  end

  defp destroy_projectile(projectile) do
    IsProjectile.remove(projectile)
    XPosition.remove(projectile)
    YPosition.remove(projectile)
    XVelocity.remove(projectile)
    YVelocity.remove(projectile)
    ImageFile.remove(projectile)
    ProjectileTarget.remove(projectile)
    ProjectileDamage.remove(projectile)
  end

  defp move_directly_to_target(projectile, {dx, dy}) do
    XVelocity.update(projectile, dx)
    YVelocity.update(projectile, dy)
  end

  defp adjust_velocity_towards_target(projectile, {distance, dx, dy}) do
    # We know what is needed, but we need to slow it down, so its travel
    # will take more than one tick.  Otherwise the player will not see it!
    ticks_away = ceil(distance / @cannonball_speed)
    adjusted_dx = div(dx, ticks_away)
    adjusted_dy = div(dy, ticks_away)

    XVelocity.update(projectile, adjusted_dx)
    YVelocity.update(projectile, adjusted_dy)
  end
end
