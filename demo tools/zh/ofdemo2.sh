#!/bin/bash

LOG_FILE="./openfunction.log"
TASK=""
STEP=""
TIMEOUT="5m"
LINE=`printf "%0.s-" {1..100}`

handleWelcome() {
  printf "%0.s#" {1..104} 
  printf "\n"
  printf "\t\t* 欢迎使用 OpenFunction 快速演示工具！ \n"
  printf "\t\t* 它将按照以下步骤搭建一个 OpenFunction 演示环境：\n"
  printf "\t\t* \- 1. 使用 Kind 创建名为 ‘openfunction’ 的集群\n"
  printf "\t\t* \- 2. 安装 OpenFunction 的依赖组件\n"
  printf "\t\t* \- 3. 准备 Knative 网关（使用 Kind ip 作为外部地址）\n"
  printf "\t\t* \- 4. 安装 OpenFunction\n"
  printf "\t\t* \- 5. 创建一个案例函数\n"
  printf "\t\t* 注：请确保在使用工具前做好以下准备事项：\n"
  printf "\t\t* \- 1. kubectl(>=v1.20.0) 位于你的 PATH 路径下\n"
  printf "\t\t* \- 2. kind(>=v0.11.0) 位于你的 PATH 路径下\n"
  printf "\t\t* \- 3. go(>=1.15) 位于你的 PATH 路径下\n"
  printf "\t\t* \- 4. docker(>=19.3.8) 位于你的 PATH 路径下\n"
  printf "\t\t* 注: 工具运行时会将日志输出到当前目录的 ‘openfunction.log’ 文件中，\n"
  printf "\t\t* \t你可以使用 ‘tail -f openfunction.log’ 来监听日志的输出。\n"
  printf "%0.s#" {1..104} "\n"
  printf "\n"
}

handleTaskOrStepStart() {
  printf "\e[6;30;42m %s %s [%s]\033[0m\r" "$1" "${LINE:${#1}:0-${#2}}" "$2"
}

handleTaskException() {
  printf "\e[8;30;41m %s %s [失败]\033[0m\n" "$1" "${LINE:${#1}:0-6}"
  printf "\e[8;30;43m 请检查 openfunction.log 以获取详细的异常信息。\033[0m\n"

  if [ -n "$2" ];then
    printf "\e[8;30;43m 异常发生在步骤： %s\033[0m\n" "$2"
  fi

  exit 1
}

handleTaskSuccess() {
  printf "\e[6;30;42m %s %s [就绪]\033[0m\n" "$1" "${LINE:${#1}:0-2}"
}

resetLogFile() {
  > $LOG_FILE
}

handleResult() {
  printf "* 你可以使用以下命令触发函数： *\n"
  printf "\033[3m\e[5;34;40m curl "$1"\033[0m\n"
  printf "* 正常情况下，结果将如下所示： *\n"
  printf "\033[3m\e[5;34;40m Hello, World!\033[0m\n"
}

resetLogFile
handleWelcome

##################################################
# TASK - Create cluster && switch to the cluster #
##################################################
TASK="创建 openfunction 集群"
handleTaskOrStepStart "$TASK" "处理中"
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
TASK="安装依赖组件"
STEP="下载并执行 deploy.sh"
handleTaskOrStepStart "$TASK" "$STEP" 
wget -qO - https://raw.githubusercontent.com/OpenFunction/OpenFunction/main/hack/deploy.sh | bash -s -- --all --poor-network >> $LOG_FILE 2>&1
if [ $? -ne 0 ];then
  handleTaskException "$TASK" "$STEP"
fi

# Wait for dependencies ready
# cert-manager
STEP="等待 cert-manager 工作负载就绪"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "cert-manager" "cert-manager-cainjector" "cert-manager-webhook";do
  timeout $TIMEOUT kubectl rollout status -n cert-manager deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

# dapr-system
STEP="等待 dapr-system 工作负载就绪"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "dapr-operator" "dapr-sentry" "dapr-sidecar-injector";do
  timeout $TIMEOUT kubectl rollout status -n dapr-system deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

# keda
STEP="等待 keda 工作负载就绪"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "keda-metrics-apiserver" "keda-operator";do
  timeout $TIMEOUT kubectl rollout status -n keda deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

# knative-serving
STEP="等待 knative-serving 工作负载就绪"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "activator" "autoscaler" "controller" "domain-mapping" "domainmapping-webhook" "net-kourier-controller" "webhook";do
  timeout $TIMEOUT kubectl rollout status -n knative-serving deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

# kourier-system
STEP="等待 kourier-system 工作负载就绪"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "3scale-kourier-gateway";do
  timeout $TIMEOUT kubectl rollout status -n kourier-system deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

# shipwright-build
STEP="等待 shipwright-build 工作负载就绪"
handleTaskOrStepStart "$TASK" "$STEP" 
for deploy in "shipwright-build-controller";do
  timeout $TIMEOUT kubectl rollout status -n shipwright-build deployment $deploy >> $LOG_FILE 2>&1
  if [ $? -ne 0 ];then
    handleTaskException "$TASK" "$STEP"
  fi
done

# tekton-pipelines
STEP="等待 tekton-pipelines 工作负载就绪"
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
TASK="配置 Knative 网关"
handleTaskOrStepStart "$TASK" "处理中"

NODE_IP=`docker exec -it openfunction-control-plane sh -c "ip addr | grep eth0$ | grep -Eo 'inet ([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | tr -d '\n'"`

STEP="更新 External 地址"
handleTaskOrStepStart "$TASK" "$STEP" 
kubectl patch svc -n kourier-system kourier \
  -p "{\"spec\": {\"type\": \"LoadBalancer\", \"externalIPs\": [\"$NODE_IP\"]}}" >> $LOG_FILE 2>&1
if [ $? -ne 0 ];then
  handleTaskException "$TASK" "$STEP"
fi

STEP="更新 Magic DNS"
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
TASK="部署 OpenFunction"
handleTaskOrStepStart "$TASK" "处理中"

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

STEP="安装 OpenFunction"
handleTaskOrStepStart "$TASK" "$STEP" 
kubectl create -f https://github.com/OpenFunction/OpenFunction/releases/download/v0.4.0/bundle.yaml >> $LOG_FILE 2>&1
if [ $? -ne 0 ];then
  handleTaskException "$TASK" "$STEP"
fi

STEP="等待 openfunction 工作负载就绪"
handleTaskOrStepStart "$TASK" "$STEP" 
timeout $TIMEOUT kubectl rollout status -n openfunction deployment openfunction-controller-manager >> $LOG_FILE 2>&1
if [ $? -ne 0 ];then
  handleTaskException "$TASK" "$STEP"
fi

handleTaskSuccess "$TASK"

########################################
# TASK - Run demo (a Knative function) #
########################################
TASK="运行案例（Knative 函数）"
handleTaskOrStepStart "$TASK" "处理中"

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

STEP="创建案例函数"
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