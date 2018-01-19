FROM alpine:latest

ARG	MINEMELD_CORE_VERSION=0.9.44.post1
ARG	MINEMELD_UI_VERSION=0.9.44

RUN	echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories &&\
	echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories &&\
	echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories &&\
	apk --no-cache add apk-tools@edge &&\
	apk --no-cache upgrade &&\
	apk --no-cache add c-ares ca-certificates collectd collectd-rrdtool collectd-utils curl cython erlang-asn1 erlang-public-key file leveldb libffi librrd libssl1.0 libxml2 libxslt libressl p7zip py-libxml2 py2-mock py2-openssl py2-pip py2-psutil py2-sphinx py2-netaddr py2-redis py2-netaddr py2-tz py2-certifi py2-click py2-gevent py2-dateutil py2-lxml py2-greenlet py2-urllib3 py2-lz4 py2-yaml python2 rabbitmq-server redis snappy su-exec supervisor tzdata &&\
	apk --no-cache add -t DEV c-ares-dev cython-dev g++ gcc gdnsd-dev git leveldb-dev libffi-dev libxml2-dev libxslt-dev musl-dev libressl-dev snappy-dev &&\
# Create minemeld user
	adduser minemeld -s /bin/false -D &&\
# Create needed directories and files
	mkdir -p /etc/minemeld/api /etc/minemeld/certs /etc/minemeld/engine /etc/minemeld/trace /etc/minemeld/library/local /etc/minemeld/supervisor/conf.d/ /var/lib/rabbitmq /var/log/rabbitmq /usr/lib/rabbitmq /data/log /var/run/minemeld /opt/minemeld/www /opt/minemeld/www/venv /opt/minemeld/www/webui /opt/minemeld/engine/current /opt/minemeld/local/prototypes /opt/minemeld/prototypes /opt/minemeld/local /opt/minemeld/local/data /opt/minemeld/local/config /opt/minemeld/local/trace /opt/minemeld/local/library /opt/minemeld/local/certs /opt/minemeld/local/certs/site /opt/minemeld/supervisor /opt/minemeld/engine  &&\
   	cd /tmp &&\
	curl -sSL https://github.com/PaloAltoNetworks/minemeld-core/archive/${MINEMELD_CORE_VERSION}.tar.gz | tar xzf - &&\
	cd minemeld-core-${MINEMELD_CORE_VERSION} &&\
	echo "Use native Alpine python packages" &&\
	sed -i 's/gevent==1.0.2/gevent/g' requirements.txt &&\
	sed -i 's/netaddr==0.7.18/netaddr/g' requirements.txt &&\
	sed -i 's/click==4.1/click/g' requirements.txt &&\
	sed -i 's/greenlet==0.4.7/greenlet/g' requirements.txt &&\
	sed -i 's/lz4==0.8.2/lz4/g' requirements.txt &&\
	sed -i 's/pytz==2015.4/pytz/g' requirements.txt &&\
	sed -i 's/PyYAML==3.11/PyYAML/g' requirements.txt &&\
	sed -i 's/redis==2.10.5/redis/g' requirements.txt &&\
# Install engine
	python setup.py install &&\
# Create config file
	touch /etc/minemeld/certs/cacert-merge-config.yml &&\
# Create CA bundle
#	mm-cacert-merge --config {{certs_directory}}/cacert-merge-config.yml --dst {{certs_directory}}/bundle.crt {{local_ca_directory}} &&\
# Cleanup
	rm -rf /tmp/* &&\
	apk --no-cache del --purge DEV &&\
	echo 'MINEMELD CORE [DONE]'

RUN apk --no-cache add git &&\
	cd /tmp &&\
# Get Minemeld prototypes
	git clone https://github.com/PaloAltoNetworks/minemeld-node-prototypes.git &&\
	mv minemeld-node-prototypes/prototypes /etc/minemeld/engine/ &&\
# Get ancilliary files as per minemeld-ansible repo
	git clone https://github.com/PaloAltoNetworks/minemeld-ansible.git &&\
	mv minemeld-ansible/roles/minemeld/templates/minemeld_types.db.j2 /usr/share/minemeld_types.db &&\
	mv minemeld-ansible/roles/minemeld/files/committed-config.yml /etc/minemeld/engine/ &&\
	mv minemeld-ansible/roles/minemeld/files/traced.yml /etc/minemeld/trace/ &&\
	mv minemeld-ansible/roles/minemeld/files/minemeld.cer /etc/minemeld/certs/ &&\
	mv minemeld-ansible/roles/minemeld/files/minemeld.pem /etc/minemeld/certs/ &&\
	mv minemeld-ansible/roles/minemeld/files/wsgi.htpasswd /etc/minemeld/api/ &&\
	touch /etc/minemeld/api/feeds.htpasswd &&\
	cd minemeld-ansible/roles/minemeld/templates &&\
# Config CollectD to output logs to emit warnings STDOUT
	sed 's/"\/var\/log\/collectd.log"/STDOUT/' collectd.centos7.conf.j2 | sed 's/info/notice/' | sed 's/Timestamp true/Timestamp false/' >/etc/collectd/collectd.conf &&\
# Unholy template replacement
# Web UI stuff
	sed 's/{{prototypes_local_directory}}:{{prototypes_repo_directory}}\/current\/\/etc\/minemeld\/prototypes/' 10-defaults.yml.j2 | sed 's/{{main_directory}}/\/data/'| sed 's/{{venv_directory}}\/bin\///g'| sed 's/\/usr\/bin\///' > /etc/minemeld/api/10-defaults.yml &&\
# Supervisord
# Rationalise file location for supervisor removing the superfluous "config" directory
	sed 's/{{main_directory}}/\/data/g' supervisord.conf.j2  | sed 's/{{supervisor_directory}}\/config/\/etc\/minemeld\/supervisor/g' > /etc/minemeld/supervisor/supervisord.conf &&\
# Listener
	sed 's/command=.*/command=mm-supervisord-listener/' minemeld-supervisord-listener.supervisord.j2 | sed 's/stderr_logfile=.*/stderr_logfile=\/data\/log\/supervisord-listener.log/' | sed '2ienvironment=HOME=/home/minemeld' | sed '3ipriority=10' >/etc/minemeld/supervisor/conf.d/supervisord-listener.conf &&\
# Traced
	sed 's/environment=.*/environment=HOME=\/home\/minemeld/' minemeld-traced.supervisord.j2 | sed 's/command=.*/command=mm-traced \/etc\/minemeld\/trace\/traced.yml/' | sed 's/directory=.*/directory=\/data/' | sed 's/stdout_logfile=.*/stdout_logfile=\/data\/log\/traced.log/' | sed '3ipriority=100' | sed '4istartsecs=15' >/etc/minemeld/supervisor/conf.d/traced.conf &&\
