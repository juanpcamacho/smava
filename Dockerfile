FROM alpine:latest


MAINTAINER Juan Camacho

# Java Version and other ENV
ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=192 \
    JAVA_VERSION_BUILD=12 \
    JAVA_PACKAGE=jdk \
    HOTSWAP_AGENT_VERSION=1.2.0 \
    JAVA_JCE=unlimited \
    JAVA_HOME=/opt/jdk \
    PATH=${PATH}:/opt/jdk/bin \
    GLIBC_REPO=https://github.com/sgerrand/alpine-pkg-glibc \
    GLIBC_VERSION=2.28-r0 \
    LANG=C.UTF-8

# Update the Repos and install needed info
RUN apk -U upgrade
RUN apk add libstdc++ curl ca-certificates bash

#Get the glibc libreries and install
RUN for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL ${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done
RUN apk add --allow-untrusted /tmp/*.apk

#Remove Temp files
RUN rm -v /tmp/*.apk
   
RUN ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
    mkdir /tmp/dcevm

#Download Java
RUN curl -L -o /tmp/dcevm/DCEVM-light-8u112-installer.jar "https://github.com/dcevm/dcevm/releases/download/light-jdk8u112%2B8/DCEVM-light-8u112-installer.jar" && \
    mkdir /opt && \
    curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/java.tar.gz \
      http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/750e1c8617c5452694857ad95c3ee230/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz && \
    JAVA_PACKAGE_SHA256=$(curl -sSL https://www.oracle.com/webfolder/s/digest/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}checksum.html | grep -E "${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64\.tar\.gz" | grep -Eo '(sha256: )[^<]+' | cut -d: -f2 | xargs) && \
    echo "${JAVA_PACKAGE_SHA256}  /tmp/java.tar.gz" > /tmp/java.tar.gz.sha256 && \
    sha256sum -c /tmp/java.tar.gz.sha256

#Untar files
RUN gunzip /tmp/java.tar.gz && \
    tar -C /opt -xf /tmp/java.tar

#Creation Softlink
RUN ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk

#Remove tmp files
RUN rm -rfv /tmp/*

#Get the WAR file
RUN curl -L -o /tmp/helloworld.war "http://78.137.98.23/task18/helloworld.war"

#Check Java is installer correctly
RUN /opt/jdk/bin/java -version

#Start the container with the WAR provided.
ENTRYPOINT ["/opt/jdk/bin/java", "-jar", "/tmp/helloworld.war"]
