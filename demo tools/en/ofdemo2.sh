#!/bin/bash

LOG_FILE="./openfunction.log"
TASK=""
STEP=""
TIMEOUT="5m"
LINE=`printf "%0.s-" {1..100}`

handleWelcome() {
  printf "%0.s#" {1..104} 
  printf "\n"
  printf "\t\t* Welcome to the OpenFunction QuickStart Tool! \n"
  printf "\t\t* It will build an OpenFunction demo environment by following steps:\n"
  printf "\t\t* \- 1. Create a cluster named 'openfunction' by Kind\n"
  printf "\t\t* \- 2. Install OpenFunction's dependencies\n"
  printf "\t\t* \- 3. Prepare Knative gateway (use Kind ip as External address)\n"
  printf "\t\t* \- 4. Install OpenFunction\n"
  printf "\t\t* \- 5. Create a sample function\n"
  printf "\t\t* Note: Preparations need to be made before running the script:\n"
  printf "\t\t* \- 1. kubectl(>=v1.20.0) in your PATH\n"
  printf "\t\t* \- 2. kind(>=v0.11.0) in your PATH\n"
  printf "\t\t* \- 3. go(>=1.15) in your PATH\n"
  printf "\t\t* \- 4. docker(>=19.3.8) in your PATH\n"
  printf "\t\t* Note: It will output the log to the 'openfunction.log' file under the current path,\n"
  printf "\t\t* \tand you can watch the log by execute 'tail -f openfunction.log'.\n"
  printf "%0.s#" {1..104} "\n"
  printf "\n"
}

handleTaskOrStepStart() {
  printf "\e[6;30;42m %s %s [%s]\033[0m\r" "$1" "${LINE:${#1}:0-${#2}}" "$2"
}

handleTaskException() {
  printf "\e[8;30;41m %s %s [Failed]\033[0m\n" "$1" "${LINE:${#1}:0-6}"
  printf "\e[8;30;43m Please check the openfunction.log for detailed exception information.\033[0m\n"

  if [ -n "$2" ];then
    printf "\e[8;30;43m The exception occurs in step: %s\033[0m\n" "$2"
  fi

  exit 1
}

handleTaskSuccess() {
  printf "\e[6;30;42m %s %s [UP]\033[0m\n" "$1" "${LINE:${#1}:0-2}"
}

resetLogFile() {
  > $LOG_FILE
}

handleResult() {
  printf "* You can use the following command to trigger the function: *\n"
  printf "\033[3m\e[5;34;40m curl "$1"\033[0m\n"
  printf "* If everything is OK, you will see the following output information: *\n"
  printf "\033[3m\e[5;34;40m Hello, World!\033[0m\n"
}

resetLogFile
handleWelcome

##################################################
# TASK - Create cluster && switch to the cluster #
##################################################
TASK="Create cluster OpenFunction"
handleTaskOrStepStart "$TASK" "In progress"
kind create cluster --name openfunction >> $LOG_FILE 2>&1
if [ $? -ne 0 ];then
  handleTaskException "$TASK"
fi
kubectl config use-context kind-openfunction >> $LOG_FILE 2>&1
if [ $? -ne 0 ];then
  handleTaskException "$TASK"
fi
handleTaskSuccess "$TASK"

##########################################
# TASK - Install dependent components #
##########################################
TASK="Installing dependent components"
STEP="Download and execute the deploy.sh"
handleTaskOrStepStart "$TASK" "$STEP" 
wget -qO - https://raw.githubusercontent.com/OpenFunction/OpenFunction/main/hack/deploy.sh | bash -s -- --all >> $LOG_FILE 2>&1
if [ $? -ne 0 ];then
  handleTaskException "$TASK" "$STEP"
fi

# Wait for dependencies ready
# cert-manager
STEP="Rollout status of cert-manager"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "cert-manager" "cert-manager-cainjector" "cert-manager-webhook";do
  timeout $TIMEOUT kubectl rollout status -n cert-manager deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

# dapr-system
STEP="Rollout status of dapr-system"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "dapr-operator" "dapr-sentry" "dapr-sidecar-injector";do
  timeout $TIMEOUT kubectl rollout status -n dapr-system deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

# keda
STEP="Rollout status of keda"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "keda-metrics-apiserver" "keda-operator";do
  timeout $TIMEOUT kubectl rollout status -n keda deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

# knative-serving
STEP="Rollout status of knative-serving"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "activator" "autoscaler" "controller" "domain-mapping" "domainmapping-webhook" "net-kourier-controller" "webhook";do
  timeout $TIMEOUT kubectl rollout status -n knative-serving deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

# kourier-system
STEP="Rollout status of kourier-system"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "3scale-kourier-gateway";do
  timeout $TIMEOUT kubectl rollout status -n kourier-system deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

# shipwright-build
STEP="Rollout status of shipwright-build"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "shipwright-build-controller";do
  timeout $TIMEOUT kubectl rollout status -n shipwright-build deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

