#!/bin/bash
# run_ansible.sh - Automates deploying Ansible to the Master Node and running the playbook

# Adjust these variables if needed
KEY_PATH="/c/Users/KRIS/Downloads/ec2-key.pem"  # Use POSIX path for Git Bash
MASTER_IP="13.40.72.112"

echo "Using Key: $KEY_PATH"
echo "Master IP: $MASTER_IP"

# Check if key exists
if [ ! -f "$KEY_PATH" ]; then
    echo "Error: Key file not found at $KEY_PATH"
    exit 1
fi

echo "--- Step 1: Uploading Key and Ansible Files to Master Node ---"
# Upload Key (renaming to id_rsa for default usage)
scp -o StrictHostKeyChecking=no -i "$KEY_PATH" "$KEY_PATH" ubuntu@$MASTER_IP:~/.ssh/id_rsa
# Upload Ansible Directory
scp -o StrictHostKeyChecking=no -i "$KEY_PATH" -r infrastructure/ansible ubuntu@$MASTER_IP:~/ansible-setup

echo "--- Step 2: Configuring Master Node & Running Playbook ---"
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@$MASTER_IP << 'EOF'
    # Fix Key Permissions
    chmod 600 ~/.ssh/id_rsa

    # Install Ansible (if not installed)
    if ! command -v ansible &> /dev/null; then
        echo "Installing Ansible..."
        sudo apt-get update -y
        sudo apt-get install -y ansible
    else
        echo "Ansible is already installed."
    fi

    # Navigate to setup folder
    cd ~/ansible-setup

    # Update Inventory paths for Linux environment
    sed -i 's|C:/Users/KRIS/Downloads/ec2-key.pem|/home/ubuntu/.ssh/id_rsa|g' inventory.ini
    
    # Run Playbook
    echo "Running Ansible Playbook..."
    ansible-playbook -i inventory.ini playbook.yml
EOF

echo "--- Done! Kubernetes Cluster Setup Completed ---"
