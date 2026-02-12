#!/bin/bash
LOG_DIR="/dataspace/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE="$LOG_DIR/dome_check_$TIMESTAMP.log"

echo "=== DOME MARKETPLACE DEEP CHECK ($TIMESTAMP) ===" > $FILE
echo "Namespace: marketplace" >> $FILE
echo "-------------------------------------------" >> $FILE

echo -e "\n[1] POD STATUS OVERVIEW" >> $FILE
kubectl get pods -n marketplace -o wide >> $FILE

echo -e "\n[2] SERVICE (DNS) MAPPING" >> $FILE
kubectl get svc -n marketplace >> $FILE

echo -e "\n[3] BAE LOGIC PROXY LOGS (Identity & TMF Connection)" >> $FILE
kubectl logs -l app=bae-marketplace -n marketplace --tail=200 >> $FILE

echo -e "\n[4] SCORPIO BROKER LOGS (Data Hub)" >> $FILE
kubectl logs -l app=scorpio -n marketplace --tail=100 >> $FILE

echo -e "\n[5] TMF PRODUCT CATALOG LOGS (Offerings)" >> $FILE
kubectl logs -l app=tmforum-product-catalog -n marketplace --tail=100 >> $FILE

echo -e "\n[6] TMF PARTY CATALOG LOGS (Users/Orgs)" >> $FILE
kubectl logs -l app=tmforum-party-catalog -n marketplace --tail=100 >> $FILE

echo -e "\n[7] INTERNAL CONNECTIVITY TEST (BAE to TMF)" >> $FILE
BAE_POD=$(kubectl get pod -l app=bae-marketplace -n marketplace -o name | head -n 1)
kubectl exec $BAE_POD -n marketplace -- curl -s -o /dev/null -w "TMF Product Catalog Status: %{http_code}\n" http://tmforum-product-catalog:8080/tmf-api/productCatalogManagement/v4/category >> $FILE 2>&1

echo -e "\n[8] DATABASE CONNECTIVITY" >> $FILE
kubectl exec $BAE_POD -n marketplace -- nc -zv mongodb-bae 27017 >> $FILE 2>&1

echo "--- CHECK COMPLETE ---" >> $FILE
echo "Bestand aangemaakt: $FILE"