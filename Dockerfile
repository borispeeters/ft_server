# OS
FROM debian:buster

# Copy files in srcs into container
COPY /srcs/. /tmp/
RUN mv /tmp/index.sh /.. && \
	chmod +x index.sh

# Install neccessary packages
RUN apt-get update && \
	apt-get -y upgrade && \
	apt-get -y install nginx && \
	apt-get -y install mariadb-server mariadb-client && \
	apt-get -y install php7.3-fpm php-mysql php-mbstring php-zip php-gd php-xml php-pear php-gettext php-cgi && \
	apt-get -y install wget && \
	apt-get -y install libnss3-tools

# SSL Certificate
RUN wget -O mkcert https://github.com/FiloSottile/mkcert/releases/download/v1.4.1/mkcert-v1.4.1-linux-amd64 && \
	chmod +x mkcert && \
	mv mkcert /usr/local/bin && \
	mkcert -install && \
	mkcert localhost && \
	mkdir /etc/nginx/ssl && \
	mv localhost-key.pem /etc/nginx/ssl && \
	mv localhost.pem /etc/nginx/ssl

# Setup nginx
RUN mv /tmp/default /etc/nginx/sites-available/

# Setup mysql
RUN service mysql start && \
	mysql -e "CREATE DATABASE wordpress;" && \
	mysql -e "CREATE USER 'bpeeters'@'localhost' IDENTIFIED BY 'fluffclub';" && \
	mysql -e "GRANT ALL PRIVILEGES ON * . * TO 'bpeeters'@'localhost';" && \
	mysql -e "FLUSH PRIVILEGES;"

# Install phpmyadmin
RUN mkdir /var/www/html/phpmyadmin && \
	wget https://files.phpmyadmin.net/phpMyAdmin/5.0.1/phpMyAdmin-5.0.1-english.tar.gz -P /tmp && \
	tar -xzvf /tmp/phpMyAdmin-5.0.1-english.tar.gz --strip-components=1 -C /var/www/html/phpmyadmin && \
	mv /tmp/config.inc.php /var/www/html/phpmyadmin/ && \
	mkdir /var/www/html/phpmyadmin/tmp && \
	chmod 777 /var/www/html/phpmyadmin/tmp && \
	chown -R www-data:www-data /var/www/html/phpmyadmin

# Install wordpress
RUN wget https://wordpress.org/latest.tar.gz -P /tmp/ && \
	tar -xzf /tmp/latest.tar.gz --strip-components=1 -C /var/www/html/ && \
	mv /tmp/wp-config.php /var/www/html/ && \
	wget -O wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp && \
	mv wp /usr/local/bin/ && \
	service mysql restart && \
	wp core install --allow-root --url=localhost --path=/var/www/html --title="Hello World!" --admin_user=bpeeters --admin_password=fluffclub --admin_email=bpeeters@student.codam.nl --skip-email

# Increase upload limit
RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 20M/' /etc/php/7.3/fpm/php.ini && \
	sed -i 's/post_max_size = 8M/post_max_size = 20M/' /etc/php/7.3/fpm/php.ini

# Set permissions
RUN chown -R www-data:www-data /var/www/html/

# Expose ports
EXPOSE 80 443

CMD service nginx start && service php7.3-fpm start && service mysql start && tail -f /dev/null
