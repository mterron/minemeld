FROM alpine:latest

ARG	MINEMELD_CORE_VERSION=0.9.62
ARG	MINEMELD_VERSION=0.9.62

RUN	clear &&\
	echo -e "\n PaloAlto" &&\
	echo -e "\e[1;33m    /|    //||     _                    /|    //||              //      //\e[0m" &&\
	echo -e "\e[1;33m   //|   // ||    (_)   __     ___     //|   // ||     ___     //  ___ //\e[0m" &&\
	echo -e "\e[1;33m  // |  //  ||   / / //   )) //___)   // |  //  ||   //___)   // //   //\e[0m" &&\
	echo -e "\e[1;33m //  | //   ||  / / //   // //       //  | //   ||  //       // //   //\e[0m" &&\
	echo -e "\e[1;33m//   |//    || / / //   // ((____   //   |//    || ((____   // ((___//\e[0m" &&\
	echo -e "\n\n" &&\
	echo -e "CORE VERSION: $MINEMELD_CORE_VERSION\nPROTOTYPES VERSION: $MINEMELD_VERSION\nUI VERSION: $MINEMELD_VERSION" &&\
	echo -e "------------------------------------------------------------------------------" &&\
	echo -e "\e[0;32mINSTALL MINEMELD ENGINE\e[0m" &&\
	echo -n -e "\e[0;32m- Create minemeld user\e[0m" &&\
	adduser minemeld -s /bin/false -D &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Create directories\e[0m" &&\
	mkdir -p -m 0775 /opt/minemeld/engine /opt/minemeld/local /opt/minemeld/log /opt/minemeld/prototypes /opt/minemeld/supervisor /opt/minemeld/www /opt/minemeld/local/certs /opt/minemeld/local/config /opt/minemeld/local/data /opt/minemeld/local/library /opt/minemeld/local/prototypes /opt/minemeld/local/config/traced /opt/minemeld/local/config/api /opt/minemeld/local/trace /opt/minemeld/supervisor/config/conf.d &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Install dependencies & Infrastructure\e[0m" &&\
	echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories &&\
	echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories &&\
	echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories &&\
	apk -q --progress add jq c-ares ca-certificates curl openssl collectd collectd-rrdtool collectd-utils cython erlang-asn1 erlang-public-key git file leveldb libffi librrd libssl1.1 libxml2 libxslt p7zip rabbitmq-server redis snappy su-exec supervisor tzdata &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Install python dependencies\e[0m" &&\
	apk -q --progress add python2 py-libxml2 py2-certifi py2-click py2-crypto py2-cryptography py2-dateutil py2-dicttoxml py2-flask py2-flask-oauthlib py2-flask-wtf py2-gevent py2-greenlet py2-gunicorn py2-lxml py2-lz4 py2-mock py2-netaddr py2-netaddr py2-openssl py2-pip py2-psutil py2-redis py2-sphinx py2-sphinx_rtd_theme py2-sphinxcontrib-websupport py2-tz py2-urllib3 py2-yaml &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Get node prototypes\e[0m" &&\
	curl -sSL "https://github.com/PaloAltoNetworks/minemeld-node-prototypes/archive/${MINEMELD_VERSION}.tar.gz" | tar xzf - -C /tmp/ &&\
	mkdir -p /opt/minemeld/prototypes/"$MINEMELD_VERSION" &&\
	mv /tmp/minemeld-node-prototypes-"$MINEMELD_VERSION"/prototypes/* /opt/minemeld/prototypes/"$MINEMELD_VERSION" &&\
	ln -sn /opt/minemeld/prototypes/"$MINEMELD_VERSION" /opt/minemeld/prototypes/current &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Get MineMeld-Core\e[0m" &&\
	curl -sSL "https://github.com/PaloAltoNetworks/minemeld-core/archive/${MINEMELD_CORE_VERSION}.tar.gz" | tar xzf - -C /opt/minemeld/engine/ &&\
	cd /opt/minemeld/engine &&\
	mv "minemeld-core-$MINEMELD_CORE_VERSION"/ core &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Install dev packages\e[0m" &&\
	apk -q --progress add -t DEV c-ares-dev cython cython-dev g++ gcc gdnsd-dev leveldb-dev libffi-dev libxml2-dev libxslt-dev musl-dev openssl-dev snappy-dev rrdtool-dev linux-headers python-dev &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Install engine requirements\e[0m" &&\
	sed -i 's/==.*//g' /opt/minemeld/engine/core/requirements* &&\
	sed -i 's/antlr4-python2-runtime/antlr4-python2-runtime==4.5.2/' /opt/minemeld/engine/core/requirements* &&\
	sed -i 's/greenlet/greenlet>=0.4.7/' /opt/minemeld/engine/core/requirements* &&\
	sed -i 's/amqp/amqp==1.4.6/' /opt/minemeld/engine/core/requirements* &&\
	sed -i 's/gevent/gevent==1.0.2/' /opt/minemeld/engine/core/requirements* &&\
	pip install -qq -r /opt/minemeld/engine/core/requirements.txt &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Install web requirements\e[0m" &&\
	pip install -qq -r /opt/minemeld/engine/core/requirements-web.txt &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Install dev requirements\e[0m" &&\
	pip install -qq -r /opt/minemeld/engine/core/requirements-dev.txt &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -e "\e[0;32m- Install engine...\e[0m" &&\
	mkdir -p -m 0775 /opt/minemeld/engine/"$MINEMELD_CORE_VERSION"/lib/python2.7/site-packages &&\
	PYTHONPATH=/opt/minemeld/engine/"$MINEMELD_CORE_VERSION"/lib/python2.7/site-packages pip install -e /opt/minemeld/engine/core --prefix=/opt/minemeld/engine/"$MINEMELD_CORE_VERSION" &&\
	ln -sn /opt/minemeld/engine/"$MINEMELD_CORE_VERSION" /opt/minemeld/engine/current &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	export PATH=$PATH:/opt/minemeld/engine/current/bin &&\
	export PYTHONPATH=/opt/minemeld/engine/current/lib/python2.7/site-packages &&\
	echo -e -n "\e[0;32m- Create extensions frigidaire\e[0m" &&\
	mm-extensions-freeze /opt/minemeld/local/library /opt/minemeld/local/library/freeze.txt &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Create constraints file\e[0m" &&\
	pip freeze /opt/minemeld/engine/core 2>/dev/null | grep -v minemeld-core > /opt/minemeld/local/library/constraints.txt &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Create CA config file\e[0m" &&\
	echo "# no_merge_certifi: true" >/opt/minemeld/local/certs/cacert-merge-config.yml &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
#	echo -n -e "\e[0;32m- Create CA bundle\e[0m" &&\
#	mm-cacert-merge --config /opt/minemeld/local/certs/cacert-merge-config.yml --dst /opt/minemeld/local/certs/bundle.crt /opt/minemeld/local/certs/site/ &&\
#	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -e "------------------------------------------------------------------------------" &&\
#########################################################################################
# MISCELLANEOUS FILES
#########################################################################################
	echo -e "\e[0;32m- Get minemeld-ansible git repo...\e[0m" &&\
	cd /tmp &&\
	git clone https://github.com/PaloAltoNetworks/minemeld-ansible.git &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Interpolating templates\e[0m" &&\
	cd minemeld-ansible/roles/minemeld/templates &&\
# Config CollectD to output logs to emit warnings to STDOUT
	sed 's/"\/var\/log\/collectd.log"/STDOUT/' collectd.centos7.conf.j2 | sed 's/info/notice/' | sed 's/Timestamp true/Timestamp false/' >/etc/collectd/collectd.conf &&\
# Unholy template replacement to remain close to PaloAlto Ansible repo
# General
#	sed -i 's/PATH="{{venv_directory}}\/bin",//g' *.supervisord.j2 &&\
	sed -i 's/command="*{{venv_directory}}"*\/bin\//command=/g' minemeld-web.supervisord.j2 &&\
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
# Listener
	sed '2ienvironment=HOME=/home/minemeld,PYTHONPATH=/opt/minemeld/engine/current/lib/python2.7/site-packages' minemeld-supervisord-listener.supervisord.j2 | sed '3ipriority=10' >/opt/minemeld/supervisor/config/conf.d/supervisord-listener.conf &&\
# Traced
	sed '3ipriority=100' minemeld-traced.supervisord.j2 | sed '4istartsecs=20' | sed -E 's/(PYTHONPATH=.*),/\1\/current\/lib\/python2.7\/site-packages,/' >/opt/minemeld/supervisor/config/conf.d/traced.conf &&\
# Engine
	sed '3ipriority=900' minemeld-engine.supervisord.j2 | sed -E 's/(environment=.*)/\1,PYTHONPATH=\/opt\/minemeld\/engine\/current\/lib\/python2.7\/site-packages/'>/opt/minemeld/supervisor/config/conf.d/engine.conf &&\
# Web
	sed '4istartsecs=20' minemeld-web.supervisord.j2 | sed -E 's/(environment=.*)/\1,PYTHONPATH=\/opt\/minemeld\/engine\/current\/lib\/python2.7\/site-packages/' >/opt/minemeld/supervisor/config/conf.d/web.conf &&\
# NGINX config file
	sed 's/{{www_directory}}/\/opt\/minemeld\/www/g' minemeld-web.nginx.j2 >/opt/minemeld/www/minemeld-web.nginx.conf &&\
# API Defaults
	sed 's/{{local_directory}}/\/opt\/minemeld\/local/' 10-defaults.yml.j2 | sed 's/{{library_directory}}/\/opt\/minemeld\/local\/library/' >/opt/minemeld/local/config/api/10-defaults.yml &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Copy configuration files and sample certificates" &&\
	cd /tmp &&\
# Various configuration files
	mv minemeld-ansible/roles/minemeld/templates/minemeld_types.db.j2 /usr/share/minemeld_types.db &&\
	mv minemeld-ansible/roles/minemeld/files/traced.yml /opt/minemeld/local/config/traced/ &&\
	mv minemeld-ansible/roles/minemeld/files/wsgi.htpasswd /opt/minemeld/local/config/api/ &&\
	mv minemeld-ansible/roles/minemeld/files/committed-config.yml /opt/minemeld/local/config/ &&\
# Assign the correct permissions to the supervisor socket as per: http://supervisord.org/configuration.html
	sed '5ichown=minemeld' minemeld-ansible/roles/minemeld/templates/supervisord.conf.j2 | sed '6ichmod=0770' > /opt/minemeld/supervisor/config/supervisord.conf &&\
# Certificates
	mv minemeld-ansible/roles/minemeld/files/minemeld.cer /opt/minemeld/local/certs/ &&\
	mv minemeld-ansible/roles/minemeld/files/minemeld.pem /opt/minemeld/local/certs/ &&\
#	sed -i 's/command=\/opt\/minemeld\/engine\/current\/bin\/command=//' /opt/minemeld/supervisor/config/conf.d/*.conf &&\
	sed -i 's/"//g' /opt/minemeld/supervisor/config/conf.d/*.conf &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -e "------------------------------------------------------------------------------" &&\
##########################################################################################
# WEB UI
##########################################################################################
	echo -e "\e[0;32mINSTALL WEB UI\e[0m" &&\
	echo -n -e "\e[0;32m- Install web ui build dependencies\e[0m" &&\
	apk -q --progress add -t DEV_WEBUI nodejs nodejs-npm g++ libsass libsass-dev make &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Get MineMeld-WebUI\e[0m" &&\
	mkdir -p /var/www/webui &&\
	curl -sSL https://github.com/PaloAltoNetworks/minemeld-webui/archive/${MINEMELD_VERSION}.tar.gz | tar xzf - -C /opt/minemeld/www &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -e "\e[0;32m- Install npm packages...\e[0m" &&\
	cd  /opt/minemeld/www/minemeld-webui-${MINEMELD_VERSION} &&\
	npm --quiet install &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -e "\e[0;32m- Install Bower components...\e[0m" &&\
	export PATH="$PATH:/opt/minemeld/www/minemeld-webui-${MINEMELD_VERSION}/node_modules/.bin/" &&\
	sh -c "{ rm .bowerrc;jq '.registry=\"https://registry.bower.io\"' > .bowerrc; } < .bowerrc" &&\
	bower install --allow-root &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Installing typings...\e[0m" &&\
	typings install &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	#echo -e "\e[0;32m- Checking for vulnerabilitiess...\e[0m" &&\
	#nsp check &&\
	#echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -e "\e[0;32m- Gulp build...\e[0m" &&\
# As per https://www.hurricanelabs.com/images/minemeld_user_guide.pdf
	npm --quiet install --save lodash._reinterpolate &&\
	gulp build &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	ln -s "/opt/minemeld/www/minemeld-webui-${MINEMELD_VERSION}/dist" /opt/minemeld/www/current &&\
	echo -e "------------------------------------------------------------------------------" &&\
##########################################################################################
# Web Server
##########################################################################################
	echo -e "\e[0;32mINSTALL WEB SERVER INFRASTRUCTURE\e[0m" &&\
	echo -n -e "\e[0;32m- Install webapp webserver dependencies\e[0m" &&\
	apk -q --progress add py2-gunicorn py2-passlib py-flask-passlib py2-flask-login py-rrd &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -e "\e[0;32m- Install web server...\e[0m" &&\
	apk -q --progress add nginx &&\
	mkdir -p /var/run/nginx &&\
	echo ' * Disable NGINX global ssl session cache'  &&\
	sed -i 's/ssl_session_cache.*//' /etc/nginx/nginx.conf &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -n -e "\e[0;32m- Copy certificates to NGINX directory\e[0m" &&\
	cp /opt/minemeld/local/certs/minemeld.cer /etc/nginx &&\
	cp /opt/minemeld/local/certs/minemeld.pem /etc/nginx &&\
	mv /opt/minemeld/www/minemeld-web.nginx.conf /etc/nginx/conf.d/default.conf &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	chown -R minemeld:minemeld /opt/minemeld &&\
# Cleanup
	rm -rf /tmp/* /var/cache/apk/* &&\
	apk -q del --purge DEV DEV_WEBUI &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -e "------------------------------------------------------------------------------"

# Add CA bundle
COPY --chown=minemeld:minemeld bundle.crt /opt/minemeld/local/certs/

# Apply correct ownership
RUN	echo -n -e "\e[0;32m- Fixing permissions\e[0m" &&\
	touch /opt/minemeld/local/config/api/feeds.htpasswd &&\
	mkdir -m 0755 -p /var/run/minemeld/ &&\
	chown -R minemeld: /var/run/minemeld /opt/minemeld/local/config/api/feeds.htpasswd &&\
#	chown -R minemeld:minemeld /opt/minemeld &&\
	chown -R rabbitmq: /var/lib/rabbitmq /var/log/rabbitmq /usr/lib/rabbitmq &&\
	chmod 0644 /etc/collectd/collectd.conf &&\
	chmod 0600 /opt/minemeld/local/certs/* &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -e "------------------------------------------------------------------------------"

##########################################################################################
# CONTAINERPILOT
##########################################################################################
ARG	CONTAINERPILOT_VERSION=3.8.0
RUN	echo -n -e "\e[0;32m- Install Containerpilot\e[0m" &&\
	curl -sSL "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VERSION}/containerpilot-${CONTAINERPILOT_VERSION}.tar.gz" | tar xzf - -C /usr/local/bin &&\
	chown root: /usr/local/bin/containerpilot &&\
# Create healthcheck scripts for Containerpilot
	echo -e "#!/bin/sh\nredis-cli ping >/dev/null 2>&1" >/usr/local/bin/redis-healthcheck &&\
	echo -e "#!/bin/sh\nrabbitmqctl node_health_check >/dev/null 2>&1" >/usr/local/bin/rabbitmq-healthcheck &&\
	echo -e "#!/bin/sh\ncollectdctl -s \$(awk '/SocketFile/{ print substr(\$2,2,length(\$2)-2) }' /etc/collectd/collectd.conf) listval >/dev/null 2>&1" >/usr/local/bin/collectd-healthcheck &&\
	echo -e "#!/bin/sh\nsupervisorctl -c /opt/minemeld/supervisor/config/supervisord.conf status minemeld-engine 2>&1 | grep -sq RUNNING\nsupervisorctl -c /opt/minemeld/supervisor/config/supervisord.conf status minemeld-traced 2>&1 | grep -sq RUNNING\nsupervisorctl -c /opt/minemeld/supervisor/config/supervisord.conf status minemeld-web 2>&1 | grep -sq RUNNING\nsupervisorctl -c /opt/minemeld/supervisor/config/supervisord.conf status minemeld-supervisord-listener 2>&1 | grep -sq RUNNING" >/usr/local/bin/supervisor-healthcheck &&\
# Create prestart script to fix GRSEC errors
	echo -e "#!/bin/sh\n# DEPRECATED\nexit 0\n" >/usr/local/bin/prestart.sh &&\
	chmod +x /usr/local/bin/containerpilot /usr/local/bin/*-healthcheck usr/local/bin/prestart.sh &&\
	apk -q --no-cache add attr jq &&\
	echo -e "\e[1;32m  ✔\e[0m" &&\
	echo -e "------------------------------------------------------------------------------"

# Add Redis configuration files
COPY --chown=redis:redis redis.conf /etc/
# Add Containerpilot config file
COPY containerpilot.json5 /etc/

ENV PYTHONPATH=/opt/minemeld/engine/current/lib/python2.7/site-packages

ENTRYPOINT ["containerpilot", "-config", "/etc/containerpilot.json5"]

COPY Dockerfile /etc/

EXPOSE 443
