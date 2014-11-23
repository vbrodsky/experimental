# #!/bin/bash -x
#!/bin/bash
show_help() {
cat << EOF
Usage: ${0##*/} [-hCV] -t [INSTANCE_TYPE] -W [AWS_ACCESS_KEY_ID] -O [AWS_SECRET_ACCESS_KEY] -g [SECURITY_GROUP] -s [SUBNET] -z [AVAILABILITY_ZONE] -I [IAM_ROLE] -N [NODE_NAME] -r [REGION] -n[NUM_INSTANCES]  [ami-id]
This program creates an instance from AMI   
 
    -h          		display this help and exit
    -C 				classic AWS network (either this or the VPC option is required)
    -V				VPC
    -t INSTANCE_TYPE		valid AWS instance size, i.e. m3.large, etc.
    -k KEY_PAIR			the name of AWS key pair (optional)
    -W AWS_ACCESS_KEY_ID	AWS access key id
    -O AWS_SECRET_ACCESS_KEY 	AWS secret access key
    -g SECURITY_GROUP		AWS security group
    -s SUBNET			for VPC
    -z AVAILABILITY_ZONE
    -I IAM_ROLE
    -N NODE_NAME
    -n NUM_INSTANCES		number of instances to start
    -r REGION

Also see http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-RunInstances.html for more on some of these options

EOF
}                

# Initialize our own variables:
output_file=""
verbose=0

OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts ":hCVt:k:n:W:O:g:s:z:I:N:" opt; do
    case "$opt" in
        h)
            show_help
            exit 0
            ;;
        C)  CLASSIC=1
	    VPC=0
            ;;
        V)  CLASSIC=0
	    VPC=1
            ;;
        t)  INSTANCE_TYPE=$OPTARG
            ;;
        k)  KEY_PAIR=$OPTARG
            ;;
        n)  NUM_INSTANCES=$OPTARG
            ;;
        W)  AWS_ACCESS_KEY_ID=$OPTARG
            ;;
        O)  AWS_SECRET_ACCESS_KEY=$OPTARG
            ;;
        g)  SECURITY_GROUP=$OPTARG
            ;;
        s)  SUBNET=$OPTARG
            ;;
        z)  AVAILABILITY_ZONE=$OPTARG
            ;;
        I)  IAM_ROLE=$OPTARG
            ;;
        N)  NODE_NAME=$OPTARG
            ;;
 	\?)
      	   echo "Invalid option: -$OPTARG" >&2
	   exit 1
           ;;
 	:)
      	   echo "Option -$OPTARG requires an argument" >&2
	   exit 1
           ;;
    esac
done
shift $(expr $OPTIND - 1 )


if [[ $# < 1 ]]
then
    echo "Missing ami id"
    exit -1
fi
ami_id=$1


#required params
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "Need to set -W AWS_ACCESS_KEY_ID"
    exit -1
fi  

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Need to set -O AWS_SECRET_ACCESS_KEY"
    exit -1
fi  

if [ -z "$CLASSIC" -a -z "$VPC" ]; then
    echo "Need to set either Classic or VPC flag"
    exit -1
fi  

if [ -z "$INSTANCE_TYPE" ]; then
    echo "Need to set -t instance type"
    exit -1
fi  

#set optional params
if [ -z "$KEY_PAIR" ]; then
    key_pair_opts=''
else
    key_pair_opts="-k $KEY_PAIR"
fi  

if [ -z "$SECURITY_GROUP" ]; then
    security_group_opts=''
else
    security_group_opts="-g $SECURITY_GROUP"
fi  

if [ -z "$AVAILABILITY_ZONE" ]; then
    availability_zone_opts=''
else
    availability_zone_opts="-z $AVAILABILITY_ZONE"
fi
  
if [ $VPC -eq 1 ]; then
    if [ -z "$SUBNET" ]; then
        subnet_opts="-s $SUBNET"
    else
        subnet_opts=''
    fi
else
    subnet_opts=''
fi

if [ -z "$IAM_ROLE" ]; then
    iam_role_opts=''
else
    iam_role_opts="-p $IAM_ROLE"
fi
NUM_INSTANCES=${NUM_INSTANCES:-1}
REGION=${REGION:-us-east-1}



echo '==== Creating instance ===='
printf 'classic=<%d> vps=<%d> instance_type=<%s> ami_id=<%s>\n' "$CLASSIC" "$VPC" "$INSTANCE_TYPE" "$ami_id"

RESULT=`ec2-run-instances $ami_id -O $AWS_SECRET_ACCESS_KEY -W $AWS_ACCESS_KEY_ID -n $NUM_INSTANCES -t $INSTANCE_TYPE --region $REGION $security_group_opts $key_pair_opts $availability_zone_opts $subnet_opts $iam_role_opts`
if [ $? -ne 0 ]; then
    echo "Could not start the instance"
    exit 1	
fi

instance_id=$(echo $RESULT | cut -d ' ' -f6)

#set node name
if [ -n "$NODE_NAME" ]; then
    ec2-create-tags $instance_id  -O $AWS_SECRET_ACCESS_KEY -W $AWS_ACCESS_KEY_ID --tag Name=$NODE_NAME

fi
echo "==== Created instance $instance_id"
