#!/bin/sh
# author: catatonicprime
# date: March 2018

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/sd/lib:/sd/usr/lib
export PATH=$PATH:/sd/usr/bin:/sd/usr/sbin

touch /tmp/tor.progress

if [ "$1" = "install" ]; then
  opkg update
  if [ "$2" = "internal" ]; then
    opkg install tor-geoip tor
  elif [ "$2" = "sd" ]; then
    opkg install tor-geoip tor --dest sd

    # When installing to SD it seems opkg isn't adding the tor user. Hack it in.
    grep "^tor:x:52:tor$" /etc/group || echo "tor:x:52:tor" >> /etc/group
    grep "^tor:x:52:52:tor:/var/run/tor:/bin/false$" /etc/passwd || echo "tor:x:52:52:tor:/var/run/tor:/bin/false" >> /etc/passwd
    grep "^tor:x:0:0:99999:7:::$" /etc/shadow || echo "tor:x:0:0:99999:7:::" >> /etc/shadow

    mkdir /etc/tor
    ln -s /sd/etc/tor/torrc /etc/tor/torrc
    ln -s /sd/usr/sbin/tor /usr/sbin/tor
    ln -s /sd/etc/init.d/tor /etc/init.d/tor
  fi
  mkdir -p /etc/config/tor/
  cp /pineapple/modules/tor/files/torrc /etc/config/tor
  mkdir -p /etc/config/tor/services
  chown tor:tor /etc/config/tor/services
  chown root:tor /etc/tor/torrc
  chmod g+r /etc/tor/torrc
  sed -i "s/ \/usr\/sbin\/tor/ \/sd\/usr\/sbin\/tor/" /sd/etc/init.d/tor
elif [ "$1" = "remove" ]; then
    opkg remove tor-geoip tor
    # remove associated tor users which we may have manually installed for SD installations.
    grep "^tor:x:52:tor$" /etc/group && sed -i '/^tor:x:52:tor$/d' /etc/group
    grep "^tor:x:52:52:tor:/var/run/tor:/bin/false$" /etc/passwd && sed -i '/^tor:x:52:52:tor:\/var\/run\/tor:\/bin\/false$/d' /etc/passwd
    grep "^tor:x:0:0:99999:7:::$" /etc/shadow && sed -i '/^tor:x:0:0:99999:7:::$/d' /etc/shadow
    rm -rf /etc/tor
    sed -i '/tor\/scripts\/autostart_tor.sh/d' /etc/rc.local
    rm -rf /etc/config/tor
    rm -f /usr/sbin/tor
    rm -f /etc/init.d/tor
fi

rm /tmp/tor.progress
