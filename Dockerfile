FROM golang:latest
MAINTAINER Andreas Linz <klingt.net@gmail.com>

# install non-go dependencies
RUN apt-get update &&\
    apt-get -y install\
        locales\
        openssh-server\
        git\
        sqlite3\
        bsdtar\
        unzip &&\
    rm -rf /var/lib/apt/lists/*

RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen &&\
    dpkg-reconfigure locales -f noninteractive &&\
    update-locale LANG='en_US.UTF-8'

ENV LANG 'en_US.UTF-8'

# create gogs user
# note: the gogs user must have a login shell, setting it to /usr/bin/nologin or /bin/false will make you unable to push over ssh!
RUN useradd --system --create-home --comment 'gogs - go git service' --shell $(which git-shell) gogs

# get the latest linux build (sqlite is not supported in the `go get` version)
RUN curl -Ls 'https://github.com/gogits/gogs/releases/download/v0.6.5/linux_amd64.zip' | bsdtar -C /opt -xzf - &&\
    mkdir /opt/gogs/custom &&\
    mkdir /opt/gogs/log &&\
    find /opt/gogs -type d -exec chmod 755 {} \; &&\
    chown -R gogs:gogs /opt/gogs &&\
    chmod u+x /opt/gogs/gogs

# HTTP
EXPOSE 3000
# SSH
EXPOSE 22

# gogs reads USER or USERNAME to determine the run user
ENV USER gogs

# shell expansion does not work, g.e. like /opt/gogs/{custom,log}
# create the mountable folders before you declare them with the VOLUME statement, otherwise they will be created automatically as root user
VOLUME /home/gogs
VOLUME /etc/ssh
VOLUME /opt/gogs/custom
VOLUME /opt/gogs/log

WORKDIR /opt/gogs

ENV GOGS_TIMEZONE "Europe/Berlin"

CMD echo ${GOGS_TIMEZONE} > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata &&\
    service ssh start &&\
    su -s /bin/sh -c '/opt/gogs/gogs web' gogs
