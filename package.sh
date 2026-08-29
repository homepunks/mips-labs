#!/bin/bash

set -xeu

source .env
LAB=$1
NUM=${LAB#lab}
NUM=${NUM#0}

cp "labs/${LAB}/${LAB}.asm" "submit/${NAME}_${SURNAME}_lab${NUM}.asm"
