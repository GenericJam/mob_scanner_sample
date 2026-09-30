defmodule ScannerSample.HomeScreenTest do
  # Tier-1 screen test: drives the screen in the BEAM, no device or emulator
  # needed. `use Mob.ScreenCase` gives mount_screen/3, render_event/3,
  # render_info/2, assigns/1, the tree queries (find / text / flatten), and
  # assert_renderable/2. See the `Mob.ScreenCase` docs for the full surface and
  # the testing-pyramid guidance: this is the fast tier you want most tests in.
  #
  # async: false because the home screen reads and writes the shared theme in
  # Mob.State. A screen that keeps all its state in assigns can use async: true.
  use Mob.ScreenCase, async: false

  alias ScannerSample.HomeScreen

  test "mounts and renders a tree the native layer can draw" do
    view = mount_screen(HomeScreen)
    # Asserts every node the screen emits is a type Compose / SwiftUI renders.
    assert_renderable(view)
  end

  test "switching to the light theme updates the assign" do
    view = HomeScreen |> mount_screen() |> render_info({:tap, :theme_light})
    assert assigns(view).theme == :light
  end

  # The message shapes MobScanner delivers back to the screen that called
  # MobScanner.scan/2 (identical on iOS and Android).
  test "a scan result lands in last_scan" do
    view =
      HomeScreen
      |> mount_screen()
      |> render_info({:scan, :result, %{type: :qr, value: "https://example.com"}})

    assert assigns(view).last_scan == "qr: https://example.com"
  end

  test "a cancelled scan is recorded" do
    view = HomeScreen |> mount_screen() |> render_info({:scan, :cancelled})
    assert assigns(view).last_scan == ":cancelled"
  end

  test "the camera permission result is tracked" do
    view = HomeScreen |> mount_screen() |> render_info({:permission, :camera, :granted})
    assert assigns(view).camera == :granted
  end
end
