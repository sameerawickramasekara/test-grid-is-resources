#!/bin/bash
# ------------------------------------------------------------------------
#
# Copyright 2016 WSO2, Inc. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

# ------------------------------------------------------------------------

export KUBERNETES_MASTER=$1
default_port=32111

prgdir=$(dirname "$0")
script_path=$(cd "$prgdir"; pwd)
common_scripts_folder=$(cd "${script_path}/../common/scripts/"; pwd)
source "${common_scripts_folder}/base.sh"

while getopts :h FLAG; do
    case $FLAG in
        h)
            showUsageAndExitDefault
            ;;
        \?)
            showUsageAndExitDefault
            ;;
    esac
done
export KUBERNETES_MASTER=$1
kubectl create secret docker-registry registrykey --docker-server=$2 --docker-username=$3 --docker-password=$4 --docker-email=$5

validateKubeCtlConfig

bash $script_path/../common/wso2-shared-dbs/deploy.sh

# deploy DB service and rc
echo "Deploying IS database Service..."
kubectl create -f "mysql-isdb-service.yaml"

echo "Deploying IS database Replication Controller..."
kubectl create -f "mysql-isdb-controller.yaml"

# wait till mysql is started
# TODO: find a better way to do this
sleep 30
export KUBERNETES_MASTER=$1
default "${default_port}"
export KUBERNETES_MASTER=$1
pods=$(kubectl get pods --output=jsonpath={.items..metadata.name})
echo "========================================="
json='{ "hosts" : ['
for pod in $pods; do
         hostip=$(kubectl get pods "$pod" --output=jsonpath={.status.hostIP})
         echo $hostip
         lable=$(kubectl get pods "$pod" --output=jsonpath={.metadata.labels.name})
         echo $lable
         servicedata=$(kubectl describe svc "$lable")
         echo $servicedata
         json+='{"ip" :"'$hostip'", "label" :"'$lable'", "ports" :['
         declare -a dataarray=($servicedata)
         let count=0
         for data in ${dataarray[@]}  ; do
            if [ "$data" = "NodePort:" ]; then
            IFS='/' read -a myarray <<< "${dataarray[$count+2]}"
            json+='{'
            json+='"protocol" :"'${dataarray[$count+1]}'",  "portNumber" :"'${myarray[0]}'"'
            json+="},"
            fi

         ((count+=1))
         done
         i=$((${#json}-1))
         lastChr=${json:$i:1}

         if [ "$lastChr" = "," ]; then
         json=${json:0:${#json}-1}
         fi

         json+="]},"

done
export KUBERNETES_MASTER=$1
json=${json:0:${#json}-1}

json+="]}"
export KUBERNETES_MASTER=$1
echo $json;

cat > $script_path/deployment.json << EOF1
$json
EOF1
