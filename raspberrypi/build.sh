#!/usr/bin/env bash
# Build ColAndreas for the Raspberry Pi (64-bit ARM Linux) open.mp server and
# pack raspberrypi/dist/ColAndreas-linux-arm64.tar.gz, laid out to unpack into
# the server folder:
#
#   plugins/ColAndreas.so                 the plugin
#   plugins/lib{BulletDynamics,BulletCollision,LinearMath}.so.3.24
#                                         Bullet physics, found via RPATH $ORIGIN
#   qawno/include/colandreas.inc          Pawn include
#
# Builds in a linux/arm64 Debian 12 container (glibc 2.36, matching Raspberry
# Pi OS bookworm and the Pi-Andreas/omp-server-raspberrypi server). Native on
# an arm64 host (Apple Silicon, GitHub's arm64 runners); emulated elsewhere.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/raspberrypi/dist"

docker run --rm --platform linux/arm64 -v "$ROOT:/src" -w /src debian:bookworm bash -euo pipefail -c '
	apt-get update -qq
	apt-get install -y -qq --no-install-recommends build-essential cmake libbullet-dev patchelf >/dev/null
	cmake -S . -B build-raspberrypi -DCMAKE_BUILD_TYPE=Release >/dev/null
	cmake --build build-raspberrypi -j"$(nproc)"

	stage=raspberrypi/dist/stage
	rm -rf "$stage"
	mkdir -p "$stage/plugins" "$stage/qawno/include"
	cp build-raspberrypi/ColAndreas.so "$stage/plugins/"
	# Debian ships Bullet only as shared libraries: bundle them next to the
	# plugin so the Pi needs no extra packages.
	for lib in BulletDynamics BulletCollision LinearMath; do
		cp -L "/usr/lib/aarch64-linux-gnu/lib$lib.so.3.24" "$stage/plugins/"
	done
	patchelf --set-rpath "\$ORIGIN" "$stage/plugins/ColAndreas.so"
	cp Server/include/colandreas.inc "$stage/qawno/include/"
'

tar --no-xattrs -C "$DIST/stage" -czf "$DIST/ColAndreas-linux-arm64.tar.gz" plugins qawno
rm -rf "$DIST/stage"
(cd "$DIST" && sha256sum ColAndreas-linux-arm64.tar.gz 2>/dev/null || shasum -a 256 ColAndreas-linux-arm64.tar.gz) > "$DIST/ColAndreas-linux-arm64.tar.gz.sha256"
echo "built: $DIST/ColAndreas-linux-arm64.tar.gz"
