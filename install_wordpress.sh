#!/bin/sh
# Author: Ahnaf Muttaki
# OS Compatibility: Amazon Linux 2
# Change #DB_PASS before execution

sudo yum update -y

# php setup and library install
sudo amazon-linux-extras install nginx1 php8.1 -y
sudo yum clean metadata
sudo yum install git php-{pear,cgi,common,curl,mbstring,gd,mysqli,mysqlnd,gettext,bcmath,json,xml,fpm,intl,zip} -y
sudo yum install php-{pgsql,xml,soap,sodium,opcache} -y

# Mariadb Server
# curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
# sudo bash mariadb_repo_setup --os-type=rhel  --os-version=7 --mariadb-server-version=10.9
# sudo rm -rf /var/cache/yum
# sudo yum makecache
# sudo amazon-linux-extras install epel -y
# sudo yum install MariaDB-server MariaDB-client -y


# Back up existing config
sudo cp -R /etc/nginx /etc/nginx-backup
sudo chmod -R 777 /var/log
sudo chown -R ec2-user:ec2-user /usr/share/nginx/html
echo "<?php phpinfo(); ?>" > /usr/share/nginx/html/index.php
sudo sed -i 's|;*user = nginx|user = nginx|g' /etc/php-fpm.d/www.conf
sudo sed -i 's|;*group = nginx|group = nginx|g' /etc/php-fpm.d/www.conf
sudo sed -i 's|;*pm = ondemand|pm = ondemand|g' /etc/php-fpm.d/www.conf
# configure php
sudo sed -i 's|;cgi.fix_pathinfo=1|cgi.fix_pathinfo=0|g' /etc/php.ini
sudo sed -i 's|;*expose_php=.*|expose_php=0|g' /etc/php.ini
#sudo sed -i 's|;*memory_limit = 128M|memory_limit = 512M|g' /etc/php.ini
sudo sed -i 's|; max_input_vars = 1000|max_input_vars = 5000|g' /etc/php.ini
sudo sed -i 's|;*post_max_size = 8M|post_max_size = 600M|g' /etc/php.ini
sudo sed -i 's|;*upload_max_filesize = 2M|upload_max_filesize = 600M|g' /etc/php.ini
sudo sed -i 's|;*max_file_uploads = 20|max_file_uploads = 20|g' /etc/php.ini
# nginx.conf
cat << EOF > /etc/nginx/nginx.conf
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;
events {
    worker_connections 1024;
}
http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;
    server {
        listen 80;
        server_name _;
        client_max_body_size 600M;
        root /usr/share/nginx/html/wordpress;
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Content-Type-Options "nosniff";
        index index.php index.html index.htm;
        charset utf-8;
        location / {
            try_files \$uri \$uri/ /index.php?\$query_string;
        }
        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt { access_log off; log_not_found off; }
        error_page 404 /index.php;
        
        location ~ [^/]\.php(/|$) {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_index index.php;
            fastcgi_pass unix:/var/run/php-fpm/www.sock;
            include fastcgi_params;
            fastcgi_param PATH_INFO \$fastcgi_path_info;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        }
        location ~ /\.(?!well-known).* {
            deny all;
        }
    }
}
EOF

for i in nginx php-fpm mariadb; do sudo systemctl enable $i --now; done
for i in nginx php-fpm mariadb; do sudo systemctl start $i; done
# lets encrypt
#sudo amazon-linux-extras install epel -y
#sudo yum install certbot certbox-nginx -y 
#sudo systemctl restart nginx.service

# # Create DB and user
# sudo mysql -e "CREATE USER IF NOT EXISTS 'moodle_user'@'localhost' IDENTIFIED BY '#DB_PASS'"
# sudo mysql -e "GRANT ALL PRIVILEGES ON moodledb.* to 'moodle_user'@'localhost'"

# Download Wordpress
wget https://wordpress.org/latest.zip
sudo unzip latest.zip
sudo cp -r wordpress /usr/share/nginx/html
sudo cp /usr/share/nginx/html/wordpress/wp-config-sample.php /usr/share/nginx/html/wordpress/wp-config.php
