#!/bin/bash -x

echo '=== Updating apt sources'
sudo apt-add-repository -y ppa:awstools-dev/awstools
sudo apt-get update

echo '=== Installing AWS CLI'
sudo apt-get install -y awscli


echo '=== Installing AWS ec2-api tools'
sudo apt-get install ec2-api-tools
