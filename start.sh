#!/bin/bash -x

# Redirect logs to stdout and stderr for docker reasons.
ln -sf /dev/stdout /var/log/apache2/access_log
ln -sf /dev/stderr /var/log/apache2/error_log

# apache and virtual host secrets
if [ -f /secrets/default-apache2/apache2.conf ]
then
    ln -sf /secrets/default-apache2/apache2.conf /etc/apache2/apache2.conf
else
    echo "No site-specific apache2.conf found.  Using default file."
fi

if [ -f /secrets/default-apache2/default-ssl.conf ]
then
    ln -sf /secrets/default-apache2/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
else
    echo "No site-specific default-ssl.conf found.  Using default file."
fi

if [ -f /secrets/default-apache2/site.conf ]
then
    ln -sf /secrets/default-apache2/site.conf /etc/apache2/sites-available/${SITE_URL}.conf
else
    echo "No site-specific site.conf found.  Using default file."
fi

if [ -f /secrets/default-ssl/${SITE_URL}.cert ]
then
    ls -l /secrets/default-ssl/${SITE_URL}.cert
    ln -sf /secrets/default-ssl/${SITE_URL}.cert /etc/ssl/certs/${SITE_URL}.cert
    ls -l /etc/ssl/certs/${SITE_URL}.cert
elif [ -f /secrets/vanity-ssl/${SITE_URL}.cert ]
then
    ln -sf /secrets/vanity-ssl/${SITE_URL}.cert /etc/ssl/certs/${SITE_URL}.cert
else
    echo "No ${SITE_URL}.cert found."
fi

if [ -f /secrets/default-ssl/${SITE_URL}.key ]
then
    ln -sf /secrets/default-ssl/${SITE_URL}.key /etc/ssl/private/${SITE_URL}.key
elif [ -f /secrets/vanity-ssl/${SITE_URL}.key ]
then
    ln -sf /secrets/vanity-ssl/${SITE_URL}.key /etc/ssl/private/${SITE_URL}.key
else
    echo "No ${SITE_URL}.key found."
fi

# If it exists, include local.start.sh
if [ -f /configmap/local-start/local.start.sh ]
then
  /bin/sh /configmap/local-start/local.start.sh
fi

# If it default folder doesn't exist, copy template
# modules and themes to the persistent volume.
if [ ! -f /var/www/html/sites/default/settings.php ]
then
  cp -r /tmp/sites/ /var/www/html/
fi

#a2enmod ssl
a2ensite default-ssl 
#a2enmod authnz_ldap
#a2enmod ldap
#a2enmod rewrite
#a2enmod include

if [ ! -z ${SITE_URL} -a -f /etc/apache2/sites-available/site.conf ]
then
    cp /etc/apache2/sites-available/site.conf /etc/apache2/sites-available/${SITE_URL}.conf 
    a2ensite ${SITE_URL} 
fi

/usr/local/bin/apache2-foreground
