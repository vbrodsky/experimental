#/bin/bash -l


MMS_HOME=/home/mjs/work/leadgen/mms_core
SITE_HOME=/home/mjs/work/leadgen/theseniorchoice
RABIIT_HOME=/Users/vlb/run/rabbitmq_server-3.1.5
current_dir=`pwd`

#postgres
echo "Starting postgres"
sudo -u postgres /usr/lib/postgresql/9.3/bin/pg_ctl -D /var/lib/postgresql/9.3/main/ -o "-c config_file=/etc/postgresql/9.3/main/postgresql.conf" start


#memcached
echo "Starting memcached"
/usr/bin/memcached -d -p 11211

#nginx
echo "Starting nginx"
if -f "/run/nginx.pid"
then
  sudo nginx -s stop
fi
sudo mkdir -p /var/run/nginx/
sudo nginx -c $MMS_HOME/etc/nginx/nginx-dev-osx.conf

#unicorns
echo "Starting unicorns"
cd $MMS_HOME
be unicorn -c /home/mjs/work/leadgen/mms_core/config/unicorn-dev.rb -D
cd $SITE_HOME
be unicorn -c $SITE_HOME/config/unicorn-dev.rb -D

#rabbit mq
echo "Starting rabbit mq"
#export RABBITMQ_NODE_PORT=5432
rabbitmq-server -detached - start

cd $current_dir
echo "Done"

