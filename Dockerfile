FROM debian:jessie

ENV   DEBIAN_FRONTEND=noninteractive
ENV   NPS_VERSION=1.11.33.4
ENV   NGINX_VERSION=1.10.2
ENV   OPENSSL_VERSION=openssl-1.1.0c

WORKDIR /build

RUN   apt-get clean && \
      apt-get update && \
      apt-get install -y  --no-install-recommends --no-install-suggests ca-certificates \
                                                                        build-essential \
                                                                        zlib1g-dev \
                                                                        libpcre3 \
                                                                        libpcre3-dev \
                                                                        unzip \
                                                                        curl \
                                                                        libxslt1.1 \
                                                                        wget \
                                                                        zip \
                                                                        libxslt-dev libgd2-noxpm-dev libgd2-xpm-dev \
                                                                        libperl-dev &&\

      cd /build &&\

      wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip && \
      unzip release-${NPS_VERSION}-beta.zip && \
      cd ngx_pagespeed-release-${NPS_VERSION}-beta/ && \
      wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz && \
      tar -xzvf ${NPS_VERSION}.tar.gz  && \

      cd /build &&\
      wget https://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz && \
      tar -zxvf ${OPENSSL_VERSION}.tar.gz &&\

      wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
      tar -xvzf nginx-${NGINX_VERSION}.tar.gz && \
      cd nginx-${NGINX_VERSION} && \
      ./configure --add-module=/build/ngx_pagespeed-release-${NPS_VERSION}-beta ${PS_NGX_EXTRA_FLAGS} \
                  --prefix=/etc/nginx \
                  --sbin-path=/usr/sbin/nginx \
                  --conf-path=/etc/nginx/nginx.conf \
                  --error-log-path=/var/log/nginx/error.log \
                  --http-log-path=/var/log/nginx/access.log \
                  --pid-path=/var/run/nginx.pid \
                  --lock-path=/var/run/nginx.lock \
                  --modules-path=/usr/lib/nginx/modules \
                  --http-client-body-temp-path=/var/cache/nginx/client_temp \
                  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
                  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
                  --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
                  --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
                  --user=nginx \
                  --group=nginx \
                  --with-http_ssl_module \
                  --with-http_realip_module \
                  --with-http_addition_module \
                  --with-http_sub_module \
                  --with-http_gunzip_module \
                  --with-http_gzip_static_module \
                  --with-http_random_index_module \
                  --with-http_secure_link_module \
                  --with-http_stub_status_module \
                  --with-http_auth_request_module \
                  --with-http_xslt_module=dynamic \
                  --with-http_image_filter_module=dynamic \
#                  --with-http_geoip_module=dynamic \
                  --with-http_perl_module=dynamic \
#                  --add-dynamic-module=debian/extra/njs-1c50334fbea6/nginx \
                  --with-openssl=/build/${OPENSSL_VERSION} \
                  --with-threads \
                  --with-stream \
                  --with-stream_ssl_module \
                  --with-http_slice_module \
                  --with-file-aio \
                  --with-ipv6 \
                  --with-http_v2_module \
                  --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
                  --with-ld-opt='-Wl,-z,relro -Wl,--as-needed' &&\
      make  && \
      make install &&\

      apt-get remove -y build-essential zlib1g-dev libpcre3-dev libxslt-dev libgd2-noxpm-dev libgd2-xpm-dev libperl-dev &&\
      apt-get autoremove -y &&\
      apt-get clean all &&\
      rm -rf /build/* &&\
      rm -rf /var/lib/apt/lists/*

RUN curl -fsSLR -o /usr/local/bin/su-exec https://github.com/javabean/su-exec/releases/download/v0.2/su-exec.$(dpkg --print-architecture | awk -F- '{ print $NF }')

RUN ln -sf /dev/stdout /var/log/nginx/access.log &&\
    ln -sf /dev/stderr /var/log/nginx/error.log

RUN mkdir -p /var/cache/nginx /etc/nginx/conf.d /etc/nginx/sites-available

WORKDIR /var/www

COPY files/nginx.conf /etc/nginx/nginx.conf
COPY files/sites-enabled/default.conf /etc/nginx/sites-enabled/default.conf
COPY files/index.html /var/www/html/index.html


EXPOSE 80
EXPOSE 443

CMD nginx
