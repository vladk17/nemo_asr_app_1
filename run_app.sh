#!/bin/bash
# Copyright (c) 2019, NVIDIA CORPORATION. All rights reserved.
################################################################################
# Run Application
################################################################################
INPUT_PORT=8888

# check if arguments supplied
if [ $# -eq 0 ]; then  # no arguments - ask for port and data dir
    # data dir
    read -e -p "Please enter the path to the data directory: " DATA_DIR
    # port
    read -e -p "Enter the port to run the container's jupyter notebooks (Press ENTER to use default port $INPUT_PORT):" NEW_INPUT_PORT
    if [ "$NEW_INPUT_PORT" ]; then
	INPUT_PORT=$NEW_INPUT_PORT
    fi
elif [ $# -eq 2 ]; then
     # arguments provide port and data dir
     INPUT_PORT=$1
     if [ "$#" -eq 2 ]; then
	 DATA_DIR=$2
     fi
else
    echo "Provide no arguments or 2 arguments: port and data_dir."
fi


USERNAME=`whoami`
USERID=`id -u $USERNAME`
GROUPNAME=docker
GROUPID=999

DATA_DIR="${DATA_DIR/#\~/$HOME}"
IMAGE_NAME='nemo_asr_app_img'
CONTAINER_NAME='run_nemo_asr_app_cont_'$USERNAME

# host IP for remote UI access 
HOST_IP=`hostname -I | awk '{print $1;}'`
UI_PORT=8060

# check port is not in use
while true; do
	(echo >/dev/tcp/localhost/$INPUT_PORT) &>/dev/null && echo "TCP port $INPUT_PORT is in use." || break
	read -e -p "Please enter a different port:" INPUT_PORT
done

# docker command
DOCKER_CMD=docker
if hash nvidia-docker 2>/dev/null; then
  DOCKER_CMD=nvidia-docker
fi

echo "Using $DOCKER_CMD"
echo "Container: $CONTAINER_NAME"
echo "Image: $IMAGE_NAME"
echo "Port: $INPUT_PORT"
echo "Data directory: $DATA_DIR"

# Build the application docker file
APP_DIR=. # path to application 
DOCKERFILEPATH="$APP_DIR"    
$DOCKER_CMD build -t $IMAGE_NAME \
	    --build-arg USER=$USERNAME \
            --build-arg UID=$USERID \
            --build-arg GROUP=$GROUPNAME \
            --build-arg GID=$GROUPID \
	    $DOCKERFILEPATH

# Clean out old containers
docker rm $(docker stop $(docker ps -a -q --filter status=exited)) 2>/dev/null
docker rm $(docker stop $(docker ps -a -q --filter ancestor=$CONTAINER_NAME))
docker rmi $(docker images -q -f "dangling=true") 2>/dev/null

ENTRY="jupyter lab --ip=0.0.0.0 --allow-root --no-browser --NotebookApp.token='' --NotebookApp.custom_display_url=http://$HOST_IP:$INPUT_PORT"
# To Run UI
#ENTRY="/bin/bash"
#python /tmp/nemo_asr_app/user_interface/app.py"

# Run command
$DOCKER_CMD run -it --rm --name $CONTAINER_NAME \
            --ipc=host \
	    --env UI_HOST_IP=$HOST_IP \
	    --env UI_PORT=$UI_PORT \
	    --env C_PORT=$INPUT_PORT \
	    --env DATA_DIR=$DATA_DIR \
	    -v $DATA_DIR:$DATA_DIR \
            -p $INPUT_PORT:8888 \
	    -p $UI_PORT:$UI_PORT \
            $IMAGE_NAME $ENTRY

# Clean up
find $APP_DIR -name \*.pyc -delete
echo "Done with ${IMAGE_NAME} service run"