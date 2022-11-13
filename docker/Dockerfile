FROM ubuntu:20.04
RUN apt update
ENV TZ=America/New_York
RUN apt install samba -y
RUN apt install vim -y
COPY smb.conf /etc/samba/smb.conf
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod 764 /usr/bin/entrypoint.sh
EXPOSE 139
EXPOSE 445
ENTRYPOINT ["/bin/sh", "-c", "/usr/bin/entrypoint.sh"]