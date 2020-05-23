FROM debian:bullseye
LABEL maintainer="juanantoniomtzfns@gmail.com"
# Disable interaction in commands
ENV DEBIAN_FRONTEND noninteractive
# Update packages and distro, remove unnecessary dependencies
RUN apt-get update -qq\
    && apt-get upgrade -qq \
    && apt-get dist-upgrade -qq \
    && apt-get autoremove -qq \
    && apt-get install build-essential -qq \
    && apt-get install wget -qq
# Download and unzip asterisk's source code
RUN wget -P /usr/local/src/ https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-17.4.0.tar.gz \
    && cd /usr/local/src/ \
    && tar zxf asterisk-17.4.0.tar.gz
# Install dependencies and check prerequisites
RUN cd /usr/local/src/asterisk-17.4.0 \
    && ./contrib/scripts/install_prereq install \
    && ./configure \
    --without-dahdi \
    --without-pri \
    --without-radius
# Select modules
RUN make menuselect.makeopts \
    && menuselect/menuselect \
    # Asterisk modules [Enabled]
    --enable res_config_mysql \
    --enable app_skel \
    --enable app_ivrdemo \
    --enable CORE-SOUNDS-ES-WAV
    # Asterisk modules [Disabled]
    # --disable CORE-SOUNDS-EN-GSM \
# Compile and install
RUN make \
    && make install \
    && make samples \
    && make config \
    && make install-logrotate \
    && make distclean \
    && rm -rf /usr/local/src/asterisk*

# Donwload and unzip sound in spanish language
RUN mkdir /var/lib/asterisk/sounds/es \
    && cd $_ \
    && wget -O core.zip https://www.asterisksounds.org/es-es/download/asterisk-sounds-core-es-ES-sln16.zip \
    && wget -O extra.zip https://www.asterisksounds.org/es-es/download/asterisk-sounds-extra-es-ES-sln16.zip \
    && unzip core.zip \
    && unzip extra.zip \
    && rm -rf *.zip