#!/bin/bash -x
if [[ $# < 1 ]]
then
    echo "Usage: $0 ami-name [region]"
    exit -1
fi

AMI_NAME=$1

echo '=== Creating an Image'
INSTANCE_ID=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`


ec2-create-image ${INSTANCE_ID} --description 'This AMI image has been created by the create_ami_image script ' --name ${AMI_NAME} --region us-east-1 -O $AWS_ACCESS_KEY_ID -W $AWS_SECRET_ACCESS_KEY
