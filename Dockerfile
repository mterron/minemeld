FROM alpine:latest

ARG	MINEMELD_CORE_VERSION=0.9.44.post1
ARG	MINEMELD_UI_VERSION=0.9.44

RUN clear &&\
	echo -e "\n PaloAlto" &&\
	echo -e "\e[33m    /|    //||     _                    /|    //||              //      //\e[0m" &&\
	echo -e "\e[33m   //|   // ||    (_)   __     ___     //|   // ||     ___     //  ___ //\e[0m" &&\
	echo -e "\e[33m  // |  //  ||   / / //   )) //___)   // |  //  ||   //___)   // //   //\e[0m" &&\
	echo -e "\e[33m //  | //   ||  / / //   // //       //  | //   ||  //       // //   //\e[0m" &&\
	echo -e "\e[33m//   |//    || / / //   // ((____   //   |//    || ((____   // ((___//\e[0m" &&\
	echo -e "\n\n" &&\
	echo -e "CORE VERSION: $MINEMELD_CORE_VERSION\nUI VERSION: $MINEMELD_UI_VERSION" &&\
	echo -e "------------------------------------------------------------------------------" &&\
	echo -n -e "\e[1;0;32m# Create minemeld user\e[0m" &&\
    adduser minemeld -s /bin/false -D &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
    echo -n -e "\e[1;0;32m# Create minemeld directories\e[0m" &&\
    mkdir -p -m 0775 /opt/minemeld/engine /opt/minemeld/local /opt/minemeld/log /opt/minemeld/prototypes /opt/minemeld/supervisor /opt/minemeld/www /opt/minemeld/local/certs /opt/minemeld/local/config /opt/minemeld/local/data /opt/minemeld/local/library /opt/minemeld/local/prototypes /opt/minemeld/local/config/traced /opt/minemeld/local/config/api /opt/minemeld/local/trace /opt/minemeld/supervisor/config/conf.d &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
    echo -n -e "\e[1;0;32m# Install packages\e[0m" &&\
	echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories &&\
	echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories &&\
	echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories &&\
	apk -U -q add apk-tools@edge &&\
