#!/bin/bash

while getopts G:Q:R: flag

do
        case "${flag}" in

                G) GIT_CREDENTIALS=${OPTARG}                
                        ;;
                Q) QUAY_CREDENTIALS=${OPTARG}
                        ;;
                R) RH_CREDENTIALS=${OPTARG}
                        ;;                        
                *) exit 0;
                ;;
        esac
done

# Git Repository
GIT_USERNAME=${GIT_CREDENTIALS%:*}
GIT_PASSWORD=${GIT_CREDENTIALS#*:}

# Quay Image Registry
QUAY_USERNAME=${QUAY_CREDENTIALS%:*}
QUAY_PASSWORD=${QUAY_CREDENTIALS#*:}

# Red Hat Image Registry
RH_USERNAME=${RH_CREDENTIALS%:*}
RH_PASSWORD=${RH_CREDENTIALS#*:}




# Application demo-integration-backend
oc new-project demo-integration-dev
oc project demo-integration-dev

## Credentials to download of demo-integration-backend image
oc apply -f ./secrets/quay-io-credentials.yml 
oc secrets link default quay-io-credentials --for=pull
oc apply -f ./secrets/quay-io-credentials.yml 

## Database of demo-integration-backend
oc new-app --template=mysql-persistent \
-p MYSQL_USER=admin \
-p MYSQL_PASSWORD=admin \
-p MYSQL_DATABASE=demointegrationdb \
-p MYSQL_ROOT_PASSWORD=root  \
-p MYSQL_VERSION=8.0-el8 \
-p VOLUME_CAPACITY=1Gi \
-p MEMORY_LIMIT=512Mi

# Pipeline settings

## Allow ArgoCD syncronize 
oc policy add-role-to-user admin system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n demo-integration-dev

## Tekton Definitions
oc new-project demo-integration-pipeline
oc project demo-integration-pipeline

oc apply -f ./tasks/
oc apply -f ./triggers/
oc apply -f pipeline.yaml
oc apply -f shared-workspace.pvc.yml

oc apply -f ./secrets/quay-io-credentials.yml 
oc patch serviceaccount pipeline  -p '{"secrets": [{"name": "quay-io-credentials"}]}'

oc apply -f ./secrets/gitlab-credentials.yml 
oc patch serviceaccount pipeline  -p '{"secrets": [{"name": "gitlab-credentials"}]}'

oc apply -f ./secrets/redhat-registry-credentials.yml
oc patch serviceaccount pipeline  -p '{"secrets": [{"name": "redhat-registry-credentials"}]}'

