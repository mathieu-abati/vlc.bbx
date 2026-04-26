#!/bin/bash
set -e

# Include BuildBox API
source buildbox_utils.sh

vlc_src_dir="$(bb_get_package_src_dir vlc)"
pushd "${vlc_src_dir}"
export DISPLAY=:0
./bin/vlc &
popd
