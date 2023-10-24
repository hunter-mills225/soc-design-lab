#!/bin/bash

# Gather path information relative to the invocation name(symlink)
#
BUILD_PATH=$( realpath $( dirname "${0}" ) )
PROJECT_PATH=$( dirname "${BUILD_PATH}" )
PROJECT_NAME=$( basename "${PROJECT_PATH}" )

# Display some sanity check info to the user
#
echo "PROJECT: ${PROJECT_NAME}"
echo "ROOT: ${PROJECT_PATH}"

pushd "${BUILD_PATH}" 1>/dev/null
vivado -nolog -nojournal "${PROJECT_NAME}/${PROJECT_NAME}".xpr &
popd 1>/dev/null
