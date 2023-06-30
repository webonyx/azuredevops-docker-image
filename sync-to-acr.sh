#!/usr/bin/env bash

ACR_NAME=${ACR_NAME:-unifiedselfserviceeastus2crsb2qrpxc}
docker pull webonyx/azuredevops-toolbox:latest --platform amd64
docker tag webonyx/azuredevops-toolbox:latest $ACR_NAME.azurecr.io/toolbox:latest
docker push $ACR_NAME.azurecr.io/toolbox:latest
