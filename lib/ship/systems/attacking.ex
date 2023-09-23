defmodule Ship.Systems.Attacking do
  @moduledoc """
  Documentation for Attacking system.
  """
  @behaviour ECSx.System

  alias Ship.Components.AttackCooldown
  alias Ship.Components.AttackDamage
  alias Ship.Components.AttackRange
  alias Ship.Components.AttackSpeed
  alias Ship.Components.AttackTarget
  alias Ship.Components.ImageFile
  alias Ship.Components.IsProjectile
  alias Ship.Components.ProjectileDamage
  alias Ship.Components.ProjectileTarget
  alias Ship.Components.SeekingTarget
  alias Ship.Components.XPosition
  alias Ship.Components.XVelocity
  alias Ship.Components.YPosition
  alias Ship.Components.YVelocity
  alias Ship.SystemUtils

  @impl ECSx.System
  def run do
    attack_targets = AttackTarget.get_all()

    Enum.each(attack_targets, &attack_if_ready/1)
  end

  defp attack_if_ready({self, target}) do
    cond do
      SystemUtils.distance_between(self, target) > AttackRange.get(self) ->
        # If the target ever leaves our attack range, we want to remove the AttackTarget
        # and begin searching for a new one.
        AttackTarget.remove(self)
        SeekingTarget.add(self)

      AttackCooldown.exists?(self) ->
        # We're still within range, but waiting on the cooldown
        :noop

      :otherwise ->
        spawn_projectile(self, target)
        add_cooldown(self)
    end
  end

  defp spawn_projectile(self, target) do
    attack_damage = AttackDamage.get(self)
    x = XPosition.get(self)
    y = YPosition.get(self)
    # Armor reduction should wait until impact to be calculated
    cannonball_entity = Ecto.UUID.generate()

    IsProjectile.add(cannonball_entity)
    XPosition.add(cannonball_entity, x)
    YPosition.add(cannonball_entity, y)
    XVelocity.add(cannonball_entity, 0)
    YVelocity.add(cannonball_entity, 0)
    ImageFile.add(cannonball_entity, "cannonball.svg")
    ProjectileTarget.add(cannonball_entity, target)
    ProjectileDamage.add(cannonball_entity, attack_damage)
  end

  defp add_cooldown(self) do
    now = DateTime.utc_now()
    ms_between_attacks = calculate_cooldown_time(self)
    cooldown_until = DateTime.add(now, ms_between_attacks, :millisecond)

    AttackCooldown.add(self, cooldown_until)
  end

  # We're going to model AttackSpeed with a float representing attacks per second.
  # The goal here is to convert that into milliseconds per attack.
  defp calculate_cooldown_time(self) do
    attacks_per_second = AttackSpeed.get(self)
    seconds_per_attack = 1 / attacks_per_second

    ceil(seconds_per_attack * 1000)
  end
end
