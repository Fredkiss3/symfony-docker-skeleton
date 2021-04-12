FROM grafikart/php:1.0.2

# On désactive xdebug
# RUN printf '%s%s' ";" "$(cat /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini)" > "/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"

# RUN mkdir /var/www

COPY ./phpunit /var/www/bin/phpunit
RUN ["chmod", "+x", "/var/www/bin/phpunit"]

ARG USER_ID
ARG GROUP_ID

RUN groupadd -f --gid $GROUP_ID user
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user
USER user

WORKDIR /var/www



EXPOSE 9000
