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
   && echo "deb http://security.ubuntu.com/ubuntu xenial-security main universe\n" >> /etc/apt/sources.list \
   && echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list \
   && echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list

# Install JAVA8
RUN apt-get -q update                                                                      \
 && apt-get --allow-unauthenticated -y -qq upgrade                                                     \
 && echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections  \
 && apt-get --allow-unauthenticated -y -q install oracle-java8-installer                               \
 && apt-get clean

# Patch rootfs
COPY ./overlay/ /

#  No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
     DEBCONF_NONINTERACTIVE_SEEN=true

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
  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-8-oracle/jre/lib/security/java.security

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
RUN adduser seluser sudo

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
     
#========================
# Selenium Configuration
#========================

EXPOSE 4444

# As integer, maps to "maxSession"
# ENV GRID_MAX_SESSION 5
# In milliseconds, maps to "newSessionWaitTimeout"
# ENV GRID_NEW_SESSION_WAIT_TIMEOUT -1
# As a boolean, maps to "throwOnCapabilityNotPresent"
# ENV GRID_THROW_ON_CAPABILITY_NOT_PRESENT true
# As an integer
# ENV GRID_JETTY_MAX_THREADS -1
# In milliseconds, maps to "cleanUpCycle"
# ENV GRID_CLEAN_UP_CYCLE 5000
# In seconds, maps to "browserTimeout"
# ENV GRID_BROWSER_TIMEOUT 0
# In seconds, maps to "timeout"
# ENV GRID_TIMEOUT 30
# Debug
# ENV GRID_DEBUG false

#=======================================
# Copy dependancies and run config script
#========================================
RUN sudo mkdir -p /opt/bin \
   && sudo chown seluser:seluser /opt/bin

COPY generate_config \
    entry_point.sh \
    /opt/bin/
    
RUN chmod +x /opt/bin/generate_config
RUN chmod +x /opt/bin/entry_point.sh

# Running this command as sudo just to avoid the message:
# To run a command as administrator (user "root"), use "sudo <command>". See "man sudo_root" for details.
# When logging into the container
# RUN sudo /opt/bin/generate_config > /opt/selenium/config.json

CMD ["/bin/sh", "/opt/bin/entry_point.sh"]

# Clean rootfs from image-builder
RUN /usr/local/sbin/scw-builder-leave

