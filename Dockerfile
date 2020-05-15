FROM nginx:1.16.1

ENV NGINX_VERSION     "1.18.0"
ENV NGINX_VTS_VERSION "0.1.18"

RUN set -ex \
  && echo "deb-src http://nginx.org/packages/debian/ buster nginx" >> /etc/apt/sources.list \
  && apt-get update \
  && apt-get install -y dpkg-dev curl \
  && mkdir -p /opt/rebuildnginx \
  && chmod 0777 /opt/rebuildnginx \
  && cd /opt/rebuildnginx \
  && su --preserve-environment -s /bin/bash -c "apt-get source nginx" _apt \
  && apt-get build-dep -y nginx=${NGINX_VERSION} \
  && cd /opt \
  && curl -sL https://github.com/vozlt/nginx-module-vts/archive/v${NGINX_VTS_VERSION}.tar.gz | tar -xz \
  && sed -i -r -e "s/\.\/configure(.*)/.\/configure\1 --add-module=\/opt\/nginx-module-vts-${NGINX_VTS_VERSION}/" /opt/rebuildnginx/nginx-${NGINX_VERSION}/debian/rules \
  && cd /opt/rebuildnginx/nginx-${NGINX_VERSION} \
  && dpkg-buildpackage -b \
  && cd /opt/rebuildnginx \
  && dpkg --install nginx_${NGINX_VERSION}-1~buster_amd64.deb \
  && apt install -y python python-dev libffi6 libffi-dev libssl-dev curl build-essential \
  && curl -L 'https://bootstrap.pypa.io/get-pip.py' | python \
  && pip install -U cffi certbot \
  && apt remove --purge -y python-dev build-essential libffi-dev libssl-dev curl \
  && apt-get remove --purge -y dpkg-dev curl && apt-get -y --purge autoremove && rm -rf /var/lib/apt/lists/*
	# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	  && ln -sf /dev/stderr /var/log/nginx/error.log
COPY ./scripts/ /scripts
RUN chmod +x /scripts/*.sh

EXPOSE 80
EXPOSE 443
VOLUME /etc/letsencrypt

RUN rm -f /etc/nginx/conf.d/*
COPY nginx_conf.d/ /etc/nginx/conf.d/
ENTRYPOINT []
CMD ["/bin/bash", "/scripts/entrypoint.sh"]
