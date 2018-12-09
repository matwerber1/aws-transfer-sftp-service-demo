#!/bin/bash

#CHANGE THESE FIELDS...
BUCKET_NAME=YOUR_S3_BUCKET
FTP_ADMIN_PUBLICKEY="YOUR_PUBLIC_KEY"

# Optional - change the CloudFormation stack name or the FTP service's Name tag
STACK_NAME=sftp-demo
SERVER_NAME_TAG=sftp-demo
FTP_ADMIN_USERNAME=admin

REGION=$(aws configure get region)

#-------------------------------------------------------------------------------
echo "Deploying prerequisites for SFTP service to CloudFormation stack $STACK_NAME..."

aws cloudformation package \
    --template-file template.yaml \
    --s3-bucket $BUCKET_NAME \
    --output-template-file packaged-template.yaml

aws cloudformation deploy \
    --template-file packaged-template.yaml \
    --stack-name $STACK_NAME \
    --capabilities CAPABILITY_IAM

  
#-------------------------------------------------------------------------------
echo ""
echo "Checking whether SFTP service tagged with Name=$SERVER_NAME_TAG exists..."

# Get full server ARN 
SERVER_ARN=$(aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Name,Values=sftp-demo \
  --resource-type-filters "transfer" \
  --query 'ResourceTagMappingList[0].ResourceARN' \
  --output text)


if [[ $SERVER_ARN == 'None' ]]; then
  
  # Role used by SFTP service to log to CloudWatch  
  LOGGING_ROLE_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`TransferLogRoleArn`].OutputValue' --output text)

  echo "Service does not exist; creating new SFTP service..."
  #create a server with identities managed by / within the transfer service
  aws transfer create-server \
    --identity-provider-type SERVICE_MANAGED \
    --logging-role $LOGGING_ROLE_ARN \
    --tags Key=Name,Value=$SERVER_NAME_TAG \
    --query 'ServerId' \
    --output text
    
else
  echo "SFTP service already exists."
fi

echo ""

# Get full server ARN 
SERVER_ARN=$(aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Name,Values=sftp-demo \
  --resource-type-filters "transfer" \
  --query 'ResourceTagMappingList[0].ResourceARN' \
  --output text)

# parse the ARN to find the server ID
SERVER_ID=$(echo $SERVER_ARN | cut -d'/' -f 2)

# determine the SFTP DNS endpoint
SFTP_ENDPOINT=$SERVER_ID.server.transfer.$REGION.amazonaws.com

TRANSFER_BUCKET_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`TransferBucketArn`].OutputValue' --output text)

echo "S3 Transfer Bucket = $TRANSFER_BUCKET_ARN"
echo "SFTP Endpoint = $SFTP_ENDPOINT"
echo ""

TRANSFER_USER_ROLE_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`TransferUserRoleArn`].OutputValue' --output text)

aws transfer describe-user --server-id "$SERVER_ID" --user-name $FTP_ADMIN_USERNAME >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "Admin user = $FTP_ADMIN_USERNAME"
else
  echo "Creating admin user '$FTP_ADMIN_USERNAME'..."
  aws transfer create-user \
    --role "$TRANSFER_USER_ROLE_ARN" \
    --server-id $SERVER_ID \
    --ssh-public-key-body "$FTP_ADMIN_PUBLICKEY" \
    --tags Key=Role,Value=Administrator \
    --user-name $FTP_ADMIN_USERNAME \
    --home-directory '/home/$FTP_ADMIN_USERNAME' \
    >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "User created successfully!"
  fi
fi