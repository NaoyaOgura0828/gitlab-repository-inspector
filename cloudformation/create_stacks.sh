#!/bin/bash

cd $(dirname $0)

# 各システム名定義
SYSTEM_NAME_TEMPLATE=inspector

# 各環境名定義
ENV_TYPE_DEV=dev
ENV_TYPE_STG=stg
ENV_TYPE_PROD=prod

# 各リージョン名定義
REGION_NAME_TOKYO=tokyo
REGION_NAME_OSAKA=osaka
REGION_NAME_VIRGINIA=virginia

create_stack() {
    SYSTEM_NAME=$1
    ENV_TYPE=$2
    REGION_NAME=$3
    SERVICE_NAME=$4

    aws cloudformation create-stack \
        --stack-name ${SYSTEM_NAME}-${ENV_TYPE}-${SERVICE_NAME} \
        --template-body file://./templates/${SERVICE_NAME}/${SERVICE_NAME}.yml \
        --cli-input-json file://./templates/${SERVICE_NAME}/${ENV_TYPE}-${REGION_NAME}-parameters.json \
        --profile ${SYSTEM_NAME}-${ENV_TYPE}-${REGION_NAME}

    aws cloudformation wait stack-create-complete \
        --stack-name ${SYSTEM_NAME}-${ENV_TYPE}-${SERVICE_NAME} \
        --profile ${SYSTEM_NAME}-${ENV_TYPE}-${REGION_NAME}

}

update_lambda_script() {
    SYSTEM_NAME=$1
    ENV_TYPE=$2
    REGION_NAME=$3
    LAMBDA_FUNCTION_NAME=$4
    ECR_IMAGE_URI=$5

    AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
        --query 'Account' \
        --output text \
        --profile ${SYSTEM_NAME}-${ENV_TYPE}-${REGION_NAME})

    BUCKET_NAME=${SYSTEM_NAME}-${ENV_TYPE}-s3-lambda-code-${AWS_ACCOUNT_ID}

    aws lambda update-function-code \
        --function-name ${SYSTEM_NAME}-${ENV_TYPE}-lambda-${LAMBDA_FUNCTION_NAME} \
        --image-uri ${ECR_IMAGE_URI} \
        --no-cli-pager \
        --profile ${SYSTEM_NAME}-${ENV_TYPE}-${REGION_NAME}

    aws lambda wait function-updated-v2 \
        --function-name ${SYSTEM_NAME}-${ENV_TYPE}-lambda-${LAMBDA_FUNCTION_NAME} \
        --profile ${SYSTEM_NAME}-${ENV_TYPE}-${REGION_NAME}
}

#####################################
# 構築対象リソース
#####################################
# create_stack ${SYSTEM_NAME_TEMPLATE} ${ENV_TYPE_DEV} ${REGION_NAME_VIRGINIA} iam-role
# create_stack ${SYSTEM_NAME_TEMPLATE} ${ENV_TYPE_DEV} ${REGION_NAME_TOKYO} parameterstore
# create_stack ${SYSTEM_NAME_TEMPLATE} ${ENV_TYPE_DEV} ${REGION_NAME_TOKYO} sns
# create_stack ${SYSTEM_NAME_TEMPLATE} ${ENV_TYPE_DEV} ${REGION_NAME_TOKYO} ecr
# create_stack ${SYSTEM_NAME_TEMPLATE} ${ENV_TYPE_DEV} ${REGION_NAME_TOKYO} lambda
# create_stack ${SYSTEM_NAME_TEMPLATE} ${ENV_TYPE_DEV} ${REGION_NAME_TOKYO} eventbridge-schedule
# create_stack ${SYSTEM_NAME_TEMPLATE} ${ENV_TYPE_DEV} ${REGION_NAME_TOKYO} dynamodb
# update_lambda_script ${SYSTEM_NAME_TEMPLATE} ${ENV_TYPE_DEV} ${REGION_NAME_TOKYO} gitlab-repository-inspector 597299534728.dkr.ecr.ap-northeast-1.amazonaws.com/gitlabchangelogs:2024-04-28
# create_stack ${SYSTEM_NAME_TEMPLATE} ${ENV_TYPE_DEV} ${REGION_NAME_TOKYO} s3
# create_stack ${SYSTEM_NAME_TEMPLATE} ${ENV_TYPE_DEV} ${REGION_NAME_TOKYO} codebuild
# create_stack ${SYSTEM_NAME_TEMPLATE} ${ENV_TYPE_DEV} ${REGION_NAME_TOKYO} codepipeline
# create_stack ${SYSTEM_NAME_TEMPLATE} ${ENV_TYPE_DEV} ${REGION_NAME_TOKYO} eventbridge-rule

exit 0
