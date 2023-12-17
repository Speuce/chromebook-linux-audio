#!/usr/bin/bash
umount \
  /etc/modprobe.d/apl-sof.conf \
  /etc/modprobe.d/hifi2-sof.conf \
  /etc/modprobe.d/snd-avs.conf \
  /etc/modprobe.d/snd-sof.conf \
  /etc/main.lua.d/51-increase-headroom.lua \
  /etc/wireplumber/main.lua.d/51-avs-dmic.lua \
  /usr/lib/firmware/intel/avs/max98357a-tplg.bin
