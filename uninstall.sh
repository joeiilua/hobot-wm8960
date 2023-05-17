# Author: jiale01.luo <jiale01.luo@horizon.ai>
# Create Time: 2023-05-10 16:47:23
# Modified by: jiale01.luo <jiale01.luo@horizon.ai>
# Modified time: 2023-05-16 13:30:18

#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 1>&2
   exit -1
fi
echo -e "\033[32mYou are uninstalling WM8960 CODEC driver...\033[0m"

rm /var/lib/alsa/asound.state

modprobe -r hobot_snd_wm8960
modprobe -r hobot_i2s_dma
modprobe -r hobot_cpudai
modprobe -r snd_soc_wm8960

rm /etc/wm8960_config/ -rf

sed -i '/load-module module-alsa-sink device=hw:0,1 mmap=false tsched=0 fragments=2 fragment_size=960 rate=48000 channels=2 rewind_safeguard=960/d' /etc/pulse/default.pa
sed -i 's/load-module module-alsa-source device=hw:0,0 mmap=false tsched=0 fragments=2 fragment_size=960 rate=48000 channels=2/load-module module-udev-detect/g' /etc/pulse/default.pa
sed -i "/snd-soc-wm8960/,/hobot-snd-wm8960/d" /etc/modules

# statements="snd-soc-wm8960\nhobot-cpudai\nhobot-i2s-dma\nhobot-snd-wm8960"
#     if ! grep -qwFf <(echo -e $statements) "/etc/modules"; then
#         echo -e $statements >> /etc/modules
#     fi


blacklists="blacklist snd-soc-wm8960\nblacklist hobot-cpudai\nblacklist hobot-i2s-dma\nblacklist hobot-snd-wm8960\nblacklist hobot_i2s_dma\nblacklist hobot_cpudai\n"

echo -e $blacklists >> /usr/lib/modprobe.d/blacklist-hobot.conf

echo -e "\033[32mUninstalling done!\033[0m"