# tekton-pipelines
STEP="Rollout status of tekton-pipelines"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "tekton-pipelines-controller" "tekton-pipelines-webhook";do
  timeout $TIMEOUT kubectl rollout status -n tekton-pipelines deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

handleTaskSuccess "$TASK"

############################################
# TASK - Prepare Knative Gateway (Kourier) #
############################################
TASK="Prepare Knative Gateway (Kourier)"
handleTaskOrStepStart "$TASK" "In progress"

NODE_IP=`docker exec -it openfunction-control-plane sh -c "ip addr | grep eth0$ | grep -Eo 'inet ([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | tr -d '\n'"`

STEP="Patch external ip"
handleTaskOrStepStart "$TASK" "$STEP" 
kubectl patch svc -n kourier-system kourier \
  -p "{\"spec\": {\"type\": \"LoadBalancer\", \"externalIPs\": [\"$NODE_IP\"]}}" >> $LOG_FILE 2>&1
if [ $? -ne 0 ];then
  handleTaskException "$TASK" "$STEP"
fi

STEP="Patch magic dns"
handleTaskOrStepStart "$TASK" "$STEP" 
kubectl patch configmap/config-domain -n knative-serving \
  --type merge --patch "{\"data\":{\"$NODE_IP.sslip.io\":\"\"}}" >> $LOG_FILE 2>&1
if [ $? -ne 0 ];then
  handleTaskException "$TASK" "$STEP"
fi

handleTaskSuccess "$TASK"

#############################
# TASK - Setup OpenFunction #
#############################
TASK="Setup OpenFunction"
handleTaskOrStepStart "$TASK" "In progress"

# Wait up to 10s for the cert-manager-webhook.cert-manager.svc.cluster.local to be ready
COUNTER=0
while [ $COUNTER -lt 10 ]
do
  COUNTER='expr $COUNTER+1'
  STATUS=`kubectl get po -n cert-manager -l app.kubernetes.io/name=webhook -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>&1`
  if [ $STATUS == "true" ];then
    break
  fi
  sleep 1
done

STEP="Install OpenFunction"
handleTaskOrStepStart "$TASK" "$STEP" 
kubectl create -f https://github.com/OpenFunction/OpenFunction/releases/download/v0.4.0/bundle.yaml >> $LOG_FILE 2>&1
if [ $? -ne 0 ];then
  handleTaskException "$TASK" "$STEP"
fi

STEP="Rollout status of openfunction"
handleTaskOrStepStart "$TASK" "$STEP" 
timeout $TIMEOUT kubectl rollout status -n openfunction deployment openfunction-controller-manager >> $LOG_FILE 2>&1
if [ $? -ne 0 ];then
  handleTaskException "$TASK" "$STEP"
fi

handleTaskSuccess "$TASK"

########################################
# TASK - Run demo (a Knative function) #
########################################
TASK="Run demo (a Knative function)"
handleTaskOrStepStart "$TASK" "In progress"

# Wait up to 10s for the OpenFunction to be ready
COUNTER=0
while [ $COUNTER -lt 10 ]
do
  COUNTER='expr $COUNTER+1'
  STATUS=`kubectl get po -n openfunction -l control-plane=controller-manager -o jsonpath='{.items[0].status.containerStatuses[1].ready}' 2>&1`
  if [ $STATUS == "true" ];then
    break
  fi
  sleep 1
done

STEP="Create sample function"
handleTaskOrStepStart "$TASK" "$STEP" 

cat <<EOF | kubectl apply --server-side=true -f - >> $LOG_FILE 2>&1
apiVersion: core.openfunction.io/v1alpha2
kind: Function
metadata:
  name: function-sample
spec:
  version: "v1.0.0"
  image: "openfunctiondev/sample-go-func:latest"
  port: 8080 # default to 8080
  serving:
    runtime: Knative
    template:
      containers:
        - name: function
          imagePullPolicy: Always
EOF

if [ $? -ne 0 ];then
  handleTaskException "$TASK" "$STEP"
fi

handleTaskSuccess "$TASK"

printf "%0.s#" {1..104}
printf "\n"

# Wait up to 30s for the function to be ready
COUNTER=0
while [ $COUNTER -lt 30 ]
do
  COUNTER='expr $COUNTER+1'
  STATUS=`kubectl get ksvc -l openfunction.io/serving=$(kubectl get functions function-sample -o jsonpath='{.status.serving.resourceRef}') -o jsonpath='{.items[0].status.conditions[2].status}' 2>&1`
  if [[ $STATUS = "True" ]];then
    break
  fi
  sleep 1
done

ENDPOINT=`kubectl get ksvc -l openfunction.io/serving=$(kubectl get functions function-sample -o jsonpath='{.status.serving.resourceRef}') -o jsonpath='{.items[0].status.url}'`
handleResult "$ENDPOINT"