# Fluentbit Energy usage Benchmark
This repository contains all the files required to compare the energy consumption of Fluentbit v2 and v3

<p align="center"><img src="/image/fluentibt.png" width="70%" alt="fluentbit logo" /></p>

## Prerequisite 
The following tools need to be install on your machine :
- jq
- kubectl
- git
- gcloud ( if you are using GKE)
- Helm

### 1.Create a Google Cloud Platform Project
```shell
PROJECT_ID="<your-project-id>"
gcloud services enable container.googleapis.com --project ${PROJECT_ID}
gcloud services enable monitoring.googleapis.com \
cloudtrace.googleapis.com \
clouddebugger.googleapis.com \
cloudprofiler.googleapis.com \
--project ${PROJECT_ID}
```
### 2.Create a GKE cluster
```shell
ZONE=europe-west3-a
NAME=fluentbit-benchmark
gcloud container clusters create ${NAME} --zone=${ZONE} --machine-type=e2-standard-8 --num-nodes=2
```
### 3.Istio

1. Download Istioctl
```shell
curl -L https://istio.io/downloadIstio | sh -
```
This command download the latest version of istio ( in our case istio 1.18.2) compatible with our operating system.
2. Add istioctl to you PATH
```shell
cd istio-1.23.2
```
this directory contains samples with addons . We will refer to it later.
```shell
export PATH=$PWD/bin:$PATH
```


### 5.Clone Github repo
```shell
git clone https://github.com/henrikrexed/fluentbitEnergyBenchmark
cd fluentbitEnergyBenchmark
```


### 6. Dynatrace 
##### 1. Dynatrace Tenant - start a trial
If you don't have any Dynatrace tenant , then i suggest to create a trial using the following link : [Dynatrace Trial](https://bit.ly/3KxWDvY)
Once you have your Tenant save the Dynatrace (including https) tenant URL in the variable `DT_TENANT_URL` (for example : https://dedededfrf.live.dynatrace.com)
```shell
DT_TENANT_URL=<YOUR TENANT URL>
```
##### 2. Create the Dynatrace API Tokens
The dynatrace operator will require to have several tokens:
* Token to deploy and configure the various components
* Token to ingest metrics and Traces


###### Operator Token
One for the operator having the following scope:
* Create ActiveGate tokens
* Read entities
* Read Settings
* Write Settings
* Access problem and event feed, metrics and topology
* Read configuration
* Write configuration
* Paas integration - installer downloader
<p align="center"><img src="/image/operator_token.png" width="40%" alt="operator token" /></p>

Save the value of the token . We will use it later to store in a k8S secret
```shell
API_TOKEN=<YOUR TOKEN VALUE>
```
###### Ingest data token
Create a Dynatrace token with the following scope:
* Ingest metrics (metrics.ingest)
* Ingest logs (logs.ingest)
* Ingest events (events.ingest)
* Ingest OpenTelemetry
* Read metrics
<p align="center"><img src="/image/data_ingest_token.png" width="40%" alt="data token" /></p>
Save the value of the token . We will use it later to store in a k8S secret

```shell
DATA_INGEST_TOKEN=<YOUR TOKEN VALUE>
```

### 6. Run the deployment script

#### a. run the Fluentbit v2 environment
```shell
cd ..
chmod 777 deployment.sh
VERSION=v2
./deployment.sh  --clustername "${NAME}" --dturl "${DT_TENANT_URL}" --dtingesttoken "${DATA_INGEST_TOKEN}" --dtoperatortoken "${API_TOKEN}" --version "${VERSION}"
```

Run the argo Workflow for a quick 30min validation:
```shell
kubectl apply -f keptn/argoworkflow.yaml -n argo
```
or run the complete 2hours load test:
```shell
kubectl apply -f opentelemetry/loadtest_job_v2.yaml -n otel-demo
kubectl apply -f hipstershop/loadtest_job.yaml -n hipster-shop
```


#### b. run the Fluentbit v3 environment
```shell
cd ..
chmod 777 updateversion.sh
VERSION=v3
./updateversion.sh --version "${VERSION}"
```

Run the argo Workflow for the quick 30min validation:
```shell
kubectl apply -f keptn/argoworkflow.yaml -n argo
```
or run the complete 2hours load test:
```shell
kubectl apply -f opentelemetry/loadtest_job.yaml -n otel-demo
kubectl apply -f hipstershop/loadtest_job.yaml -n hipster-shop
```