# Engine
	sed 's/environment=.*/environment=HOME=\/home\/minemeld,MINEMELD_PROTOTYPE_PATH=\/etc\/minemeld\/engine\/prototypes/' minemeld-engine.supervisord.j2 | sed 's/command=.*/command=mm-run \/etc\/minemeld\/engine/' | sed 's/directory=.*/directory=\/data/' |sed 's/stdout_logfile=.*/stdout_logfile=\/data\/log\/engine.log/'| sed '3ipriority=900' >/etc/minemeld/supervisor/conf.d/engine.conf &&\
# Web
	sed 's/environment=.*/environment=HOME=\/home\/minemeld,MM_CONFIG=\/etc\/minemeld,MINEMELD_PROTOTYPE_PATH=\/etc\/minemeld\/engine\/prototypes,MINEMELD_LOCAL_LIBRARY_PATH=\/etc\/minemeld\/library/' minemeld-web.supervisord.j2 | sed 's/{{venv_directory}}\/bin\///' | sed 's/directory=.*/directory=\/data/' | sed 's/stdout_logfile=.*/stdout_logfile=\/data\/log\/web.log/' >/etc/minemeld/supervisor/conf.d/web.conf &&\
# Cleanup
	apk --no-cache del --purge git &&\
    rm -rf /tmp/* &&\
	echo 'ANSIBLE FILES [DONE]'

RUN mkdir -p /var/www/webui &&\
	curl -sSL https://github.com/PaloAltoNetworks/minemeld-webui/archive/${MINEMELD_UI_VERSION}.tar.gz | tar xzf - -C /tmp &&\
	mv /tmp/minemeld-webui-${MINEMELD_UI_VERSION}/src/* /var/www/webui/ &&\
	mm-extensions-freeze /etc/minemeld/library/ /etc/minemeld/library/freeze.txt &&\
	pip freeze | grep -v minemeld-core >/etc/minemeld/library/constraints.txt &&\
# Add webservers
	apk --no-cache add py2-gunicorn py2-flask py-flask-passlib py2-flask-login py-rrd &&\
# Cleanup
    rm -rf /tmp/* &&\
	echo 'MINEMELD WEB UI [DONE]'

# Add CA bundle
COPY bundle.crt /etc/minemeld/certs/
# Apply correct ownership
RUN	chown -R minemeld: /etc/minemeld /data /var/run/minemeld &&\
	chown -R rabbitmq: /var/lib/rabbitmq /var/log/rabbitmq /usr/lib/rabbitmq &&\
	echo 'PERMISSIONS FIX [DONE]'

ARG	CONTAINERPILOT_VERSION=3.6.2
RUN	apk --no-cache add attr &&\
	curl -sSL https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VERSION}/containerpilot-${CONTAINERPILOT_VERSION}.tar.gz | tar xzf - -C /usr/local/bin &&\
# Create healthcheck scripts for Containerpilot
	echo -e "#!/bin/sh\nredis-cli ping >/dev/null 2>&1" >/usr/local/bin/redis-healthcheck &&\
	echo -e "#!/bin/sh\nrabbitmqctl node_health_check >/dev/null 2>&1" >/usr/local/bin/rabbitmq-healthcheck &&\
	echo -e "#!/bin/sh\ncollectdctl -s \$(awk '/SocketFile/{ print substr(\$2,2,length(\$2)-2) }' /etc/collectd/collectd.conf) listval >/dev/null 2>&1" >/usr/local/bin/collectd-healthcheck &&\
	echo -e "#!/bin/sh\nsetfattr -n user.pax.flags -v E $(which python) /usr/lib/libffi.so.6.0.4" >/usr/local/bin/prestart.sh &&\
	chmod +x /usr/local/bin/* &&\
	echo 'CONTAINERPILOT [DONE]'

# Add Redis configuration files
COPY redis.conf /etc/
# Add Containerpilot config file
COPY containerpilot-minemeld.json5 /etc/

#ENTRYPOINT ["containerpilot", "-config", "/etc/containerpilot-minemeld.json5"]
