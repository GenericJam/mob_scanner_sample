# mob_scanner sample

A minimal [Mob](https://hexdocs.pm/mob) app that scans QR codes with the
[`mob_scanner`](https://hex.pm/packages/mob_scanner) plugin. It was generated
with `mix mob.new scanner_sample --blank`; only the pieces below were added.

Verified on 2026-09-30 by scanning a real QR code on a Moto G Power 5G (2024,
Android) and an iPhone SE (3rd gen, iOS). The versions are pinned in `mix.exs`:

| Package       | Version |
|---------------|---------|
| `mob`         | 0.9.4   |
| `mob_dev`     | 0.7.3   |
| `mob_scanner` | 0.1.4   |
| `mob_camera`  | 0.1.9   |

## Run it

```bash
mix deps.get
mix mob.install                          # OTP runtimes, NDK check, icons
mix mob.provision                        # iOS device only: your Apple team + profile
mix mob.deploy --native --android        # or --ios, or --device <id>
```

Then tap **Request camera**, grant access, tap **Scan QR**, and point the
camera at a QR code. The decoded value shows as `last scan: qr: <value>`.

## What a scanner app needs

1. **Both plugins as deps** (`mix.exs`). `mob_camera` owns the `:camera`
   runtime permission and the iOS camera usage string that the scanner uses.

   ```elixir
   {:mob_scanner, "== 0.1.4"},
   {:mob_camera, "== 0.1.9"}
   ```

2. **Both plugins activated** (`mob.exs`). Adding a dep alone does nothing
   native: only activated plugins get their native code compiled into the app.

   ```elixir
   config :mob, :plugins, [:mob_camera, :mob_scanner]
   ```

3. **A native build after activating.** `mix mob.deploy --native` compiles the
   plugins' native code into the app binary. A plain `mix mob.deploy` or
   `mix mob.push` only ships Elixir code and leaves the old binary installed.

4. **Camera permission before scanning** (`lib/scanner_sample/home_screen.ex`):

   ```elixir
   Mob.Permissions.request(socket, :camera)
   def handle_info({:permission, :camera, :granted}, socket), do: ...
   ```

5. **Start a scan and handle the results**:

   ```elixir
   MobScanner.scan(socket, formats: [:qr])

   def handle_info({:scan, :result, %{type: :qr, value: value}}, socket), do: ...
   def handle_info({:scan, :cancelled}, socket), do: ...
   # iOS also sends {:scan, :not_available} when no camera can be opened
   ```

On Android the scanner's `<activity>` is added to `AndroidManifest.xml` by the
native build (inside the `mob:plugin-components` managed block). With
mob_scanner 0.1.2 or older you had to declare it by hand; that's no longer
needed.

## Troubleshooting

**`{:nif_not_loaded, [{:erlang, :nif_error, ...}, {:mob_scanner_nif, :scanner_scan, 1, ...}]}`**
means the installed app binary has no scanner native code. Check, in order:

- `:mob_scanner` is in `config :mob, :plugins` in `mob.exs`. `mix mob.plugins`
  lists each plugin as installed or activated.
- `mob.exs` is present and loads. Older generated projects gitignored
  `mob.exs`, so a clone has none, and with no `mob.exs` no plugins are activated.
- You ran `mix mob.deploy --native` after adding or activating the plugin.

**`ActivityNotFoundException ... io.mob.scanner.MobScannerActivity`** on
Android: upgrade to mob_scanner ≥ 0.1.3, or declare the activity yourself:

```xml
<activity android:name="io.mob.scanner.MobScannerActivity"
    android:exported="false"
    android:theme="@style/Theme.AppCompat.NoActionBar" />
```

**Black preview on iOS** after granting permission mid-scan: cancel and scan
again. Request `:camera` before calling `MobScanner.scan/2`.

## Tests

```bash
mix test
```

`test/scanner_sample/home_screen_test.exs` drives the screen in the BEAM with
the same messages the scanner delivers. No device needed.
