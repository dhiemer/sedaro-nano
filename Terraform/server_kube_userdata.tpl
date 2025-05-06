#!/bin/bash

# === PARAMETERS ===
GITHUB_TOKEN="${registration_token}"

# === CONFIGURATION ===
GITHUB_URL="https://github.com/dhiemer/sedaro-nano"
RUNNER_USER="actions"
INSTALL_DIR="/home/$RUNNER_USER/actions-runner"

# === SYSTEM PREP ===
sudo yum update -y
sudo yum install -y tar dotnet-runtime-6.0 lttng-ust openssl-libs krb5-libs zlib

# === FIX LOCALE ENVIRONMENT ===
echo "export LANG=en_US.UTF-8" | sudo tee -a /etc/profile.d/locale.sh
echo "export LC_ALL=en_US.UTF-8" | sudo tee -a /etc/profile.d/locale.sh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# === CREATE USER AND DIRECTORY ===
if ! id -u $RUNNER_USER >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash $RUNNER_USER
fi

sudo mkdir -p $INSTALL_DIR
sudo chown $RUNNER_USER:$RUNNER_USER $INSTALL_DIR
cd $INSTALL_DIR

# === DOWNLOAD AND EXTRACT GITHUB RUNNER ===
curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v2.315.0/actions-runner-linux-x64-2.315.0.tar.gz
tar xzf actions-runner.tar.gz
rm -f actions-runner.tar.gz
sudo chown -R $RUNNER_USER:$RUNNER_USER $INSTALL_DIR

# === INSTALL DEPENDENCIES FOR RUNNER ===
sudo ./bin/installdependencies.sh

# === CONFIGURE GITHUB RUNNER ===
sudo -u $RUNNER_USER ./config.sh --unattended \
  --url $GITHUB_URL \
  --token $GITHUB_TOKEN \
  --name k3s-runner-1 \
  --labels self-hosted,SEDARO \
  --work _work \
  --replace

# === CREATE SYSTEMD SERVICE ===
cat <<EOF | sudo tee /etc/systemd/system/github-runner.service
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
Environment=LANG=en_US.UTF-8
Environment=LC_ALL=en_US.UTF-8
ExecStart=$INSTALL_DIR/run.sh
WorkingDirectory=$INSTALL_DIR
User=$RUNNER_USER
Restart=always
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

# === ENABLE AND START RUNNER SERVICE ===
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now github-runner

echo "✅ GitHub runner systemd service started..."

# === OPTIONAL: Add user to docker group if Docker is present ===
if command -v docker &> /dev/null; then
  sudo usermod -aG docker $RUNNER_USER
fi

# === INSTALL K3s ===
curl -sfL https://get.k3s.io | sh -


# Give read access to the runner user for the kubeconfig file
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
sudo chown $RUNNER_USER:$RUNNER_USER /etc/rancher/k3s/k3s.yaml


# === CONFIGURE ECR AUTH FOR K3s ===
cat <<EOF | sudo tee /etc/rancher/k3s/registries.yaml
mirrors:
  "032021926264.dkr.ecr.us-east-1.amazonaws.com":
    endpoint:
      - "https://032021926264.dkr.ecr.us-east-1.amazonaws.com"

configs:
  "032021926264.dkr.ecr.us-east-1.amazonaws.com":
    auth:
      username: AWS
      password: "$(aws ecr get-login-password --region us-east-1)"
EOF

# Restart K3s to pick up ECR auth
sudo systemctl restart k3s