#	apk upgrade &&\
	# py-hiredis version on Alpine is very old
	apk -q --progress add c-ares ca-certificates collectd collectd-rrdtool collectd-utils curl cython erlang-asn1 erlang-public-key file leveldb libffi librrd libssl1.0 libxml2 libxslt libressl p7zip py2-decorator py-libxml2 py2-mock py2-openssl py2-pip py2-psutil py2-sphinx py2-netaddr py2-redis py2-netaddr py2-tz py2-msgpack py2-cffi py2-virtualenv py2-markupsafe py-ethtool py2-itsdangerous py2-certifi py2-click py2-gevent py2-dateutil py2-lxml py2-greenlet py2-urllib3 py2-lz4 py2-yaml py2-gunicorn py2-passlib py2-flask py-flask-passlib py2-flask-login py-rrd py2-zmq python2 rabbitmq-server redis snappy su-exec supervisor tzdata &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo -e "\e[1;0;32m# Get Minemeld prototypes\e[0m" &&\
	cd /tmp &&\
	echo "Working directory: $(pwd)" &&\
	apk -q add -t DEV git &&\
	git clone https://github.com/PaloAltoNetworks/minemeld-node-prototypes.git &&\
	mkdir -p /opt/minemeld/prototypes/"$MINEMELD_CORE_VERSION" &&\
	mv minemeld-node-prototypes/prototypes/* /opt/minemeld/prototypes/"$MINEMELD_CORE_VERSION" &&\
    ln -sn /opt/minemeld/prototypes/"$MINEMELD_CORE_VERSION" /opt/minemeld/prototypes/current &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo -n -e "\e[1;0;32m# Get Minemeld-Core\e[0m" &&\
	curl -sSL "https://github.com/PaloAltoNetworks/minemeld-core/archive/${MINEMELD_CORE_VERSION}.tar.gz" | tar xzf - -C /opt/minemeld/engine/ &&\
	cd /opt/minemeld/engine &&\
	mv "minemeld-core-$MINEMELD_CORE_VERSION"/ core &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo -n -e "\e[1;0;32m# Install dev packages\e[0m" &&\
	apk -q --progress add -t DEV c-ares-dev cython-dev g++ gcc gdnsd-dev leveldb-dev libffi-dev libxml2-dev libxslt-dev musl-dev libressl-dev snappy-dev rrdtool-dev linux-headers psutils-dev py-setuptools py-py &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo "Use Alpine's native Python packages" &&\
	sed -i 's/==/>=/g' core/requirements*.txt &&\
	echo -e "\e[1;0;32m# Create virtualenv\e[0m" &&\
	echo "Working directory: $(pwd)" &&\
	virtualenv --system-site-packages /opt/minemeld/engine/"$MINEMELD_CORE_VERSION" &&\
#	virtualenv /opt/minemeld/engine/"$MINEMELD_CORE_VERSION"  &&\
	chown -R minemeld:minemeld /opt/minemeld/engine/"$MINEMELD_CORE_VERSION" &&\
	chmod -R 0775 /opt/minemeld/engine/"$MINEMELD_CORE_VERSION" &&\
	source /opt/minemeld/engine/"$MINEMELD_CORE_VERSION"/bin/activate &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo -e "\e[1;0;32m# Install requirements\e[0m" &&\
	pip -q install -r /opt/minemeld/engine/core/requirements.txt &&\
	echo -e "\e[1;0;32m Install requirements [✔ ]\e[0m" &&\
	echo -e "\e[1;0;32m# Install web requirements\e[0m" &&\
	pip -q install -r /opt/minemeld/engine/core/requirements-web.txt &&\
	echo -e "\e[1;0;32m Install web requirements [✔ ]\e[0m" &&\
	echo -e "\e[1;0;32m# Install dev requirements\e[0m" &&\
	pip -q install -r /opt/minemeld/engine/core/requirements-dev.txt &&\
	deactivate &&\
	echo -e "\e[1;0;32m Install dev requirements [✔ ]\e[0m\n\n" &&\
	echo -e "\e[1;0;32m# Install engine\e[0m" &&\
	pip -q install -e /opt/minemeld/engine/core &&\
    ln -sn /opt/minemeld/engine/"$MINEMELD_CORE_VERSION" /opt/minemeld/engine/current &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	rm -rf /tmp/* /var/cache/apk/* &&\
	export PATH=$PATH:/opt/minemeld/engine/current/bin &&\
	source /opt/minemeld/engine/"$MINEMELD_CORE_VERSION"/bin/activate &&\
	echo -e -n "\e[1;0;32m# Create extensions frigidaire\e[0m" &&\
	mm-extensions-freeze /opt/minemeld/local/library /opt/minemeld/local/library/freeze.txt &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo -n -e "\e[1;0;32m# Create constraints file\e[0m" &&\
	cd /opt/minemeld/engine/"$MINEMELD_CORE_VERSION" &&\
	/opt/minemeld/engine/"$MINEMELD_CORE_VERSION"/bin/pip freeze /opt/minemeld/engine/core | grep -v minemeld-core > /opt/minemeld/local/library/constraints.txt &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
# Cleanup
	apk -q del --purge DEV &&\
	echo -n -e "\e[1;0;32m# Create CA config file\e[0m" &&\
	echo "# no_merge_certifi: true" >/opt/minemeld/local/certs/cacert-merge-config.yml &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	#echo -n -e "\e[1;0;32m# Create CA bundle\e[0m" &&\
	#mm-cacert-merge --config /opt/minemeld/local/certs/cacert-merge-config.yml --dst /opt/minemeld/local/certs/bundle.crt /opt/minemeld/local/certs/site/ &&\
	#echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo -e "\e[1;0;32mMINEMELD CORE [✔ ✔ ]\e[0m" &&\
	echo -e "------------------------------------------------------------------------------" &&\
#########################################################################################
# MISCELANEOUS FILES
#########################################################################################
	echo -e "\e[1;0;32m# Obtain misc files from minemeld-ansible git repo\e[0m" &&\
	apk --no-cache -q add git &&\
	cd /tmp &&\
	git clone https://github.com/PaloAltoNetworks/minemeld-ansible.git &&\
	mv minemeld-ansible/roles/minemeld/templates/minemeld_types.db.j2 /usr/share/minemeld_types.db &&\
	mv minemeld-ansible/roles/minemeld/files/traced.yml /opt/minemeld/local/config/traced/ &&\
	mv minemeld-ansible/roles/minemeld/files/wsgi.htpasswd /opt/minemeld/local/config/api/ &&\
	mv minemeld-ansible/roles/minemeld/files/committed-config.yml /opt/minemeld/local/config/ &&\
#	touch /opt/minemeld/local/config/api/feeds.htpasswd &&\
	cd minemeld-ansible/roles/minemeld/templates &&\
	echo "Working directory: $(pwd)" &&\
# Config CollectD to output logs to emit warnings to STDOUT
	sed 's/"\/var\/log\/collectd.log"/STDOUT/' collectd.centos7.conf.j2 | sed 's/info/notice/' | sed 's/Timestamp true/Timestamp false/' >/etc/collectd/collectd.conf &&\
# Unholy template replacement to remain close to PaloAlto Ansible repo
# General
	sed -i 's/{{ *main_directory *}}/\/opt\/minemeld/g' * &&\
	sed -i 's/{{supervisor_directory}}/\/opt\/minemeld\/supervisor/g' * &&\
	sed -i 's/{{venv_directory}}/\/opt\/minemeld\/engine\/current/g' * &&\
	sed -i 's/{{engine_directory}}/\/opt\/minemeld\/engine/g' * &&\
	sed -i 's/{{trace_directory}}/\/opt\/minemeld\/local\/trace/g' * &&\
	sed -i 's/{{traced_config_directory}}/\/opt\/minemeld\/local\/config\/traced/g' * &&\
	sed -i 's/{{data_directory}}/\/opt\/minemeld\/local\/data/g' * &&\
	sed -i 's/{{prototypes_local_directory}}/\/opt\/minemeld\/local\/prototypes/g' * &&\
	sed -i 's/{{prototypes_repo_directory}}/\/opt\/minemeld\/prototypes/g' * &&\
	sed -i 's/{{certs_directory}}/\/opt\/minemeld\/local\/certs/g' * &&\
	sed -i 's/{{config_directory}}/\/opt\/minemeld\/local\/config/g' * &&\
# Supervisord
	mv supervisord.conf.j2 /opt/minemeld/supervisor/config/supervisord.conf &&\
#  Listener
	sed '2ienvironment=HOME=/home/minemeld' minemeld-supervisord-listener.supervisord.j2 | sed '3ipriority=10' >/opt/minemeld/supervisor/config/conf.d/supervisord-listener.conf &&\
#  Traced
	sed '3ipriority=100' minemeld-traced.supervisord.j2  | sed '4istartsecs=10' >/opt/minemeld/supervisor/config/conf.d/traced.conf &&\
#  Engine
	sed '3ipriority=900' minemeld-engine.supervisord.j2 >/opt/minemeld/supervisor/config/conf.d/engine.conf &&\
#  Web
	sed '4istartsecs=5' minemeld-web.supervisord.j2 >/opt/minemeld/supervisor/config/conf.d/web.conf &&\
# NGINX config file
	sed  's/{{www_directory}}/\/opt\/minemeld\/www/g' minemeld-web.nginx.j2 >/opt/minemeld/www/minemeld-web.nginx.conf &&\
# API Defaults
	mv 10-defaults.yml.j2 /opt/minemeld/local/config/api/ &&\
# Cleanup
#	sed -i 's/command=\/opt\/minemeld\/engine\/current\/bin\/command=//' /opt/minemeld/supervisor/config/conf.d/*.conf &&\
	sed -i 's/"//g' /opt/minemeld/supervisor/config/conf.d/*.conf &&\
	apk -q --no-cache del --purge git &&\
	rm -rf /tmp/* &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo -e "------------------------------------------------------------------------------"
##########################################################################################
# WEB UI
##########################################################################################
RUN	echo -n -e "\e[1;0;32m# Get Minemeld Web UI\e[0m" &&\
	curl -sSL "https://github.com/PaloAltoNetworks/minemeld-webui/archive/${MINEMELD_UI_VERSION}.tar.gz" | tar xzf - -C /opt/minemeld/www &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo -e "\e[1;0;32m# Install Minemeld Web UI\e[0m" &&\
	apk -q --progress --no-cache add -t DEV_WEBUI git g++ libsass libsass-dev nodejs nodejs-npm&&\
	cd /opt/minemeld/www/minemeld-webui-${MINEMELD_UI_VERSION} &&\
	echo "Working directory: $(pwd)" &&\
	echo ' * Running npm' &&\
    npm install -g &&\
    echo ' * Doing the bower thing' &&\
    bower install --allow-root &&\
    echo -n ' * Installing typings' &&\
    typings install &&\
    echo ' * Checking for vulnerabilities' &&\
    nsp check &&\
    echo ' * Running gulp' &&\
    gulp build &&\
	mkdir -p /opt/minemeld/www/"$MINEMELD_CORE_VERSION" &&\
    ln -ns /opt/minemeld/www/"$MINEMELD_CORE_VERSION"/dist /opt/minemeld/www/current &&\
	chown minemeld: /opt/minemeld/www &&\
# Cleanup
	rm -rf /tmp/* &&\
    apk -q --no-cache del --purge DEV_WEBUI &&\
	echo -e "\e[1;0;32m [✔ ✔ ]\e[0m" &&\
	echo -n -e "\e[1;0;32m# Install webapp dependencies\e[0m" &&\
	apk --no-cache -q --progress add py2-gunicorn py2-passlib py2-flask py-flask-passlib py2-flask-login py-rrd &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo -n -e "\e[1;0;32m# Install web server\e[0m" &&\
	apk -q --no-cache --progress add nginx &&\
	mkdir -p /var/run/nginx &&\
	cp /opt/minemeld/local/certs/* /etc/nginx &&\
	mv /opt/minemeld/www/minemeld-web.nginx.conf /etc/nginx/conf.d/minemeld-web &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo ' * Disable global ssl session cache'  &&\
	sed -i 's/ssl_session_cache.*//' /etc/nginx/nginx.conf &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo -e "------------------------------------------------------------------------------"

