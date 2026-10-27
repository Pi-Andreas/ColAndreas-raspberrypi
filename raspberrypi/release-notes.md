ColAndreas **v1.4.0** (upstream tag `v1.4.0.3`) built for the **Raspberry Pi open.mp server** — 64-bit ARM Linux, Raspberry Pi OS bookworm or newer. Use it with [Pi-Andreas/omp-server-raspberrypi](https://github.com/Pi-Andreas/omp-server-raspberrypi).

### Install

In the server folder (e.g. `~/omp-server`):

```bash
tar -xzf ColAndreas-linux-arm64.tar.gz
```

That adds `plugins/ColAndreas.so`, the Bullet physics libraries it needs (`plugins/lib*.so.3.24`, found next to the plugin, nothing to install) and `qawno/include/colandreas.inc`.

Then:
1. Copy your `ColAndreas.cadb` to `scriptfiles/colandreas/ColAndreas.cadb`. It is generated from your own GTA: San Andreas files with ColAndreasWizard (see the README) and is not part of this release.
2. Add `"ColAndreas"` to `pawn.legacy_plugins` in `config.json`.

Memory: the collision world takes a few hundred MB once `CA_Init()` runs; a 2 GB Pi or larger is recommended alongside a full gamemode.

SHA-256 `ColAndreas-linux-arm64.tar.gz`: `{{SHA256}}`
