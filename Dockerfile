# Copyright (c) 2019, NVIDIA CORPORATION. All rights reserved.
################################################################################
# Application Container
################################################################################
# Copyright (c) 2019, NVIDIA CORPORATION. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################
# Use NGC
#-------------------------------------------------------------------------------
FROM nvcr.io/nvidia/pytorch:19.11-py3 
################################################################################

################################################################################
# Install system modules
#-------------------------------------------------------------------------------
RUN apt-get update -y
RUN apt-get install -y libboost-all-dev swig
RUN apt-get install -y sox libsox-fmt-mp3
RUN apt-get install -y python-setuptools
################################################################################

################################################################################
# Install Python modules
#-------------------------------------------------------------------------------
# Install EasyDict
RUN pip install easydict 

# UI installs
RUN pip install --upgrade setuptools
RUN pip install wheel dash dash-daq dash-bootstrap-components

# NeMo install 
RUN git clone https://github.com/NVIDIA/nemo /tmp/NeMo \
    && cd /tmp/NeMo/ \
    && ./reinstall.sh
    
# To install reqs for language model uncomment the following lines
#RUN apt-get install -y swig
#RUN cd /tmp/NeMo/scripts && \
#    ./install_decoders.sh

# Copy NeMo ASR application 
COPY . /tmp/nemo_asr_app/
################################################################################
# Create folder structure and enviroment variables
#-------------------------------------------------------------------------------
ENV APP_DIR /tmp/nemo_asr_app

ENV WORK_DIR ${APP_DIR}/notebooks
ENV PYTHONPATH "${PYTHONPATH}:/tmp/NeMo:${APP_DIR}"
################################################################################

################################################################################
# Set paths and user
#------------------------------------------------------------------------------
# Set user
ARG USER
ARG UID
ARG GROUP
ARG GID
RUN adduser --disabled-password --gecos '' --uid $UID $USER && \
    addgroup --system --gid $GID $GROUP && \
    adduser $USER $GROUP && \
    adduser $USER sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN chown -R ${USER}:${USER} /tmp
USER $USER

# Ports
ENV NOTEBOOK_PORT 8888
EXPOSE ${NOTEBOOK_PORT}

# Working directory
WORKDIR ${WORK_DIR}