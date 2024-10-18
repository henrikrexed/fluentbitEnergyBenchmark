#!/usr/bin/env bash

################################################################################
### Script deploying the Observ-K8s environment
### Parameters:
### version: the fluentbit version to deploy ( v2 or v3)
################################################################################


### Pre-flight checks for dependencies
if ! command -v jq >/dev/null 2>&1; then
    echo "Please install jq before continuing"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Please install git before continuing"
    exit 1
fi


if ! command -v helm >/dev/null 2>&1; then
    echo "Please install helm before continuing"
    exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
    echo "Please install kubectl before continuing"
    exit 1
fi
echo "parsing arguments"
while [ $# -gt 0 ]; do
  case "$1" in
  --version)
    VERSION="$2"
   shift 2
    ;;
  *)
    echo "Warning: skipping unsupported option: $1"
    shift
    ;;
  esac
done
echo "Checking arguments"

if [ -z "$VERSION" ]; then
  echo "Error: version is not set!"
  exit 1
fi

OLDIP=$(kubectl get svc istio-ingressgateway -n istio-system -ojson | jq -j '.status.loadBalancer.ingress[].ip')


## delete the current environment
kubectl delete -f istio/istio_gateway.yaml

if [  "$VERSION" = 'v3' ]; then
  kubectl delete -f opentelemetry/deploy_1_11_v2.21.yaml -n otel-demo
  kubectl delete -f hipstershop/k8s-manifest.yaml -n hipster-shop
  kubectl delete -f opentelemetry/openTelemetry-manifest_statefulset.yaml
  kubectl delete -f opentelemetry/openTelemetry-manifest_statefulset_2.21.yaml
  kubectl delete -f opentelemetry/openTelemetry-manifest_statefulset.yaml
  kubectl delete -f fluentbit/fluent_2.21.yaml -n fluentbit
  kubectl delete -f fluentbit/pipeline/v2.2.1/fluentbit.yaml -n fluentbit
else
  kubectl delete -f opentelemetry/deploy_1_11_v3.19.yaml -n otel-demo
  kubectl delete -f opentelemetry/openTelemetry-manifest_statefulset_3.19.yaml
  kubectl delete -f fluentbit/pipeline/v3.19/fluentbit.yaml -n fluentbit
  kubectl delete -f fluentbit/fluent_3.19.yaml -n fluentbit
fi
istioctl uninstall
sed -i "s,$OLDIP,IP_TO_REPLACE," opentelemetry/deploy_1_11_v2.21.yaml
sed -i "s,$OLDIP,IP_TO_REPLACE," opentelemetry/deploy_1_11_v3.19.yaml
sed -i "s,$OLDIP,IP_TO_REPLACE," istio/istio_gateway.yaml
sed -i "s,$OLDIP,IP_TO_REPLACE," hipstershop/k8s-manifest.yaml
sed -i "s,$OLDIP,IP_TO_REPLACE," hipstershop/loadtest_job.yaml
sed -i "s,$OLDIP,IP_TO_REPLACE," opentelemetry/loadtest_job.yaml
sed -i "s,$OLDIP,IP_TO_REPLACE,"  keptn/keptnTask.yaml

#Deploy istio
if [  "$VERSION" = 'v3' ]; then
  istioctl install -f istio/istio-operator_3.19.yaml --skip-confirmation
else
  istioctl install -f istio/istio-operator.yaml --skip-confirmation
fi
### get the ip adress of ingress ####
IP=""
while [ -z $IP ]; do
  echo "Waiting for external IP"
  IP=$(kubectl get svc istio-ingressgateway -n istio-system -ojson | jq -j '.status.loadBalancer.ingress[].ip')
  [ -z "$IP" ] && sleep 10
done
echo 'Found external IP: '$IP
sed -i "s,IP_TO_REPLACE,$IP," opentelemetry/deploy_1_11_v2.21.yaml
sed -i "s,IP_TO_REPLACE,$IP," opentelemetry/deploy_1_11_v3.19.yaml
sed -i "s,IP_TO_REPLACE,$IP," istio/istio_gateway.yaml
sed -i "s,IP_TO_REPLACE,$IP," hipstershop/k8s-manifest.yaml
sed -i "s,IP_TO_REPLACE,$IP," hipstershop/loadtest_job.yaml
sed -i "s,IP_TO_REPLACE,$IP," opentelemetry/loadtest_job.yaml
sed -i "s,IP_TO_REPLACE,$IP," keptn/keptnTask.yaml
# Deploy collector
echo "Deploying the collector"
if [  "$VERSION" = 'v3' ]; then
  kubectl apply -f  opentelemetry/openTelemetry-manifest_statefulset_3.19.yaml
  kubectl apply -f fluentbit/pipeline/v3.19/fluentbit.yaml -n fluentbit
  kubectl apply -f fluentbit/fluent_3.19.yaml -n fluentbit
else
  kubectl apply -f oopentelemetry/penTelemetry-manifest_statefulset_2.21.yaml
  kubectl apply -f opentelemetry/openTelemetry-manifest_statefulset.yaml
  kubectl apply -f fluentbit/fluent_2.21.yaml -n fluentbit
  kubectl apply -f fluentbit/pipeline/v2.2.1/fluentbit.yaml -n fluentbit
fi

#deploy demo application
echo "Deploying hipster-shop"
kubectl apply -f hipstershop/k8s-manifest.yaml -n hipster-shop

#Deploy oteldemo
echo "Deploying oteldemo"
if [  "$VERSION" = 'v3' ]; then
  kubectl apply -f opentelemetry/deploy_1_11_v3.19.yaml -n otel-demo
else
  kubectl apply -f opentelemetry/deploy_1_11_v2.21.yaml -n otel-demo
fi

kubectl apply -f istio/istio_gateway.yaml


echo "--------------Demo--------------------"
echo "url of the demo: "
echo "otel-demo : http://oteldemo.$IP.nip.io"
echo "hipstershop url: http://hipstershop.$IP.nip.io"
echo "========================================================"