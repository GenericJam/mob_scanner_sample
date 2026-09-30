defmodule ScannerSample.HomeScreen do
  @moduledoc "Landing screen for ScannerSample."
  use Mob.Screen

  def mount(_params, _session, socket) do
    theme = Mob.State.get(:theme, :dark)
    Mob.Theme.set(theme_to_module(theme))
    # Activated plugins that ship a demo screen show up here automatically —
    # no edits needed when you add or remove one in mob.exs.
    {:ok,
     Mob.Socket.assign(socket,
       theme: theme,
       plugin_screens: Mob.Plugins.screens(),
       camera: :unknown,
       last_scan: "none"
     )}
  end

  def render(assigns) do
    ~MOB"""
    <Scroll background={:background}>
      <Column background={:background} padding={:space_lg}>
        <Image src={logo_src(assigns.theme)} width={120} height={120} content_mode="fit" />
        <Spacer size={16} />
        <Text text="ScannerSample" text_size={:xl} text_color={:on_surface} padding={:space_sm} />
        <Text text="BEAM running on device" text_size={:sm} text_color={:primary} padding={4} />
        <Spacer size={24} />
        <Text text={"camera: #{assigns.camera}"} text_size={:sm} text_color={:on_surface} padding={4} />
        <Text text={"last scan: #{assigns.last_scan}"} text_size={:sm} text_color={:on_surface} padding={4} />
        {nav_button("Request camera", :request_camera)}
        <Spacer size={8} />
        {nav_button("Scan QR", :scan)}
        <Spacer size={24} />
        {plugin_section(assigns.plugin_screens)}
        <Spacer size={32} />
        <Text text="Theme" text_size={:sm} text_color={:muted} padding={4} />
        <Spacer size={8} />
        <Row fill_width={true}>
          {theme_tab("Light", :light, assigns.theme)}
          <Spacer size={8} />
          {theme_tab("Dark",  :dark,  assigns.theme)}
        </Row>
      </Column>
    </Scroll>
    """
  end

  def handle_info({:tap, :request_camera}, socket) do
    {:noreply, Mob.Permissions.request(socket, :camera)}
  end

  def handle_info({:tap, :scan}, socket) do
    {:noreply, MobScanner.scan(socket, formats: [:qr])}
  end

  def handle_info({:permission, :camera, status}, socket) do
    {:noreply, Mob.Socket.assign(socket, :camera, status)}
  end

  def handle_info({:scan, :result, %{type: type, value: value}}, socket) do
    {:noreply, Mob.Socket.assign(socket, :last_scan, "#{type}: #{value}")}
  end

  def handle_info({:scan, other}, socket) do
    {:noreply, Mob.Socket.assign(socket, :last_scan, inspect(other))}
  end

  def handle_info({:tap, :theme_light}, socket) do
    Mob.Theme.set(Mob.Theme.Light)
    Mob.State.put(:theme, :light)
    {:noreply, Mob.Socket.assign(socket, :theme, :light)}
  end

  def handle_info({:tap, :theme_dark}, socket) do
    Mob.Theme.set(Mob.Theme.Dark)
    Mob.State.put(:theme, :dark)
    {:noreply, Mob.Socket.assign(socket, :theme, :dark)}
  end

  # Plugin demo screens are tagged by their route string (see plugin_section/1).
  def handle_info({:tap, route}, socket) when is_binary(route) do
    case Enum.find(socket.assigns.plugin_screens, &(&1.default_route == route)) do
      %{module: mod} -> {:noreply, Mob.Socket.push_screen(socket, mod)}
      nil -> {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp nav_button(label, tag) do
    tap = {self(), tag}

    ~MOB(<Button text={label} background={:primary} text_color={:on_primary} text_size={:lg} padding={:space_md} fill_width={true} on_tap={tap} />)
  end

  # A nav button per activated plugin that declares a screen, built from the
  # live plugin registry so the list tracks mob.exs with no edits here.
  defp plugin_section([]), do: %{type: :column, props: %{}, children: []}

  defp plugin_section(screens) do
    heading = %{
      type: :text,
      props: %{text: "Device Plugins", text_size: :sm, text_color: :muted, padding: 4},
      children: []
    }

    spacer = %{type: :spacer, props: %{size: 12}, children: []}

    buttons =
      Enum.flat_map(screens, fn %{default_route: route} ->
        [spacer, nav_button(plugin_label(route), route)]
      end)

    %{type: :column, props: %{fill_width: true}, children: [spacer, heading | buttons]}
  end

  # "/mob_camera/demo" -> "Camera". Falls back gracefully for any route shape.
  defp plugin_label(route) do
    route
    |> String.trim_leading("/")
    |> String.split("/")
    |> List.first()
    |> to_string()
    |> String.replace_prefix("mob_", "")
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp theme_tab(label, key, active) do
    {bg, fg} = if key == active, do: {:primary, :on_primary}, else: {:surface, :on_surface}
    tap = {self(), :"theme_#{key}"}

    ~MOB(<Button text={label} background={bg} text_color={fg} text_size={:sm} padding={:space_sm} weight={1} on_tap={tap} />)
  end

  defp theme_to_module(:light), do: Mob.Theme.Light
  defp theme_to_module(_), do: Mob.Theme.Dark

  # mob_logo_dark.png is the dark-on-light logo (for light backgrounds);
  # mob_logo_light.png is light-on-dark.
  defp logo_src(:light), do: Path.join(rootdir(), "mob_logo_dark.png")
  defp logo_src(_), do: Path.join(rootdir(), "mob_logo_light.png")

  # ROOTDIR is set by mob_beam (iOS) and mob_beam.c (Android) before erl_start,
  # so this fallback is only exercised in unit tests on the host. Don't put
  # `Path.expand("~/...")` directly in `System.get_env/2`'s default argument —
  # default args evaluate eagerly, and Android's BEAM has no `HOME` env var,
  # so `System.user_home!()` would raise `RuntimeError` and abort the screen
  # before the first render.
  defp rootdir do
    case System.get_env("ROOTDIR") do
      nil -> Path.expand("~/.mob/runtime/ios-sim")
      val -> val
    end
  end
end
