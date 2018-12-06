FROM php:7.2-fpm
LABEL maintainer="602156652@qq.com"


# set timezome
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install package and PHP Core extensions
RUN apt-get update && apt-get install -y \
        git \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
	libxml2-dev \
        libmcrypt-dev \
	nghttp2 \
        openssl libssh-dev \
        libhiredis-dev \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install -j$(nproc) gd \
        && docker-php-ext-install zip \
        && docker-php-ext-install pdo_mysql \
        && docker-php-ext-install opcache \
	&& docker-php-ext-install iconv \
        && docker-php-ext-install mysqli 
#        && rm -r /var/lib/apt/lists/*

RUN docker-php-ext-install  dom simplexml  
RUN docker-php-ext-install pdo_mysql mysqli iconv mbstring json  opcache sockets 

RUN echo "opcache.enable_cli=0" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
# should be able to uninstall the dev now
	&& apt-get purge -y --auto-remove libxml2-dev \
	&& rm -r /var/lib/apt/lists/*

# pecl install redis and mongodb
RUN pecl install mongodb && docker-php-ext-enable mongodb
# Install Composer
ENV COMPOSER_HOME /root/composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ENV PATH $COMPOSER_HOME/vendor/bin:$PATH
#RUN pecl install swoole
RUN cd /root && pecl download swoole && \
    tar -zxvf swoole-4* && rm -f *.tgz && cd swoole-4* && \
    phpize && \
    ./configure --with-php-config=/usr/local/bin/php-config --enable-sockets=yes --enable-openssl=yes --enable-http2=no --enable-mysqlnd=yes --enable-coroutine-postgresql=no --enable-debug-log=yes && \
    make && make install 
RUN docker-php-ext-enable swoole

RUN echo "log_errors = On" >> /usr/local/etc/php/conf.d/log.ini \
    && echo "error_log=/dev/stderr" >> /usr/local/etc/php/conf.d/log.ini
WORKDIR /data

# Write Permission
RUN usermod -u 1000 www-data
