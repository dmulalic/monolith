FROM quay.io/ukhomeofficedigital/docker-centos-openjdk8:latest
MAINTAINER "Mark Olliver mark@keao.cloud"
LABEL Version="0.1"
LABEL Name="tomcat"
LABEL Description="Apache Tomcat Container"


ARG TOMCAT_MAJOR=8
ARG TOMCAT_MINOR=8.0.35
ARG OPENSSL_VERSION=1.0.2h
ARG JAVA_MAJOR=1.8.0
ARG JAVA_MINOR=91-0.b14

ENV TOMCAT_MAJOR ${TOMCAT_MAJOR}
ENV TOMCAT_MINOR ${TOMCAT_MINOR}
ENV OPENSSL_VERSION ${OPENSSL_VERSION}
ENV JAVA_MAJOR ${JAVA_MAJOR}
ENV JAVA_MINOR ${JAVA_MINOR}

RUN curl -#L http://www.mirrorservice.org/sites/ftp.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_MINOR}/bin/apache-tomcat-${TOMCAT_MINOR}.tar.gz -o /tmp/apache-tomcat.tar.gz
RUN curl -#L https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -o /tmp/openssl.tar.gz

RUN tar -zxf /tmp/apache-tomcat.tar.gz -C /opt && \
    rm /tmp/apache-tomcat.tar.gz && \
    mv /opt/apache-tomcat-* /opt/tomcat

RUN yum install -y apr-devel java-${JAVA_MAJOR}-openjdk-devel && \
    yum groupinstall -y "Development Tools"

WORKDIR /tmp
RUN tar zxf openssl.tar.gz && \
    rm openssl.tar.gz && \
    mv openssl-* openssl && \
    cd openssl && \
    ./config shared && \
    make depend && \
    make install

ENV JAVA_HOME /usr/lib/jvm/java-${JAVA_MAJOR}-openjdk-${JAVA_MAJOR}.${JAVA_MINOR}.el7_2.x86_64
ENV JRE_HOME /usr/lib/jvm/java-${JAVA_MAJOR}-openjdk-${JAVA_MAJOR}.${JAVA_MINOR}.el7_2.x86_64
ENV PATH /srv/bin:/opt/tomcat/bin:/usr/lib/jvm/jre-${JAVA_MAJOR}-openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV CATALINA_HOME /opt/tomcat
WORKDIR /opt/tomcat
 
RUN mkdir -p /opt/tomcat-native && \
    tar -zxf bin/tomcat-native.tar.gz -C /opt/tomcat-native --strip-components=1 && \
    rm /opt/tomcat/bin/*tar.gz && \
    cd /opt/tomcat-native/native && \
    ./configure \
        --libdir=/usr/lib/ \
        --prefix="$CATALINA_HOME" \
        --with-apr=/usr/bin/apr-1-config \
        --with-java-home="$JAVA_HOME" \
        --with-ssl=yes && \
    make -j$(nproc) && \
    make install && \
    rm -rf /opt/tomcat-native /tmp/openssl
               
RUN set -e \
	if `catalina.sh configtest | grep -q 'INFO: Loaded APR based Apache Tomcat Native library'` \
        then \
	    echo "Build Passed" \
        else \
            echo "Build Failed" \
            exit 1 \
	fi

RUN yum remove -y apr-devel kernel-devel kernel-headers boost* rsync perl* && \
    rpm --nodeps -e libXfont libXau libX11 libXi libX11-common libXext libXtst libXrender xorg-x11-font-utils xorg-x11-fonts-Type1 libxcb giflib && \
    yum groupremove -y "Development Tools" && \
    yum clean all

RUN mkdir -p /opt/tomcat/ssl /opt/tomcat/users /srv/bin
COPY ssl/* /opt/tomcat/ssl/
COPY etc/* /opt/tomcat/conf/
COPY bin/* /srv/bin

EXPOSE 8080 8443

ENTRYPOINT docker-entrypoint.sh
