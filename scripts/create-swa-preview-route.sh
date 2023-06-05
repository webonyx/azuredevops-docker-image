#!/usr/bin/env bash

SUBSCRIPTION=8c135cf8-4843-4d61-9260-56f35f6ca745
PROFILE_NAME=AtlasCDN-NPRD
RESOURCE_GROUP=unified-eastus2-stage-webapp-rg
ENDPOINT_NAME=preview
CUSTOM_DOMAINS=atlas-preview-att-com

############################################

DEFAULT_FLAGS="--subscription $SUBSCRIPTION --profile-name $PROFILE_NAME --resource-group $RESOURCE_GROUP"
ORIGIN_HOST=$(echo ${AZURESTATICWEBAPP_STATIC_WEB_APP_URL:-$AZURESTATICWEBAPP1_STATIC_WEB_APP_URL} | sed 's|https://||')
ROUTE_NAME="${BUILD_REPOSITORY_NAME}--$(echo $BUILD_SOURCEBRANCHNAME | sed 's|[\._]|-|g')"

echo "Checking if origin group exists"
if [ $(az afd origin-group show $DEFAULT_FLAGS --origin-group-name $ROUTE_NAME --output tsv | wc -l) -eq 0 ]; then
	echo "Creating origin group..."

	az afd origin-group create $DEFAULT_FLAGS \
		--origin-group-name $ROUTE_NAME \
		--probe-request-type HEAD \
		--probe-protocol Http \
		--probe-interval-in-seconds 100 \
		--probe-path / \
		--sample-size 4 \
		--successful-samples-required 3 \
		--additional-latency-in-milliseconds 50

		sleep 10
else
	echo "[skip] Origin group already exists"
fi

echo "Checking if origin exists"
if [ $(az afd origin list $DEFAULT_FLAGS --origin-group-name $ROUTE_NAME --output tsv | wc -l) -eq 0 ]; then
	echo "Creating origin..."

	az afd origin create $DEFAULT_FLAGS \
		--host-name $ORIGIN_HOST \
		--origin-host-header $ORIGIN_HOST \
		--origin-group-name $ROUTE_NAME \
		--origin-name $ROUTE_NAME \
		--priority 1 \
		--weight 500 \
		--enabled-state Enabled \
		--http-port 80 \
		--https-port 443

		sleep 10
else
	echo "[skip] Origin already exists"
fi

echo "Checking if route exists"
if [ $(az afd route show $DEFAULT_FLAGS --endpoint-name $ENDPOINT_NAME --route-name $ROUTE_NAME --output tsv | wc -l) -eq 0 ]; then
	echo "Creating route..."

	az afd route create $DEFAULT_FLAGS \
		--endpoint-name $ENDPOINT_NAME \
		--route-name $ROUTE_NAME \
		--patterns-to-match "/${ROUTE_NAME}" "/${ROUTE_NAME}/*" \
		--origin-group $ROUTE_NAME \
		--origin-path / \
		--supported-protocols Http Https \
		--custom-domains $CUSTOM_DOMAINS \
		--forwarding-protocol MatchRequest \
		--https-redirect Enabled
else
	echo "[skip] Route already exists"
fi