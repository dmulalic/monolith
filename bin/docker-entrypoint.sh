#!/bin/bash -e

if [ -f "/opt/tomcat/ssl/tomcat-users.xml" ]; then
    echo "Passwords found - running with basic auth"
    cp /opt/tomcat/conf/web.xml.password /opt/tomcat/conf/web.xml
    exec catalina.sh run
else
    echo "SSL Keys not found - running in none secure mode"
    cp /opt/tomcat/conf/web.xml.nonsecure /opt/tomcat/conf/web.xml
    exec catalina.sh run
fi
