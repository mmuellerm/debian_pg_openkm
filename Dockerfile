FROM debian:bullseye

LABEL org.opencontainers.image.authors="Matthias Mueller m-mueller-minden at t-online dot de"

RUN apt-get update && apt-get install -y libapt-pkg-perl perl-modules-5.32 dialog bash && apt-get upgrade -y && \
    sed -i '/#session[[:space:]]*required[[:space:]]*pam_limits.so/s/^#//;' /etc/pam.d/su && \
    sed -i '/# End of file/d' /etc/security/limits.conf && \
    echo "*   soft  nofile   6084" >> /etc/security/limits.conf && \
    echo "*   hard  nofile   6084" >> /etc/security/limits.conf && \
    echo "# End of file" >> /etc/security/limits.conf && \
    apt-get clean && \
    apt-get update

RUN apt-get install -y build-essential \
                       libreoffice \
                       imagemagick \
                       liblog4j1.2-java \
                       binutils \
                       zlib1g-dev \
                       libjpeg62-turbo-dev \
                       libfreetype6-dev \
                       libgif-dev \
                       ant \
                       unzip \
                       sudo \
                       tar \
                       gzip \
                       tesseract-ocr \
                       tesseract-ocr-eng \
                       tesseract-ocr-deu \
                       patch && \
    apt-get clean && \
    /usr/sbin/update-ca-certificates --verbose --fresh && \
    sed -i 's|<policy domain="coder" rights="none" pattern="PDF" />|<policy domain="coder" rights="read\|write" pattern="PDF" />|' /etc/ImageMagick-6/policy.xml

# In the previous versions I used the JDK from Oracle. But now I am not able to do a download of actual JDK version 8 without an Oracle account.
ADD https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u362-b09/OpenJDK8U-jdk_x64_linux_hotspot_8u362b09.tar.gz /usr/lib/jvm/OpenJDK8U-jdk_x64_linux_hotspot_8u362b09.tar.gz
ADD http://www.swftools.org/swftools-0.9.2.tar.gz /usr/local/swftools-0.9.2.tar.gz
ADD http://aur.archlinux.org/cgit/aur.git/snapshot/swftools.tar.gz /usr/local/swftools-0.9.2/swftools.tar.gz
ADD extern.patch /usr/local/extern.patch
ADD https://sourceforge.net/projects/openkm/files/6.3.2/openkm-6.3.2-community-tomcat-bundle.zip/download /usr/local/openkm-tomcat-bundle.zip
ADD https://sourceforge.net/projects/openkm/files/6.3.12/OpenKM-6.3.12.zip/download /tmp/openkm-6.3.12.zip

RUN tar zxvf /usr/lib/jvm/OpenJDK8U-jdk_x64_linux_hotspot_8u362b09.tar.gz --directory /usr/lib/jvm && rm /usr/lib/jvm/OpenJDK8U-jdk_x64_linux_hotspot_8u362b09.tar.gz && \
    unlink /etc/alternatives/java && ln -s /usr/lib/jvm/jdk8u362-b09/bin/java /etc/alternatives/java && \
    tar --directory /usr/local --ungzip -xf /usr/local/swftools-0.9.2.tar.gz && rm /usr/local/swftools-0.9.2.tar.gz && \
    tar --directory /usr/local/swftools-0.9.2 --ungzip -xf /usr/local/swftools-0.9.2/swftools.tar.gz && \
    rm /usr/local/swftools-0.9.2/swftools.tar.gz && cp /usr/local/swftools-0.9.2/swftools/giflib-5.1.patch /usr/local/swftools-0.9.2/giflib-5.1.patch && cp /usr/local/swftools-0.9.2/swftools/swftools-0.9.2.patch /usr/local/swftools-0.9.2/swftools-0.9.2.patch && \
    mv /usr/local/extern.patch /usr/local/swftools-0.9.2/extern.patch && \
    mv /usr/local/swftools-0.9.2/swfs/Makefile.in /usr/local/swftools-0.9.2/swfs/Makefile && cd /usr/local/swftools-0.9.2 && patch -Np0 -i giflib-5.1.patch && patch -Np0 -i swftools-0.9.2.patch && patch -Np0 -i extern.patch && \
    mv swfs/Makefile swfs/Makefile.in && ./configure && make && make install && cd / && rm -r /usr/local/swftools-0.9.2

ENV PATH="$PATH:/usr/lib/jvm/jdk8u362-b09/bin"
ENV CATALINA_HOME=/usr/local/tomcat
ENV JAVA_HOME=/usr/local/java
ENV OPENJDK_HOME=/usr/lib/jvm/jdk8u362-b09/
ENV TOMCAT_HOME="$CATALINA_HOME"

RUN ln -s $OPENJDK_HOME $JAVA_HOME && \
    unzip /usr/local/openkm-tomcat-bundle.zip -d /usr/local/ && rm /usr/local/openkm-tomcat-bundle.zip && ln -s $CATALINA_HOME /opt/openkm && \
    unzip /tmp/openkm-6.3.12.zip -d /tmp/ && mv /tmp/OpenKM.war $TOMCAT_HOME/webapps/ && rm /tmp/openkm-6.3.12.zip /tmp/md5sum.txt && \
    sed -i 's|http://www.springframework.org/schema/security/spring-security-3.1.xsd|http://www.springframework.org/schema/security/spring-security-3.2.xsd|' $TOMCAT_HOME/OpenKM.xml && \
    mkdir $TOMCAT_HOME/repository

ONBUILD ARG PG_USERNAME=openkm
ONBUILD ARG PG_PASSWORD="*secret*"
ONBUILD ARG PG_HOST=postgresql

ONBUILD RUN sed -i 's|hibernate.dialect=org.hibernate.dialect.HSQLDialect|hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect|' $TOMCAT_HOME/OpenKM.cfg
ONBUILD RUN sed -i 's|maxActive="100" maxIdle="30" maxWait="10000" validationQuery="select 1 from INFORMATION_SCHEMA.SYSTEM_USERS"|maxActive="100" maxIdle="30" maxWait="10000" validationQuery="select 1"|' $TOMCAT_HOME/conf/server.xml
ONBUILD RUN sed -i 's|username="sa" password="" driverClassName="org.hsqldb.jdbcDriver"|username="'${PG_USERNAME}'" password="'${PG_PASSWORD}'" driverClassName="org.postgresql.Driver"|' $TOMCAT_HOME/conf/server.xml
ONBUILD RUN sed -i 's|url="jdbc:hsqldb:\${catalina.base}/repository/okmdb"/>|url="jdbc:postgresql://'${PG_HOST}':5432/okmdb"/>|' $TOMCAT_HOME/conf/server.xml

EXPOSE 8080

VOLUME /opt/openkm/repository

ENV PATH $PATH:$CATALINA_HOME/bin

CMD $TOMCAT_HOME/bin/catalina.sh run
