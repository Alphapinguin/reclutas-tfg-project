FROM debian:bullseye
MAINTAINER Juan Antonio juanantoniomtzfns@gmail.com
# Update packages and distro, remove unnecessary
RUN apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y && apt-get autoremove -y