FROM golang as supervisorgo
MAINTAINER brian.wilkinson@1and1.co.uk
WORKDIR /go/src/github.com/1and1internet/supervisorgo
RUN git clone https://github.com/1and1internet/supervisorgo.git . \
	&& go build -o release/supervisorgo \
	&& echo "supervisorgo successfully built"

FROM golang as configurability
MAINTAINER brian.wilkinson@1and1.co.uk
WORKDIR /go/src/github.com/1and1internet/configurability
RUN git clone https://github.com/1and1internet/configurability.git . \
	&& make main \
	&& echo "configurator successfully built"

FROM ubuntu:bionic
MAINTAINER brian.wilkinson@1and1.co.uk
ARG DEBIAN_FRONTEND=noninteractive
COPY files/ /
COPY --from=supervisorgo /go/src/github.com/1and1internet/supervisorgo/release/supervisorgo /usr/bin/supervisorgo
COPY --from=configurability /go/src/github.com/1and1internet/configurability/bin/configurator /usr/bin/configurator
RUN \
	update-alternatives --install /usr/bin/supervisord supervisord /usr/bin/supervisorgo 1 && \
  apt-get -y update && apt-get -y upgrade && \
  apt-get -o Dpkg::Options::=--force-confdef -y install curl netcat wget telnet vim bzip2 ssmtp locales && \
  locale-gen en_GB.utf8 en_US.utf8 es_ES.utf8 de_DE.UTF-8 && \
  mkdir --mode 777 -p /var/log/supervisor && \
  chmod -R 777 /var/run /etc/ssmtp /etc/passwd /etc/group && \
  mkdir --mode 777 -p /tmp/sockets && \
  chmod -R 755 /init /hooks && \
  apt-get remove -y binutils* build-essential bzip2 cpp* dbus dirmngr fakeroot \
  				 file g++* gcc-7* gnupg* gpg-* krb5-locales libalgorithm* && \
  apt-get -y clean && \
  rm -rf /var/lib/apt/lists/* && \
  sed -i '/^root.*/d' /etc/shadow
ENV \
  SUPERVISORD_EXIT_ON_FATAL=1 \
  LC_ALL=en_GB.UTF-8 \
  LANG=en_GB.UTF-8 \
  LANGUAGE=en_GB.UTF-8 \
  SMTP_USER="" \
  SMTP_PASS="" \
  SMTP_DOMAIN="" \
  SMTP_RELAYHOST=""
ENTRYPOINT ["/bin/bash", "-e", "/init/entrypoint"]
CMD ["/init/supervisord"]
