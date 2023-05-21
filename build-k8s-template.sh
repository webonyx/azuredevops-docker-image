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

if [ -z "${NAME_SUFFIX}" ]; then
  echo "Error during running \"$0\": \"--namesuffix\" is required but was not set or set to the empty string. Exiting..."
  exit 1
fi

safename () {
  echo $(echo $1 | sed -e 's/[^A-Za-z0-9]//g')
}

KUSTOMIZE_BASED_PATH=${KUSTOMIZE_BASED_PATH:-k8s}
if [ ! -d "$KUSTOMIZE_BASED_PATH" ]; then
  echo "Kustomize based path does not exists"
  exit 1
fi

KUSTOMIZE_PATH=${KUSTOMIZE_BASED_PATH}/${OVERLAY:-template}
if [ ! -d "$KUSTOMIZE_PATH" ]; then
  KUSTOMIZE_PATH=${KUSTOMIZE_BASED_PATH}/template
  echo "[Warning] Overlay \"${OVERLAY}\" does not exists. Fallback to \"template\" overlay at \"${KUSTOMIZE_PATH}\""
fi


NAME_SUFFIX=$(safename ${NAME_SUFFIX})
SOURCE_IMAGE=${SOURCE_IMAGE:-"unifiedselfserviceeastus2crsb2qrpxc.azurecr.io/dataset"}

cd $KUSTOMIZE_PATH
kustomize edit set namesuffix -- "-${NAME_SUFFIX}"

if [ -n "${IMAGE}" ]; then
  echo "Override image with: \"${IMAGE}\""
  kustomize edit set image "${SOURCE_IMAGE}=${IMAGE}"
fi

echo "Building template..."
kustomize build . > k8s.yaml

echo "##vso[task.setvariable variable=MANIFEST_PATH]${KUSTOMIZE_PATH}/k8s.yaml"
