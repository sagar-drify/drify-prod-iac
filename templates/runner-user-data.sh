#!/bin/bash
set -euxo pipefail
exec > >(tee -a /var/log/runner-bootstrap.log) 2>&1

dnf install -y git tar gzip xz jq libicu krb5-libs openssl-libs zlib gcc-c++ make python3

id runner >/dev/null 2>&1 || useradd --create-home --shell /bin/bash runner
mkdir -p /opt/actions-runner
cd /opt/actions-runner

RUNNER_VERSION=$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/^v//')
curl -fsSL -o runner.tar.gz \
  "https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"
tar -xzf runner.tar.gz
rm -f runner.tar.gz
./bin/installdependencies.sh || true
chown -R runner:runner /opt/actions-runner

# Registration needs a short-lived token and is done afterwards through SSM.
touch /var/lib/runner-bootstrap-complete
