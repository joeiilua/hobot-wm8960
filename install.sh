#!/bin/bash -x



# Author: jiale01.luo <jiale01.luo@horizon.ai>
# Create Time: 2023-05-10 16:47:23
# Modified by: jiale01.luo <jiale01.luo@horizon.ai>
# Modified time: 2023-09-20 18:33:41


if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)" 1>&2
    exit -1
fi

som_name=$(cat /sys/class/socinfo/som_name)
if [ x${som_name} != x'8' ] && [ x${som_name} != x'b' ]; then #v1.0
    echo "This script is only for Pi 2.0 or SOM!" 1>&2
    exit -1
fi

if [ x${som_name} != x'8' ];then
    echo "Board type: Pi V2.0"
elif [ ${som_name} != x'b' ];then
    echo "Board type: SOM"
fi

kill -9 $(pidof pulseaudio)
echo -e "\033[32mYou are installing WM8960 CODEC driver...\033[0m"

rm /var/lib/alsa/asound.state -rf

echo -e "\033[32mLoading driver...\033[0m"


echo -e "\033[32mCreating ALSA configuration file(asound.state)...\033[0m"

if [ -d "/etc/wm8960_config/" ]; then
    echo -e "\033[33mDirectory \"/etc/wm8960_config/\" exists\033[0m"
    echo -e "\033[33mCopy asound configuration files unconditionally\033[0m"
else
    echo -e "\033[32mCreating directory /etc/wm8960_config \033[0m"
    mkdir -p /etc/wm8960_config/
fi
cp wm8960_asound.state /etc/wm8960_config
ln -s /etc/wm8960_config/wm8960_asound.state /var/lib/alsa/asound.state


if [ $? == 0 ]; then
    echo -e "\033[32mRestore setting success!\033[0m"
else
    echo -e "\033[31mRestore setting failed!\033[0m"
    exit 1
fi

echo -e "\033[32mConfiguring ~/.config/pulse/default.pa\033[0m"

mkdir -pv ~/.config/pulse/

cp -v /etc/pulse/default.pa ~/.config/pulse/default.pa


if [ x${som_name} != x'b' ];then
    sed -i 's/load-module module-udev-detect/load-module module-alsa-sink device=hw:0,1 mmap=false tsched=0 fragments=2 fragment_size=960 rate=48000 channels=2 rewind_safeguard=960\nload-module module-alsa-source device=hw:0,0 mmap=false tsched=0 fragments=2 fragment_size=960 rate=48000 channels=2/g' ~/.config/pulse/default.pa
else
    sed -i 's/load-module module-udev-detect/load-module module-alsa-sink device=hw:0,0 mmap=false tsched=0 fragments=2 fragment_size=960 rate=48000 channels=2 rewind_safeguard=960\nload-module module-alsa-source device=hw:0,1 mmap=false tsched=0 fragments=2 fragment_size=960 rate=48000 channels=2/g' ~/.config/pulse/default.pa
fi

echo -e "\033[32mDo you want to load the driver automatically at startup? (y/n):\033[0m"

read ans

if [ $ans == 'y' ]; then
    sed -i '/blacklist snd-soc-wm8960/d' /usr/lib/modprobe.d/blacklist-hobot.conf
    sed -i '/blacklist hobot-cpudai/d' /usr/lib/modprobe.d/blacklist-hobot.conf
    sed -i '/blacklist hobot-i2s-dma/d' /usr/lib/modprobe.d/blacklist-hobot.conf
    sed -i '/blacklist hobot-snd-wm8960/d' /usr/lib/modprobe.d/blacklist-hobot.conf
    sed -i '/blacklist hobot_i2s_dma/d' /usr/lib/modprobe.d/blacklist-hobot.conf
    sed -i '/blacklist hobot_cpudai/d' /usr/lib/modprobe.d/blacklist-hobot.conf

    statements="snd-soc-wm8960\nhobot-cpudai\nhobot-i2s-dma\nhobot-snd-wm8960"
    if ! grep -qwFf <(echo -e $statements) "/etc/modules"; then
        echo -e $statements >>/etc/modules
    fi
fi

modprobe snd-soc-wm8960
modprobe hobot-i2s-dma
modprobe hobot-cpudai
modprobe hobot-snd-wm8960

rm /var/lib/alsa/asound.state -rf

alsactl restore


echo -e "\033[32mInstall success!\033[0m"
