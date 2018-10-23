#!/bin/bash

sudo apt-get -y install python3-pip wget
sudo pip3 install awscli

export ENVIRONMENT=feat
export CLUSTER=core
export SERVICE_SUFFIX=$CIRCLE_BRANCH
export SERVICE1=reaction-core
export CONTAINER1=core
export core_CIRCLE_SHA1=$CIRCLE_SHA1

PROPEL_CONFIG_FILE="propel.yaml"
if [ ! -f ${PROPEL_CONFIG_FILE} ]; then
	echo "Propel configuration file not found!"
	exit 1
fi

if [ -z "${AWS_REGION}" ]; then
        export AWS_REGION=us-west-2
fi

ENV_NAME_UPPERCASE=$(echo $ENVIRONMENT | awk '{print toupper($0)}')
AWS_ACCESS_KEY_ID_VAR_NAME=CLOUDFORMATION_${ENV_NAME_UPPERCASE}_AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY_VAR_NAME=CLOUDFORMATION_${ENV_NAME_UPPERCASE}_AWS_SECRET_ACCESS_KEY

if [ "${!AWS_ACCESS_KEY_ID_VAR_NAME}" ]; then
	export AWS_ACCESS_KEY_ID=${!AWS_ACCESS_KEY_ID_VAR_NAME}
fi

if [ "${!AWS_SECRET_ACCESS_KEY_VAR_NAME}" ]; then
	export AWS_SECRET_ACCESS_KEY=${!AWS_SECRET_ACCESS_KEY_VAR_NAME}
fi

#mkdir -p ~/.aws
#echo "[default]" > ~/.aws/credentials
#echo "aws_access_key_id = ${AWS_ACCESS_KEY_ID}" >> ~/.aws/credentials
#echo "aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}" >> ~/.aws/credentials

#echo "[default]" > ~/.aws/config
#echo "region = ${AWS_REGION}" >> ~/.aws/config

echo Running aws s3 cp s3://${S3_PROPEL_ARTIFACTS_BUCKET}/propel-linux-amd64 ./propel
aws s3 cp s3://${S3_PROPEL_ARTIFACTS_BUCKET}/propel-linux-amd64 ./propel

sudo mv propel /usr/local/bin/propel
sudo chmod +x /usr/local/bin/propel

RELEASE_DESCRIPTION="CircleCI build URL: ${CIRCLE_BUILD_URL}"
propel param copy --env $ENVIRONMENT --cluster $CLUSTER --service $SERVICE1 --container $CONTAINER1 --suffix $SERVICE_SUFFIX --overwrite
propel param set ROOT_URL=https://${SERVICE1}-${SERVICE_SUFFIX}.$ENVIRONMENT.reactioncommerce.com/ --env $ENVIRONMENT --cluster $CLUSTER --service $SERVICE1 --container $CONTAINER1 --suffix $SERVICE_SUFFIX --overwrite
propel release create --deploy --env $ENVIRONMENT --cluster $CLUSTER --descr "${RELEASE_DESCRIPTION}" --service $SERVICE1 --suffix $SERVICE_SUFFIX

export SERVICE2=storefront
export CONTAINER2=storefront
propel param set CANONICAL_URL=https://${SERVICE1}-${SERVICE_SUFFIX}.$ENVIRONMENT.reactioncommerce.com --env $ENVIRONMENT --cluster $CLUSTER --service $SERVICE2 --container $CONTAINER2 --suffix $SERVICE_SUFFIX --overwrite
propel param set OAUTH2_REDIRECT_URL=https://${SERVICE2}-${SERVICE_SUFFIX}.$ENVIRONMENT.reactioncommerce.com/callback --env $ENVIRONMENT --cluster $CLUSTER --service $SERVICE2 --container $CONTAINER2 --suffix $SERVICE_SUFFIX --overwrite
propel param set OAUTH2_IDP_HOST_URL=https://${SERVICE1}-${SERVICE_SUFFIX}.$ENVIRONMENT.reactioncommerce.com --env $ENVIRONMENT --cluster $CLUSTER --service $SERVICE2 --container $CONTAINER2 --suffix $SERVICE_SUFFIX --overwrite
propel param set EXTERNAL_GRAPHQL_URL=https://${SERVICE1}-${SERVICE_SUFFIX}.$ENVIRONMENT.reactioncommerce.com/graphql-alpha --env $ENVIRONMENT --cluster $CLUSTER --service $SERVICE2 --container $CONTAINER2 --suffix $SERVICE_SUFFIX --overwrite
propel param set INTERNAL_GRAPHQL_URL=https://${SERVICE1}-${SERVICE_SUFFIX}.$ENVIRONMENT.reactioncommerce.com/graphql-alpha --env $ENVIRONMENT --cluster $CLUSTER --service $SERVICE2 --container $CONTAINER2 --suffix $SERVICE_SUFFIX --overwrite
propel release create --deploy --env $ENVIRONMENT --cluster $CLUSTER --descr "${RELEASE_DESCRIPTION}" -service $SERVICE2 --suffix $SERVICE_SUFFIX
