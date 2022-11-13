/etc/init.d/smbd restart

export USER=phil

export PASSWORD=testpass

useradd "$USER" -p "$PASSWORD" --no-create-home --shell /usr/sbin/nologin

(echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -s -a "$USER"

#/bin/bash
sleep infinity