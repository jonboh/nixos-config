# About this flake
This is my nixos-config flake. It is a redacted version of the configurations I've been using since I
started using NixOS in 2023. The commit messages are kept, but their contents have been purged, as
there were some configuration values I was not comfortable sharing.
In the unlikely event you need something mentioned in one of these commits and its not present,
contact me through email and I'll fetch you what you need from the original archived repo.

This flake contains the configuration of most of my devices, these include my PCs, raspberries
and bananapi routers.

This flake is shared to allow others to write their own, you won't be able to build the outputs
of this flake without access to the private inputs.

# Systems
## Workstation
My main PC. A keyboard-centric i3 setup.

## Lab
An older PC I use on my workbench, replicates the workstation setup. Its main purpose is to open
schematics.

## Laptop
Similar to my workstation but on the go.

## WSL
A WSL configuration that replicates some of workstation tools, like the editor and kitty config.
I used this at one point I needed to use Windows, Its been a while since I booted that machine, so
this configuration might be slightly broken due to some refactors.

## Tars
A raspberry 4 I use to run services on my network.
It runs Grafana, InfluxDB, loki, MQTT, syncthing, atuin, radicale (and whatever I find interesting :D)...
The MQTT broker is used by a set of [iaq-boards](https://github.com/nkitanov/iaq_board) I built
to track the air quality on my home.

## Forge
A raspberry 4 connected to my SidenwinderX2 3D printer.
Runs `fluidd` and `klipper`.
Klipper is built using Nix as well. Klipper is buit for the two MCUs I have, the printer and the
resonance sensor I use for calibration.

## Brick
A Raspberry 5 I mostly use to build `aarch64-linux` packages.

# Network
## Charon
My main router. A Bananapi R3 powered by [nixos-sbc](https://github.com/nakato/nixos-sbc)
If you want to learn how to configure it, check this [blogspot](https://github.com/ghostbuster91/blogposts/blob/main/router2023/main.md)
## Citadel
This is a second Bananapi R3 which I use to provide good WiFi coverage to my lab.

`Charon` and `Citadel` have a vlan configuration that allows me to segment my network,
irrespective of wether devices are connected through wire or wifi.

## Sentinel
This is a Raspberry 5 which runs [Suricata](https://suricata.io/) and analyzes my network traffic.
The metrics generated can be seen in a Grafana dashboard.
