FROM osixia/openldap:1.2.4
LABEL maintainer="none@none.com" \
      version="1.1.10-1.2-1"

ENV FUSIONDIRECTORY_VERSION=1.2-1

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys D744D55EACDA69FF \
 && (echo "deb http://repos.fusiondirectory.org/fusiondirectory-releases/fusiondirectory-1.2/debian-jessie jessie main"; \
     echo "deb http://repos.fusiondirectory.org/fusiondirectory-extra/debian-jessie jessie main") \
    > /etc/apt/sources.list.d/fusiondirectory-jessie.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    fusiondirectory-schema=${FUSIONDIRECTORY_VERSION} \
    fusiondirectory-plugin-autofs-schema=${FUSIONDIRECTORY_VERSION} \
    fusiondirectory-plugin-mail-schema=${FUSIONDIRECTORY_VERSION} \
    fusiondirectory-plugin-sudo-schema=${FUSIONDIRECTORY_VERSION} \
    fusiondirectory-plugin-systems-schema=${FUSIONDIRECTORY_VERSION} \
    fusiondirectory-plugin-webservice-schema=${FUSIONDIRECTORY_VERSION} \
    patch \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY init.sh /sbin/init.sh
COPY init.dirs /sbin/init.dirs
RUN chmod 755 /sbin/init.sh /sbin/init.dirs /container/service/slapd/startup.sh
RUN sed -i "/^FIRST_START_DONE=/aFIRST_START_DONE=/etc/ldap/slapd.d/slapd-first-start-done" /container/service/slapd/startup.sh
RUN sed -i "/# create dir if they not already exists/i/sbin/init.dirs\n" /container/service/slapd/startup.sh
# init.sh should be executed before replication starts, since init.sh assumes it is executed before that.
RUN sed -i "/# Replication config/c\    /sbin/init.sh\n" /container/service/slapd/startup.sh
RUN sed -i "s|exec /usr/sbin/slapd \(.*\)|exec /usr/sbin/slapd \1 \${LDAP_REPLICATION_COOKIE:+-c \$LDAP_REPLICATION_COOKIE}|" /container/service/slapd/process.sh
