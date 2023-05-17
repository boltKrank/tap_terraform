#!/bin/bash
export TAP_VERSION=""
export ACR_NAME=""
wget https://go.dev/dl/go1.20.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.20.1.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
git clone https://github.com/boltKrank/imgpkg.git
cd $HOME/imgpkg
$HOME/imgpkg/hack/build.sh
sudo cp $HOME/imgpkg/imgpkg /usr/local/bin/imgpkg
imgpkg copy -b registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle:${TAP_VERSION} --to-repo ${ACR_NAME}.azurecr.io/tanzu-cluster-essentials/cluster-essentials-bundle --include-non-distributable-layers
imgpkg copy -b registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:${TAP_VERSION} --to-repo ${ACR_NAME}.azurecr.io/tanzu-application-platform/tap-packages --include-non-distributable-layers