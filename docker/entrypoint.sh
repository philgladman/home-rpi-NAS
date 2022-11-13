/etc/init.d/smbd restart

groupadd smbusers -g 1010

useradd $USER -p $PASSWORD --no-create-home --shell /usr/sbin/nologin -g smbusers

(echo ${PASSWORD}; echo ${PASSWORD}) | smbpasswd -s -a $USER

sleep infinity