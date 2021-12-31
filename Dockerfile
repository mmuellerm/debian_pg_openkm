FROM debian:bullseye

LABEL maintainer="Matthias Mueller m-mueller-minden at t-online dot de"

RUN apt-get update && apt-get install -y libapt-pkg-perl perl-modules-5.32 dialog wget && apt-get upgrade -y

RUN sed -i '/#session[[:space:]]*required[[:space:]]*pam_limits.so/s/^#//;' /etc/pam.d/su && \
    sed -i '/# End of file/d' /etc/security/limits.conf && \
    echo "*   soft  nofile   6084" >> /etc/security/limits.conf && \
    echo "*   hard  nofile   6084" >> /etc/security/limits.conf && \
    echo "# End of file" >> /etc/security/limits.conf

RUN apt-get install -y build-essential \
                       bash \
                       libreoffice \
                       imagemagick \
                       liblog4j1.2-java \
                       binutils \
                       zlib1g-dev \
                       libjpeg62-turbo-dev \
                       libfreetype6-dev \
                       libgif-dev \
                       ant \
                       curl \
                       unzip \
                       sudo \
                       tar \
                       gzip \
                       tesseract-ocr \
                       tesseract-ocr-eng \
                       tesseract-ocr-deu \
                       patch && \
    apt-get clean

RUN wget -O /usr/lib/jvm/jdk-8u311-linux-x64.tar.gz -c --header "Cookie: oraclelicense=accept-securebackup-cookie" https://download.oracle.com/otn-pub/java/jdk/8u311-b11/4d5417147a92418ea8b615e228bb6935/jdk-8u311-linux-x64.tar.gz && \
    tar zxvf /usr/lib/jvm/jdk-8u311-linux-x64.tar.gz --directory /usr/lib/jvm && rm /usr/lib/jvm/jdk-8u311-linux-x64.tar.gz && \
    unlink /etc/alternatives/java && ln -s /usr/lib/jvm/jdk1.8.0_311/bin/java /etc/alternatives/java

RUN wget -O /usr/local/swftools-0.9.2.tar.gz http://www.swftools.org/swftools-0.9.2.tar.gz && tar --directory /usr/local --ungzip -xf /usr/local/swftools-0.9.2.tar.gz && rm /usr/local/swftools-0.9.2.tar.gz && \
    wget -O /usr/local/swftools-0.9.2/swftools.tar.gz http://aur.archlinux.org/cgit/aur.git/snapshot/swftools.tar.gz && tar --directory /usr/local/swftools-0.9.2 --ungzip -xf /usr/local/swftools-0.9.2/swftools.tar.gz && \
    rm /usr/local/swftools-0.9.2/swftools.tar.gz && cp /usr/local/swftools-0.9.2/swftools/giflib-5.1.patch /usr/local/swftools-0.9.2/giflib-5.1.patch && cp /usr/local/swftools-0.9.2/swftools/swftools-0.9.2.patch /usr/local/swftools-0.9.2/swftools-0.9.2.patch 

ADD extern.patch /usr/local/swftools-0.9.2/extern.patch

RUN mv /usr/local/swftools-0.9.2/swfs/Makefile.in /usr/local/swftools-0.9.2/swfs/Makefile && cd /usr/local/swftools-0.9.2 && patch -Np0 -i giflib-5.1.patch && patch -Np0 -i swftools-0.9.2.patch && patch -Np0 -i extern.patch && \
    mv swfs/Makefile swfs/Makefile.in && ./configure && make && make install && cd / && rm -r /usr/local/swftools-0.9.2

ENV PATH="$PATH:/usr/lib/jvm/jdk1.8.0_311/bin"
ENV CATALINA_HOME=/usr/local/tomcat
ENV JAVA_HOME=/usr/local/java
ENV OPENJDK_HOME=/usr/lib/jvm/jdk1.8.0_311/
ENV TOMCAT_HOME="$CATALINA_HOME"

RUN ln -s $OPENJDK_HOME $JAVA_HOME && \
    wget -O /usr/local/openkm-tomcat-bundle.zip https://sourceforge.net/projects/openkm/files/6.3.2/openkm-6.3.2-community-tomcat-bundle.zip/download && unzip /usr/local/openkm-tomcat-bundle.zip -d /usr/local/ && rm /usr/local/openkm-tomcat-bundle.zip && ln -s $CATALINA_HOME /opt/openkm && \
    wget -O /tmp/openkm-6.3.11.zip https://sourceforge.net/projects/openkm/files/6.3.11/OpenKM-6.3.11.zip/download && unzip /tmp/openkm-6.3.11.zip -d /tmp/ && mv /tmp/OpenKM.war $TOMCAT_HOME/webapps/ && rm /tmp/openkm-6.3.11.zip /tmp/md5sum.txt && \
    sed -i 's|http://www.springframework.org/schema/security/spring-security-3.1.xsd|http://www.springframework.org/schema/security/spring-security-3.2.xsd|' $TOMCAT_HOME/OpenKM.xml

ONBUILD ARG PG_USERNAME=openkm
ONBUILD ARG PG_PASSWORD="*secret*"
ONBUILD ARG PG_HOST=postgresql

ONBUILD RUN sed -i 's|hibernate.dialect=org.hibernate.dialect.HSQLDialect|hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect|' $TOMCAT_HOME/OpenKM.cfg
ONBUILD RUN sed -i 's|maxActive="100" maxIdle="30" maxWait="10000" validationQuery="select 1 from INFORMATION_SCHEMA.SYSTEM_USERS"|maxActive="100" maxIdle="30" maxWait="10000" validationQuery="select 1"|' $TOMCAT_HOME/conf/server.xml
ONBUILD RUN sed -i 's|username="sa" password="" driverClassName="org.hsqldb.jdbcDriver"|username="'${PG_USERNAME}'" password="'${PG_PASSWORD}'" driverClassName="org.postgresql.Driver"|' $TOMCAT_HOME/conf/server.xml
ONBUILD RUN sed -i 's|url="jdbc:hsqldb:\${catalina.base}/repository/okmdb"/>|url="jdbc:postgresql://'${PG_HOST}':5432/okmdb"/>|' $TOMCAT_HOME/conf/server.xml

EXPOSE 8080

ENV PATH $PATH:$CATALINA_HOME/bin

RUN mkdir $TOMCAT_HOME/repository

CMD $TOMCAT_HOME/bin/catalina.sh run
