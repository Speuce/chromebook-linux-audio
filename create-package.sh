#!/usr/bin/bash
PACKAGE="package"
rm -r $PACKAGE
# Files that conditionally go in /etc
SHARE_DIR="$PACKAGE/usr/share/eupnea-audio"
mkdir -p $SHARE_DIR
# Common directory
mkdir -p $PACKAGE/etc/modprobe.d
install -D -t $PACKAGE/etc/main.lua.d conf/common/51-increase-headroom.lua
# avs
cp conf/avs/snd-avs.conf $SHARE_DIR
cp conf/avs/51-avs-dmic.lua $SHARE_DIR
cp conf/avs/tplg/max98357a-tplg.bin $SHARE_DIR
mkdir -p $PACKAGE/etc/wireplumber/main.lua.d
touch $PACKAGE/etc/wireplumber/main.lua.d/51-avs-dmic.lua
touch $PACKAGE/etc/modprobe.d/snd-avs.conf
# hifi2
cp conf/sof/hifi2-sof.conf $SHARE_DIR
touch $PACKAGE/etc/modprobe.d/hifi2-sof.conf
# apl sof
cp conf/sof/apl-sof.conf $SHARE_DIR
touch $PACKAGE/etc/modprobe.d/apl-sof.conf
# sof
cp conf/sof/snd-sof.conf $SHARE_DIR
touch $PACKAGE/etc/modprobe.d/snd-sof.conf

# Files that are always in /usr
# install_ucm()
mkdir -p $PACKAGE/usr/share/alsa/ucm2
# FIXME: Ubuntu 23.10 seems to already have the `common` folder
# cp -r chromebook-ucm-conf/common $PACKAGE/usr/share/alsa/ucm2/common
cp -r chromebook-ucm-conf/codecs $PACKAGE/usr/share/alsa/ucm2/codecs
# FIXME: Ubuntu 23.10 seems to already have the `codecs/hda` folder
rm -r $PACKAGE/usr/share/alsa/ucm2/codecs/hda
cp -r chromebook-ucm-conf/platforms $PACKAGE/usr/share/alsa/ucm2/platforms
mkdir -p $PACKAGE/usr/share/alsa/ucm2/conf.d
cp -r chromebook-ucm-conf/sof-rt5682 $PACKAGE/usr/share/alsa/ucm2/conf.d/sof-rt5682
cp -r chromebook-ucm-conf/sof-cs42l42 $PACKAGE/usr/share/alsa/ucm2/conf.d/sof-cs42l42
# avs tplg
mkdir -p $PACKAGE/usr/lib/firmware/intel
cp -r conf/avs/tplg $PACKAGE/usr/lib/firmware/intel/avs
echo "" >$PACKAGE/usr/lib/firmware/intel/avs/max98357a-tplg.bin
# rpl
TPLG_PATH="/usr/lib/firmware/intel/sof-tplg"
mkdir -p $PACKAGE/$TPLG_PATH
for TPLG in "cs35l41" "max98357a-rt5682-4ch" "max98357a-rt5682" "max98360a-cs42l42" "max98360a-nau8825" "max98360a-rt5682-2way" "max98360a-rt5682-4ch" "max98360a-rt5682" "max98373-nau8825" "max98390-rt5682" "max98390-ssp2-rt5682-ssp0" "nau8825" "rt1019-nau8825" "rt1019-rt5682" "rt5682" "rt711" "sdw-max98373-rt5682"; do
  ln -s $TPLG_PATH/sof-adl-$TPLG.tplg $PACKAGE/$TPLG_PATH/sof-rpl-$TPLG.tplg
  ln -s $TPLG_PATH/sof-adl-$TPLG.tplg.xz $PACKAGE/$TPLG_PATH/sof-rpl-$TPLG.tplg.xz
done
# FIXME: Once this is shipped in distros remove it
cp -r conf/sof/tplg $PACKAGE/usr/lib/firmware/intel/sof-tplg
# mendocino
mkdir -p $PACKAGE/usr/lib/fimware/amd/sof/community
cp -r conf/amd-sof/fw $PACKAGE/usr/lib/fimware/amd/sof/community
mkdir -p $PACKAGE/usr/lib/fimware/amd/sof/community
cp -r conf/amd-sof/tplg $PACKAGE/usr/lib/fimware/amd/sof-tplg
# FIXME: Files from upstream may need to be copied

# Programs / scripts
cargo build --release
install -D -t $PACKAGE/usr/bin target/release/eupnea-audio-start
mkdir -p $PACKAGE/usr/bin
cp eupnea-audio-stop.sh $PACKAGE/usr/bin/eupnea-audio-stop
install -D -t $PACKAGE/usr/lib/systemd/system eupnea-audio.service
install -D -t $PACKAGE/usr/share/eupnea-audio conf/boards.json
cp chromebook-unique-id.sh $PACKAGE/usr/bin/chromebook-unique-id
install -D -t $PACKAGE/etc/eupnea-audio audio-choices.toml
