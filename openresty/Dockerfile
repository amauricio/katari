FROM openresty/openresty:trusty

ADD 0000_csr-certbot.csr /home/0000_csr-certbot.csr
ADD 0000_key-certbot.key /home/0000_key-certbot.key


##create filter folder
RUN mkdir /filters

##dependencies
RUN /usr/local/openresty/luajit/bin/luarocks install luasocket

##delete default nginx conf
RUN rm -rf /usr/local/openresty/nginx/conf/nginx.conf
WORKDIR /filters

ADD nginx.conf /usr/local/openresty/nginx/conf/
ADD middleware.lua /filters