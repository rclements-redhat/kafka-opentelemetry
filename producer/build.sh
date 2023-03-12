#!/usr/bin/env bash
set -x

### BASH directives ###

set -o errexit

### BASH VARIABLES ###

BASE_CONTAINER_NAME="eclipse-temurin"
BASE_CONTAINER_URL="docker.io/library/${BASE_CONTAINER_NAME}:latest"
APP_DIR="/opt/app"
APP_MAIN_JAR="producer.jar"
APP_AGENT_JAR="../opentelemetry-javaagent.jar"
APP_ENTRY_SCRIPT="producer.sh"
APP_ALL_FILES="${APP_MAIN_JAR} ${APP_AGENT_JAR} ${APP_ENTRY_SCRIPT}"

SIGNAL_OK=0
SIGNAL_ERROR=1

PROGRAM_NAME=${0}

DEFAULT_CONTAINER_TARGET_NAME="kafka-producer-otlp"
DEFAULT_CONTAINER_TARGET_TAG="latest"

ARG_PATTERN='--.*'

unset CONTAINER_TARGET_NAME
unset CONTAINER_TARGET_TAG

if [[ ! -z "${1}" ]];
then
  arg_type=""
  for arg in "$@"
  do
    case "${arg}" in

      # argument selector
      "--tag")
          arg_type="${arg}"
          set CONTAINER_TARGET_TAG
        ;;
      "--name")
          arg_type="${arg}"
          set CONTAINER_TARGET_NAME
        ;;

      # parameter
      *)
        echo "parameter"
        parameter="${arg}"
        case "${arg_type}" in
          "--name") CONTAINER_TARGET_NAME="${parameter}"; echo "setting ${arg_type} to ${parameter}";;
          "--tag") CONTAINER_TARGET_TAG="${parameter}"; echo "setting ${arg_type} to ${parameter}";;
        esac
    esac
  done

  if [[ -v CONTAINER_TARGET_NAME && -z ${CONTAINER_TARGET_NAME} ]];
  then
    echo "You used the --name parameter but did not provide a name."
    echo "USAGE: ${PROGRAM_NAME} --name <target container name>"
    exit ${SIGNAL_ERROR}
  fi
  if [[ -v CONTAINER_TARGET_TAG && -z ${CONTAINER_TARGET_TAG} ]];
  then
    echo "You used the --tag parameter but did not provide a tag."
    echo "USAGE: ${PROGRAM_NAME} --name <target container tag>"
    exit ${SIGNAL_ERROR}
  fi
fi

CONTAINER_TARGET_NAME=${DEFAULT_CONTAINER_TARGET_NAME}
CONTAINER_TARGET_TAG=${DEFAULT_CONTAINER_TARGET_TAG}

#CONTAINER_TARGET_NAME="${CONTAINER_TARGET_NAME-${DEFAULT_TARGET_CONTAINER_NAME}}"
#CONTAINER_TARGET_TAG="${CONTAINER_TARGET_TAG-${DEFAULT_TARGET_CONTAINER_TAG}}"

echo "Container Target Name: ${CONTAINER_TARGET_NAME}"
echo "Container Target Tag : ${CONTAINER_TARGET_TAG}"


## MAIN COMMANDS ###

existing_containers=$(buildah containers --format \"{{.ContainerName}}\")

container_array=($existing_containers)

for cnt in "${container_array[@]}"
do
  cnt=$(echo $cnt | tr -cd '[:alnum:]._-')
  if [[ "${cnt}" == ${BASE_CONTAINER_NAME}-working-container ]];
  then
    buildah rm "${BASE_CONTAINER_NAME}-working-container"
  fi
done

# Create container

container=$(buildah from "${BASE_CONTAINER_URL}")

# Create mount
mount=$(buildah mount "${container}")

# Make app dir
mkdir -p "${mount}${APP_DIR}"

# Copy main files
buildah copy "${container}" ${APP_MAIN_JAR} ${APP_AGENT_JAR} "${APP_DIR}"
buildah copy --chmod 777 "${container}" "${APP_ENTRY_SCRIPT}" "${APP_DIR}"
# Set working dir
buildah config --workingdir "${APP_DIR}" "${container}"

# Configure entrypoint
buildah config --entrypoint '[ "/bin/bash", "/opt/app/producer.sh" ]' "${container}"

# Save running container to image
buildah commit --format oci "${container}" "${CONTAINER_TARGET_NAME}:${CONTAINER_TARGET_TAG}"
