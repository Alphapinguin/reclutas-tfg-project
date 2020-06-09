FROM debian:bullseye
LABEL maintainer="juanantoniomtzfns@gmail.com"
# Disable interaction in commands
ENV DEBIAN_FRONTEND noninteractive
# Update packages and distro, remove unnecessary dependencies
RUN apt-get update -qq\
    && apt-get -qq install \
    wget \
    nano \
    unzip \
    unixodbc \
    unixodbc-dev \
    python-dev \
    python3-pip \
    python3-mysqldb \
    mariadb-server \
    mariadb-client \
    && apt-get autoremove -qq
# Download and unzip asterisk's source code
WORKDIR /usr/local/src/
RUN wget http://downloads.asterisk.org/pub/telephony/certified-asterisk/asterisk-certified-16.8-current.tar.gz \
    && tar zxf asterisk-certified-16.8-current.tar.gz
# Install dependencies and check prerequisites
WORKDIR /usr/local/src/asterisk-certified-16.8-cert2
RUN echo yes | ./contrib/scripts/install_prereq install \
    && ./configure \
    --without-dahdi \
    --without-pri \
    --without-radius
# Select modules
RUN make menuselect.makeopts \
    && menuselect/menuselect \
    # Asterisk modules [Enabled]
    --enable res_config_mysql
# Compile and install
RUN make \
    && make install \
    && make samples \
    && make config \
    && make install-logrotate
# Download and unzip sounds in spanish language
RUN mkdir /var/lib/asterisk/sounds/es
WORKDIR /var/lib/asterisk/sounds/es/
RUN wget https://www.asterisksounds.org/es-es/download/asterisk-sounds-core-es-ES-sln16.zip \
    && wget https://www.asterisksounds.org/es-es/download/asterisk-sounds-extra-es-ES-sln16.zip \
    && unzip -o asterisk-sounds-core-es-ES-sln16.zip \
    && unzip -o asterisk-sounds-extra-es-ES-sln16.zip 
# Download and install library for MySQL connector
WORKDIR /usr/local/src/
RUN wget https://dev.mysql.com/get/Downloads/Connector-ODBC/8.0/mysql-connector-odbc-8.0.19-linux-ubuntu19.10-x86-64bit.tar.gz \
    && tar xzf mysql-connector-odbc-8.0.19-linux-ubuntu19.10-x86-64bit.tar.gz \
    && cp mysql-connector-odbc-8.0.19-linux-ubuntu19.10-x86-64bit/lib/libmyodbc8a.so /usr/lib/x86_64-linux-gnu/odbc/
# MariaDB start and DB creation
RUN /etc/init.d/mysql start \
    && mysqladmin -u root create asterisk
# Installing and using Alembic
RUN pip install alembic
WORKDIR /usr/local/src/asterisk-certified-16.8-cert2/contrib/ast-db-manage/
COPY path_contrib/* /usr/local/src/asterisk-certified-16.8-cert2/contrib/ast-db-manage/
RUN /etc/init.d/mysql start \
    && alembic -c config.ini upgrade head
# Open necessary ports for Asterisk
EXPOSE 5060/udp
EXPOSE 10000-10003
# Place custom configurations
WORKDIR /
COPY path_asterisk/* /etc/asterisk/
COPY path_etc/* /etc/
COPY path_usr/* /usr/local/src/
# Remove unnecessary files
RUN rm -rf /usr/local/src/asterisk-certified-16.8-cert2/ \
    /usr/local/src/*.tar.gz \
    /var/lib/asterisk/sounds/es/*.zip
# Run services
RUN chmod +x /usr/local/src/start_services.sh
ENTRYPOINT [ "/usr/local/src/start_services.sh" ]