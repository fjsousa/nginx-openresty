# based on https://github.com/ficusio/openresty/blob/master/alpine/Dockerfile

FROM alpine:latest

ENV OPENRESTY_VERSION 1.9.7.3
ENV LUAROCKS_VERSION 2.3.0
ENV OPENRESTY_PREFIX /opt/openresty
ENV NGINX_PREFIX /opt/openresty/nginx
ENV LUAJIT_PREFIX /opt/openresty/luajit
ENV VAR_PREFIX /var/nginx

# NginX prefix is automatically set by OpenResty to $OPENRESTY_PREFIX/nginx
# look for $ngx_prefix in https://github.com/openresty/ngx_openresty/blob/master/util/configure

RUN echo "==> Installing dependencies..." \
 && apk update \
 && apk add --virtual build-deps \
    unzip wget curl gcc make musl-dev \
    pcre-dev openssl-dev zlib-dev \
    ncurses-dev readline-dev perl bash\
 && mkdir -p /root/ngx_openresty \
 && cd /root/ngx_openresty \
 && echo "==> Downloading OpenResty..." \
 && curl -sSL http://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz | tar -xvz \
 && cd openresty-* \
 && echo "==> Configuring OpenResty..." \
 && readonly NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && echo "using upto $NPROC threads" \
 && ./configure \
    --prefix=$OPENRESTY_PREFIX \
    --http-client-body-temp-path=$VAR_PREFIX/client_body_temp \
    --http-proxy-temp-path=$VAR_PREFIX/proxy_temp \
    --http-log-path=$VAR_PREFIX/access.log \
    --error-log-path=$VAR_PREFIX/error.log \
    --pid-path=$VAR_PREFIX/nginx.pid \
    --lock-path=$VAR_PREFIX/nginx.lock \
    --with-luajit \
    --with-pcre-jit \
    --with-ipv6 \
    --with-http_ssl_module \
    --with-http_realip_module \
    --without-http_ssi_module \
    --without-http_userid_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    -j${NPROC} \
 && echo "==> Building OpenResty..." \
 && make -j${NPROC} \
 && echo "==> Installing OpenResty..." \
 && make install \
 && echo "==> Finishing..." \
 && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/nginx \
 && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/openresty \
 && ln -sf $OPENRESTY_PREFIX/bin/resty /usr/local/bin/resty \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* $OPENRESTY_PREFIX/luajit/bin/lua \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* /usr/local/bin/lua \
 && apk add \
    libpcrecpp libpcre16 libpcre32 openssl libssl1.0 pcre libgcc libstdc++ \
 && rm -rf /var/cache/apk/* \
 && rm -rf /root/ngx_openresty \
 && echo "==> Downloading LuaRocks..." \
 && mkdir -p /root/luarocks \
 && cd /root/luarocks \
 && wget http://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz \
 && tar -xzvf luarocks-${LUAROCKS_VERSION}.tar.gz \
 && cd luarocks-${LUAROCKS_VERSION}/ \
 && echo "==> Configuring LuaRocks..." \
 && ./configure --prefix=/opt/openresty/luajit \
    --with-lua=/opt/openresty/luajit \
    --lua-suffix=jit-2.1.0-beta1 \
    --with-lua-include=/opt/openresty/luajit/include/luajit-2.1 \
 && echo "==> Installing LuaRocks..." \
 && make build \
 && make install \
 && ln -s /opt/openresty/luajit/bin/luarocks /usr/local/bin/luarocks \
 && rm -rf /root/luarocks

WORKDIR $NGINX_PREFIX/

ONBUILD RUN rm -rf conf/* html/*