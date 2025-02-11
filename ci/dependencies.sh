#!/bin/bash
sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
        software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
        python3.9 \
        python3.9-venv \
        python3.9-dev \
        python3-pip \
        build-essential \
        libssl-dev \
        libffi-dev \
        ca-certificates \
        curl \
        git \
        openssh-client

update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1 && \
    update-alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3 1

# install cocotb and testing dependencies
pip3 install cocotb
pip3 install cocotb_bus
pip3 install scapy
pip3 install fusesoc
pip3 install pytest



