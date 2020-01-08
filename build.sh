#!/bin/bash
set -e

HELP=true
DEPLOY=false
BUILD=false
DEV=false
DEPLOY_ON=""
while (( "$#" )); do
  case "$1" in
    deploy)
      HELP=false
      DEPLOY=true
      shift 1
      ;;
    build)
      BUILD=true
      HELP=false
      shift 1
      ;;
    --dev)
        DEV=true
        shift 1
        ;;
    --help)
        HELP=true
        shift 1
        ;;
    --deploy-on)
        DEPLOY_ON="$2"
        shift 2
        ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

if ! $DEPLOY && ! $BUILD $$ !$EXTRACT; then
    HELP=true
fi

if $HELP; then cat <<-END
Usage:
------

Build or deploy the openwrt image

    build: Build openwrt inside a docker container
    deploy: Deploy the last built image on the --deploy-device
    extract: Extract the image from the docker image and place in the bin/ folder
    --dev: Build a openwrt docker image with some prebuilt tool to use make kernel_menuconfig
    --deploy-on /dev/sda: Flash the image on the device /dev/sda
    --help: Show this help
END
exit 0
fi

if $DEV; then
    IMAGE_NAME="openwrt-dev"
else
    IMAGE_NAME="openwrt"
fi

echo "Selecting image $IMAGE_NAME"
if $BUILD; then
    docker build -t $IMAGE_NAME .
    echo "Image $IMAGE_NAME successfully built"
fi

if $DEPLOY; then
    docker run --rm "--device=$DEPLOY_ON" $IMAGE_NAME deploy "$DEPLOY_ON"
    echo "Image $IMAGE_NAME successfully copied to $DEPLOY_ON"
fi

if $EXTRACT; then
    docker run --rm -v "$(pwd)/bin:/opt/bin" $IMAGE_NAME extract
    echo "Image successfully copied to bin/"
fi