#!/usr/bin/env bash
while true; do 
read -p "Do you want to do saml login? " yn
case $yn in 
	[Yy]* ) saml2aws --role=arn:aws:iam::141380700111:role/Phi login -a prod -p prod --force --disable-keychain; break;;
	[Nn]*) echo "Okay, no login for you!"; break;;
	*) echo "Please answer yes or no.";;
esac
done
export BIOPORTAL_URL=http://knowledge.dev.syapse.com
export BIOPORTAL_ACCESS_KEY=526573c8-67c5-4da1-a853-9f62dad0b5a3
export BIOPORTAL_PORT=8080
export IAM_ENABLED=False
if [ "$1" == "prod" ]
then
	env=""
	export S3_BUCKET_NAME=syapse-prod-knowledge
else
	env="-${1}"
	export S3_BUCKET_NAME=syapse-prod-knowledge${env}
fi
aws_api_response=$(aws sts assume-role --role-arn arn:aws:iam::141380700111:role/data_lake_knowledge${env}_full --role-session-name $(whoami)$1) 
export AWS_ACCESS_KEY_ID=$(jq '.Credentials.AccessKeyId' <<< $aws_api_response | tr -d '"')
export AWS_SECRET_ACCESS_KEY=$(jq '.Credentials.SecretAccessKey' <<< $aws_api_response | tr -d '"')
export AWS_SESSION_TOKEN=$(jq '.Credentials.SessionToken' <<< $aws_api_response | tr -d '"')
