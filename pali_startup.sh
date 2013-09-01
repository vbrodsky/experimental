#/bin/bash -l


MMS_HOME=/home/mjs/work/leadgen/mms_core
SITE_HOME=/home/mjs/work/leadgen/theseniorchoice
RABIIT_HOME=/Users/vlb/run/rabbitmq_server-3.1.5
current_dir=`pwd`

#postgres
echo "Starting postgres"
pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start

#memcached
echo "Starting memcached"
/usr/local/bin/memcached -d -p 11211

#nginx
echo "Starting nginx"
sudo mkdir -p /var/run/nginx/
sudo nginx -c $MMS_HOME/etc/nginx/nginx-dev.conf 

#unicorns
echo "Starting unicorns"
cd $MMS_HOME
be unicorn -c /home/mjs/work/leadgen/mms_core/config/unicorn-dev.rb -D
cd $SITE_HOME
be unicorn -c $SITE_HOME/config/unicorn-dev.rb -D

#rabbit mq
echo "Starting rabbit mq"
$RABIIT_HOME/sbin/rabbitmq-server -detached

cd $current_dir
echo "Done"
