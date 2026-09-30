import Config

# Register the Repo so Mix tasks (mix ecto.create, mix ecto.migrate) can
# discover it. The actual database path is configured at runtime in
# ScannerSample.Repo.init/2 via the MOB_DATA_DIR environment variable.
config :scanner_sample, ecto_repos: [ScannerSample.Repo]

# Wire the Repo into Mob.ScreenState so screens using `vsn:` get automatic
# state persistence. Remove this line to disable screen state persistence.
config :mob, :repo, ScannerSample.Repo
