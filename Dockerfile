## -*- docker-image-name: "scaleway/java:latest" -*-
FROM scaleway/ubuntu:amd64-xenial
# following 'FROM' lines are used dynamically thanks do the image-builder
# which dynamically update the Dockerfile if needed.
#FROM scaleway/ubuntu:armhf-xenial       # arch=armv7l
#FROM scaleway/ubuntu:arm64-xenial       # arch=arm64
#FROM scaleway/ubuntu:i386-xenial        # arch=i386
#FROM scaleway/ubuntu:mips-xenial        # arch=mips

MAINTAINER Scaleway <opensource@scaleway.com> (@scaleway)

# Prepare rootfs for image-builder
RUN /usr/local/sbin/scw-builder-enter

# ================================================
#  Customize sources for apt-get
# ================================================
RUN  echo "deb http://archive.ubuntu.com/ubuntu xenial main universe\n" > /etc/apt/sources.list \
   && echo "deb http://archive.ubuntu.com/ubuntu xenial-updates main universe\n" >> /etc/apt/sources.list \
   && echo "deb http://security.ubuntu.com/ubuntu xenial-security main universe\n" >> /etc/apt/sources.list

#  No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
     DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt-get -qqy install software-properties-common python-software-properties python3-software-properties

# Install JAVA8
RUN echo | add-apt-repository ppa:webupd8team/java                                         \
 && apt-get -q update                                                                      \
 && apt-get -y -qq upgrade                                                     \
 && echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections  \
 && apt-get -y -q install oracle-java8-installer                               \
 && apt-get clean

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
RUN apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install \
    bzip2 \
    ca-certificates \
    tzdata \
    sudo \
    unzip \
    wget \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security

#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ "UTC"
RUN echo "${TZ}" > /etc/timezone \
   && dpkg-reconfigure --frontend noninteractive tzdata

#========================================
# Add normal user with passwordless sudo
#========================================
RUN useradd seluser \
          --shell /bin/bash  \
          --create-home \
   && usermod -a -G sudo seluser \
   && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
   && echo 'seluser:secret' | chpasswd

#===================================================
# Run the following commands as non-privileged user
#===================================================
USER seluser

#==========
# Selenium
#==========
RUN  sudo mkdir -p /opt/selenium \
   && sudo chown seluser:seluser /opt/selenium \
   && wget --no-verbose https://selenium-release.storage.googleapis.com/3.4/selenium-server-standalone-3.4.0.jar \
     -O /opt/selenium/selenium-server-standalone.jar

# Patch rootfs
COPY ./overlay/ /

# Clean rootfs from image-builder
RUN /usr/local/sbin/scw-builder-leave
