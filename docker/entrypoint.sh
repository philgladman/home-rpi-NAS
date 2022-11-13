/etc/init.d/smbd restart

useradd $USER -p $PASSWORD --no-create-home --shell /usr/sbin/nologin

(echo ${PASSWORD}; echo ${PASSWORD}) | smbpasswd -s -a $USER

sleep infinity