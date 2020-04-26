FROM mmuellerm/openkm-debian:v6.3.9

ONBUILD ARG PG_USERNAME=openkm
ONBUILD ARG PG_PASSWORD="*secret*"
ONBUILD ARG PG_HOST=postgresql

ONBUILD RUN sed -i 's|hibernate.dialect=org.hibernate.dialect.HSQLDialect|hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect|' $TOMCAT_HOME/OpenKM.cfg
ONBUILD RUN sed -i 's|maxActive="100" maxIdle="30" maxWait="10000" validationQuery="select 1 from INFORMATION_SCHEMA.SYSTEM_USERS"|maxActive="100" maxIdle="30" maxWait="10000" validationQuery="select 1"|' $TOMCAT_HOME/conf/server.xml
ONBUILD RUN sed -i 's|username="sa" password="" driverClassName="org.hsqldb.jdbcDriver"|username="'${PG_USERNAME}'" password="'${PG_PASSWORD}'" driverClassName="org.postgresql.Driver"|' $TOMCAT_HOME/conf/server.xml
ONBUILD RUN sed -i 's|url="jdbc:hsqldb:\${catalina.base}/repository/okmdb"/>|url="jdbc:postgresql://'${PG_HOST}':5432/okmdb"/>|' $TOMCAT_HOME/conf/server.xml

EXPOSE 8080

CMD $TOMCAT_HOME/bin/catalina.sh run
