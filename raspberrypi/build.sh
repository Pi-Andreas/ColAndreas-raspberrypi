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

# Everything, packaging included, runs in the container; the outputs are then
# handed back to the calling user (the container runs as root, which on a
# Linux host would leave root-owned files the caller can't overwrite).
docker run --rm --platform linux/arm64 -v "$ROOT:/src" -w /src \
	-e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" debian:bookworm bash -euo pipefail -c '
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

	tar --owner=0 --group=0 -C "$stage" -czf raspberrypi/dist/ColAndreas-linux-arm64.tar.gz plugins qawno
	rm -rf "$stage"
	(cd raspberrypi/dist && sha256sum ColAndreas-linux-arm64.tar.gz > ColAndreas-linux-arm64.tar.gz.sha256)
	chown -R "$HOST_UID:$HOST_GID" raspberrypi/dist build-raspberrypi
'
echo "built: $ROOT/raspberrypi/dist/ColAndreas-linux-arm64.tar.gz"
