#!/bin/bash

# install Verilator dependencies
sudo apt-get install -y help2man perl python3 make autoconf g++ flex bison ccache
sudo apt-get install -y libfl2  # Ubuntu only (ignore if gives error)
sudo apt-get install -y libfl-dev  # Ubuntu only (ignore if gives error)