# Add CA bundle
COPY bundle.crt /opt/minemeld/local/certs/

# Apply correct ownership
RUN	echo -n -e "\e[1;0;32m# Fixing permissions\e[0m" &&\
	mkdir -m 0755 -p /var/run/minemeld/ &&\
	chown -R minemeld: /opt/minemeld /var/run/minemeld &&\
	chown -R rabbitmq: /var/lib/rabbitmq /var/log/rabbitmq /usr/lib/rabbitmq &&\
	chmod 0644 /etc/collectd/collectd.conf &&\
#	chmod 0600 /opt/minemeld/local/certs/*.pem &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo -e "------------------------------------------------------------------------------"

ARG	CONTAINERPILOT_VERSION=3.6.2
RUN	echo -n -e "\e[1;0;32m# Installing Containerpilot\e[0m" &&\
	curl -sSL "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VERSION}/containerpilot-${CONTAINERPILOT_VERSION}.tar.gz" | tar xzf - -C /usr/local/bin &&\
# Create healthcheck scripts for Containerpilot
	echo -e "#!/bin/sh\nredis-cli ping >/dev/null 2>&1" >/usr/local/bin/redis-healthcheck &&\
	echo -e "#!/bin/sh\nrabbitmqctl node_health_check >/dev/null 2>&1" >/usr/local/bin/rabbitmq-healthcheck &&\
	echo -e "#!/bin/sh\ncollectdctl -s \$(awk '/SocketFile/{ print substr(\$2,2,length(\$2)-2) }' /etc/collectd/collectd.conf) listval >/dev/null 2>&1" >/usr/local/bin/collectd-healthcheck &&\
# Create prestart script to fix GRSEC errors
	echo -e "#!/bin/sh\nsetfattr -n user.pax.flags -v E $(which python) /usr/lib/libffi.so.6.0.4" >/usr/local/bin/prestart.sh &&\
	chmod +x /usr/local/bin/* &&\
	apk -q --progress --no-cache add attr &&\
	echo -e "\e[1;0;32m [✔ ]\e[0m" &&\
	echo -e "------------------------------------------------------------------------------"

# Add Redis configuration files
COPY redis.conf /etc/
# Add Containerpilot config file
COPY minemeld.json5 /etc/

#ENTRYPOINT ["containerpilot", "-config", "/etc/minemeld.json5"]
