#!/usr/bin/env bash

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --overlay)
      OVERLAY="$2"
      shift # past argument
      shift # past value
      ;;
    --namesuffix)
      NAME_SUFFIX="$2"
      shift # past argument
      shift # past value
      ;;
    --image)
      IMAGE="$2"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

KUSTOMIZE_BASED_PATH=${KUSTOMIZE_BASED_PATH:-k8s}
KUSTOMIZE_PATH=${KUSTOMIZE_BASED_PATH}/${OVERLAY:-template}
isTemplate=false

if [ ! -d "$KUSTOMIZE_BASED_PATH" ]; then
  echo "Expected Kustomize based path at \"$KUSTOMIZE_BASED_PATH\" does not exists"
  exit 1
fi

if [ -z "$OVERLAY" ] || [ ! -d "$KUSTOMIZE_PATH" ]; then
  KUSTOMIZE_PATH=${KUSTOMIZE_BASED_PATH}/template
  isTemplate=true
  echo "[Warning] Build using \"template\" overlay at \"${KUSTOMIZE_PATH}\""
fi

if [ "true" == "$isTemplate" ] && [ -z "${NAME_SUFFIX}" ]; then
  echo "Error running \"$0\": \"--namesuffix\" is required but was not set or set to the empty string. Exiting..."
  exit 1
fi

safename () {
  echo $(echo $1 | sed -e 's/[^A-Za-z0-9]//g')
}

NAME_SUFFIX=$(safename ${NAME_SUFFIX})
SOURCE_IMAGE=${SOURCE_IMAGE:-"unifiedselfserviceeastus2crsb2qrpxc.azurecr.io/dataset"}

# start editing
cd $KUSTOMIZE_PATH

# Only set namesuffix for template overlay
if [ "true" == $isTemplate ]; then
  kustomize edit set namesuffix -- "-${NAME_SUFFIX}"
fi

if [ -n "${IMAGE}" ]; then
  echo "Override image with: \"${IMAGE}\""
  kustomize edit set image "${SOURCE_IMAGE}=${IMAGE}"
fi

echo "Building template..."
kustomize build . > k8s.yaml

MANIFEST_PATH="${KUSTOMIZE_PATH}/k8s.yaml"
echo "##vso[task.setvariable variable=MANIFEST_PATH]${MANIFEST_PATH}"
echo "Exported: MANIFEST_PATH=${MANIFEST_PATH}"
