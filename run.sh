#!/bin/bash

set -xeu

TARGET=$1

../jdk-26.0.2.1.jdk/Contents/Home/bin/java -jar ../Mars4_5.jar labs/${TARGET}/${TARGET}.asm nc
