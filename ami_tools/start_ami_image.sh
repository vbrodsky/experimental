#!/bin/bash -x
show_help() {
cat << EOF
Usage: ${0##*/} [-hCV] -t [INSTANCE_TYPE] -W [AWS_ACCESS_KEY_ID] -O [AWS_SECRET_ACCESS_KEY] -s [SECURITY_GROUP] -S [SUBNET] -a [AVAILABILITY_GROUP] -I [IAM_ROLE] -N [NODE_NAME] [ami-id]
This program creates an instance from AMI   
 
    -h          		display this help and exit
    -C 				classic AWS network
    -V				VPC
    -t INSTANCE_TYPE		valid AWS instance size, i.e. m3.large, etc.
    -W AWS_ACCESS_KEY_ID	AWS access key id
    -O AWS_SECRET_ACCESS_KEY 	AWS secret access key
    -s SECURITY_GROUP		AWS security group
    -S SUBNET
    -a AVAILABILITY_GROUP
    -I IAM_ROLE
    -N NODE_NAME

EOF
}                

# Initialize our own variables:
output_file=""
verbose=0

OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts ":hCVt:W:O:s:S:a:I:N:" opt $AMI_ID; do
    case "$opt" in
        h)
            show_help
            exit 0
            ;;
        v)  verbose=$((verbose+1))
            ;;
        f)  output_file=$OPTARG
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
shift "$((OPTIND-1))" # Shift off the options and optional --.

printf 'verbose=<%d>\noutput_file=<%s>\nLeftovers:\n' "$verbose" "$output_file"
printf '<%s>\n' "$@"

