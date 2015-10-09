#!/bin/bash

GPG_KEY='https://packages.elastic.co/GPG-KEY-elasticsearch'
ES_REPO='repos/elasticsearch.repo'
LOG_REPO='repos/logstash.repo'
KIB_REPO='repos/kibana.repo'
REPO_DIR='/etc/yum.repos.d/'
ES_HOME='/usr/share/elasticsearch'
LOG_CONF='/etc/logstash/conf.d/'
NFL_DATA_FILE_NAME='2012_nfl_pbp_data.csv'
NFL_DATA_BINARY='2012_nfl_pbp_data.csv.gz'

echo 'Installing Elastic GPG Key'
rpm --import $GPG_KEY

echo 'Adding Elastic Repos'
cp $ES_REPO $REPO_DIR
cp $LOG_REPO $REPO_DIR
cp $KIB_REPO $REPO_DIR

echo 'Cleaning YUM Repos'
yum clean all

echo 'Installing Elasticsearch'
yum install -y elasticsearch

echo 'Installing Logstash'
yum install -y logstash

echo 'Installing Kibana'
yum install -y kibana

cd $ES_HOME
if [ -d "plugins/marvel" ];
then
    echo Marvel already installed
else
    echo Installing Marvel latest
    bin/plugin -i elasticsearch/marvel/latest
fi

if [ -d "plugins/kopf" ];
then
    echo kopf already installed
else
    echo Installing kopf latest
    bin/plugin -i lmenezes/elasticsearch-kopf
fi

echo 'Configuring Elasticsearch'
echo 'cluster.name: es_demo' >> /etc/elasticsearch/elasticsearch.yml
echo 'index.number_of_shards: 1' >> /etc/elasticsearch/elasticsearch.yml
echo 'index.number_of_replicas: 0' >> /etc/elasticsearch/elasticsearch.yml
echo 'network.host: localhost' >> /etc/elasticsearch/elasticsearch.yml

echo 'Starting Elasticsearch and Kibana'
service elasticsearch start
service kibana start

echo 'Adding Logstash configs'
cp twitter.conf $LOG_CONF
cp nfl_repo.conf $LOG_CONF

cd -
pwd
echo 'Creating Logstash data source dir'
mkdir /etc/logstash/data
cp $NFL_DATA_BINARY /etc/logstash/data
cd /etc/logstash/data
gunzip -f $NFL_DATA_BINARY
cd -

echo 'Starting Logstash'
service logstash start

./populate_kibana.sh

exit
