defmodule ShipWeb.GameLive do
  use ShipWeb, :live_view

  alias Ship.Components.HullPoints
  alias Ship.Components.ImageFile
  alias Ship.Components.IsProjectile
  alias Ship.Components.PlayerSpawned
  alias Ship.Components.XPosition
  alias Ship.Components.YPosition

  def mount(_params, %{"player_token" => token} = _session, socket) do
    player = Ship.Players.get_player_by_session_token(token)

    socket =
      socket
      |> assign(player_entity: player.id)
      |> assign(keys: MapSet.new())
      # These will configure the scale of our display compared to the game world
      |> assign(game_world_size: 100, screen_height: 30, screen_width: 50)
      |> assign_loading_state()

    if connected?(socket) do
      unless PlayerSpawned.exists?(player.id) do
        ECSx.ClientEvents.add(player.id, :spawn_ship)
        # The first load will now have additional responsibilities
        send(self(), :first_load)
      end
    end

    {:ok, socket}
  end

  defp assign_loading_state(socket) do
    assign(socket,
      x_coord: nil,
      y_coord: nil,
      current_hp: nil,
      player_ship_image_file: nil,
      other_ships: [],
      x_offset: 0,
      y_offset: 0,
      projectiles: [],
      loading: true
    )
  end

  def handle_info(:first_load, socket) do
    :ok = wait_for_spawn(socket.assigns.player_entity)

    socket =
      socket
      |> assign_player_ship()
      |> assign_other_ships()
      |> assign_projectiles()
      |> assign_offsets()
      |> assign(loading: false)

    :timer.send_interval(50, :refresh)

    {:noreply, socket}
  end

  def handle_info(:refresh, socket) do
    socket =
      socket
      |> assign_player_ship()
      |> assign_other_ships()
      |> assign_projectiles()
      |> assign_offsets()

    {:noreply, socket}
  end

  defp wait_for_spawn(player_entity) do
    if PlayerSpawned.exists?(player_entity) do
      :ok
    else
      Process.sleep(10)
      wait_for_spawn(player_entity)
    end
  end

  defp assign_player_ship(socket) do
    x = XPosition.get(socket.assigns.player_entity)
    y = YPosition.get(socket.assigns.player_entity)
    hp = HullPoints.get(socket.assigns.player_entity)
    image = ImageFile.get(socket.assigns.player_entity)

    assign(socket, x_coord: x, y_coord: y, current_hp: hp, player_ship_image_file: image)
  end

  defp assign_other_ships(socket) do
    other_ships =
      Enum.reject(all_ships(), fn {entity, _, _, _} -> entity == socket.assigns.player_entity end)

    assign(socket, other_ships: other_ships)
  end

  defp all_ships do
    for {ship, _hp} <- HullPoints.get_all() do
      x = XPosition.get(ship)
      y = YPosition.get(ship)
      image = ImageFile.get(ship)
      {ship, x, y, image}
    end
  end

  defp assign_projectiles(socket) do
    projectiles =
      for projectile <- IsProjectile.get_all() do
        x = XPosition.get(projectile)
        y = YPosition.get(projectile)
        image = ImageFile.get(projectile)
        {projectile, x, y, image}
      end

    assign(socket, projectiles: projectiles)
  end

  defp assign_offsets(socket) do
    # Note: the socket must already have updated player coordinates before assigning offsets!
    %{screen_width: screen_width, screen_height: screen_height} = socket.assigns
    %{x_coord: x, y_coord: y, game_world_size: game_world_size} = socket.assigns

    x_offset = calculate_offset(x, screen_width, game_world_size)
    y_offset = calculate_offset(y, screen_height, game_world_size)

    assign(socket, x_offset: x_offset, y_offset: y_offset)
  end

  defp calculate_offset(coord, screen_size, game_world_size) do
    case coord - div(screen_size, 2) do
      offset when offset < 0 -> 0
      offset when offset > game_world_size - screen_size -> game_world_size - screen_size
      offset -> offset
    end
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    if MapSet.member?(socket.assigns.keys, key) do
      # Already holding this key - do nothing
      {:noreply, socket}
    else
      # We only want to add a client event if the key is defined by the `keydown/1` helper below
      maybe_add_client_event(socket.assigns.player_entity, key, &keydown/1)
      {:noreply, assign(socket, keys: MapSet.put(socket.assigns.keys, key))}
    end
  end

  def handle_event("keyup", %{"key" => key}, socket) do
    # We don't have to worry about duplicate keyup events
    # But once again, we will only add client events for keys that actually do something
    maybe_add_client_event(socket.assigns.player_entity, key, &keyup/1)
    {:noreply, assign(socket, keys: MapSet.delete(socket.assigns.keys, key))}
  end

  defp maybe_add_client_event(player_entity, key, fun) do
    case fun.(key) do
      :noop -> :ok
      event -> ECSx.ClientEvents.add(player_entity, event)
    end
  end

  defp keydown(key) when key in ~w(w W ArrowUp), do: {:move, :north}
  defp keydown(key) when key in ~w(a A ArrowLeft), do: {:move, :west}
  defp keydown(key) when key in ~w(s S ArrowDown), do: {:move, :south}
  defp keydown(key) when key in ~w(d D ArrowRight), do: {:move, :east}
  defp keydown(_key), do: :noop

  defp keyup(key) when key in ~w(w W ArrowUp), do: {:stop_move, :north}
  defp keyup(key) when key in ~w(a A ArrowLeft), do: {:stop_move, :west}
  defp keyup(key) when key in ~w(s S ArrowDown), do: {:stop_move, :south}
  defp keyup(key) when key in ~w(d D ArrowRight), do: {:stop_move, :east}
  defp keyup(_key), do: :noop

  def render(assigns) do
    ~H"""
    <div id="game" phx-window-keydown="keydown" phx-window-keyup="keyup">
      <svg
        viewBox={"#{@x_offset} #{@y_offset} #{@screen_width} #{@screen_height}"}
        preserveAspectRatio="xMinYMin slice"
      >
        <rect width={@game_world_size} height={@game_world_size} fill="#72eff8" />

        <%= if @loading do %>
          <text x={div(@screen_width, 2)} y={div(@screen_height, 2)} style="font: 1px serif">
            Loading...
          </text>
        <% else %>
          <image
            x={@x_coord}
            y={@y_coord}
            width="1"
            height="1"
            href={~p"/images/#{@player_ship_image_file}"}
          />
          <%= for {_entity, x, y, image_file} <- @projectiles do %>
            <image x={x} y={y} width="1" height="1" href={~p"/images/#{image_file}"} />
          <% end %>
          <%= for {_entity, x, y, image_file} <- @other_ships do %>
            <image x={x} y={y} width="1" height="1" href={~p"/images/#{image_file}"} />
          <% end %>
          <text x={@x_offset} y={@y_offset + 1} style="font: 1px serif">
            Hull Points: <%= @current_hp %>
          </text>
        <% end %>
      </svg>
    </div>
    """
  end
end
