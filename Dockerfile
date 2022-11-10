FROM ubuntu:20.04
RUN apt update
ENV TZ=America/New_York
RUN apt install samba -y
RUN apt install vim -y
EXPOSE 139
EXPOSE 445
ENTRYPOINT ["/bin/sh", "-c", "sleep infinity"]