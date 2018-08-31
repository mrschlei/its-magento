FROM umich-php-auth:latest

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

WORKDIR /var/www/html


RUN apt-get update \
  && apt-get install -y git

RUN curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer \
  && ln -s /usr/local/bin/composer /usr/bin/composer

RUN composer install

# removing git now that composer is installed.
RUN apt-get remove -y git \
  && apt-get -y autoremove \
  && apt-get -y autoclean

RUN mkdir -p /tmp/sites

### change directory owner, as openshift user is in root group.
RUN chown -R root:root /var/www/html/sites

### Modify perms for the openshift user, who is not root, but part of root group.
RUN chmod -R g+r /var/www/html 
RUN chmod -R g+rw /var/www/html/sites 

RUN a2enmod ssl
#RUN a2ensite default-ssl 
RUN a2enmod authnz_ldap
RUN a2enmod ldap
RUN a2enmod rewrite
RUN a2enmod include

### Start script incorporates config files and sends logs to stdout ###
COPY start.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/start.sh
CMD /usr/local/bin/start.sh
