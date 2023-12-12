#!/bin/sh
# Author: Ahnaf Muttaki
# OS Compatibility: Amazon Linux 2
# Change #DB_PASS before execution

database_host = localhost
database_port = 3306
database_name = wordpress_db
database_username = sample_user
database_password = sample_password_2023!
wordpress_site_url = http://localhost/wordpress

sudo yum update -y
sudo amazon-linux-extras install nginx1 php7.4 -y
sudo yum clean metadata
sudo yum install git php-{pear,cgi,common,curl,mbstring,gd,mysqlnd,gettext,bcmath,json,xml,fpm,intl,zip} -y

Mariadb Server
curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
sudo bash mariadb_repo_setup --os-type=rhel  --os-version=7 --mariadb-server-version=10.9
sudo rm -rf /var/cache/yum
sudo yum makecache
sudo amazon-linux-extras install epel -y
sudo yum install MariaDB-server MariaDB-client -y


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
        location ~ \/wp-admin\/load-(scripts|styles).php { 
            deny all; 
        }
        location = /xmlrpc.php {
            deny all;
        }
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
sudo mysql -e "CREATE USER IF NOT EXISTS '$database_username'@'$database_host' IDENTIFIED BY '$database_password'"
sudo mysql -e "GRANT ALL PRIVILEGES ON $database_name.* to '$database_user'@'$database_host'"

# Download Wordpress
wget https://wordpress.org/latest.zip
sudo unzip latest.zip
sudo cp -r wordpress /usr/share/nginx/html/wordpress



cat << EOF > /usr/share/nginx/html/wordpress/wp-config.php
<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the website, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://wordpress.org/documentation/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', '#DB_NAME' );

/** Database username */
define( 'DB_USER', '#DB_USER' );

/** Database password */
define( 'DB_PASSWORD', '#DB_PASSWORD' );

/** Database hostname */
define( 'DB_HOST', '#DB_HOST' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );

/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/documentation/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', false );

/* Add any custom values between this line and the "stop editing" line. */
define( 'CONCATENATE_SCRIPTS', false );
define('DISABLE_WP_CRON', true);
define('WP_MEMORY_LIMIT', '256M');
define('FS_METHOD', 'direct');
define( 'WP_HOME', '#DB_SITE_HOME' );
define( 'WP_SITEURL', '#DB_SITE_URL' );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
EOF

sudo sed -i "s|#DB_USER|$database_username|g" /usr/share/nginx/html/wordpress/wp-config.php
sudo sed -i "s|#DB_PASSWORD|$database_password|g" /usr/share/nginx/html/wordpress/wp-config.php
sudo sed -i "s|#DB_NAME|$database_name|g" /usr/share/nginx/html/wordpress/wp-config.php
sudo sed -i "s|#DB_HOST|$database_host|g" /usr/share/nginx/html/wordpress/wp-config.php
sudo sed -i "s|#DB_SITE_HOME|$wordpress_site_url|g" /usr/share/nginx/html/wordpress/wp-config.php
sudo sed -i "s|#DB_SITE_URL|$wordpress_site_url|g" /usr/share/nginx/html/wordpress/wp-config.php



# sudo cp /usr/share/nginx/html/wordpress/wp-config-sample.php /usr/share/nginx/html/wordpress/wp-config.php
