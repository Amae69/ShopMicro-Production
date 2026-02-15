# Running Ansible on Windows

Ansible **does not run natively on Windows**. The error `ansible-playbook: command not found` confirms this. You have two main options to proceed:

## Option A: Use WSL (Windows Subsystem for Linux) - Recommended

If you have WSL installed (e.g., Ubuntu on Windows), you can run Ansible from there.

1.  **Open WSL Terminal** (e.g., Ubuntu).
2.  **Install Ansible**:
    ```bash
    sudo apt update
    sudo apt install -y ansible
    ```
3.  **Navigate to your project**:
    Your Windows drives are mounted at `/mnt/c/`.
    ```bash
    cd /mnt/c/Users/KRIS/Desktop/t4dev-capstone/infrastructure/ansible
    ```
4.  **Fix Private Key Permissions**:
    Linux requires strict permissions (600) for SSH keys, which doesn't work well on `/mnt/c`. Copy your key to the Linux filesystem:
    ```bash
    mkdir -p ~/.ssh
    cp /mnt/c/Users/KRIS/Downloads/ec2-key.pem ~/.ssh/
    chmod 600 ~/.ssh/ec2-key.pem
    ```
5.  **Update Inventory (`inventory.ini`)**:
    Change the `ansible_ssh_private_key_file` path to the Linux path:
    ```ini
    ansible_ssh_private_key_file=~/.ssh/ec2-key.pem
    ```
6.  **Run Playbook**:
    Because `/mnt/c` is "world writable" in WSL, Ansible ignores `ansible.cfg`. Run with this command instead:
    ```bash
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini playbook.yml
    ```

---

## Option B: Run from the Master Node (The "Jump Host" Method)

You can use your **Kubernetes Master Node** (which is Linux) to run Ansible and configure itself and the worker nodes.

1.  **Copy Files with SCP**:
    Run these commands from your **Git Bash** (local Windows):
    ```bash
    # Variable for your Key Path (update if needed)
    KEY_PATH="C:/Users/KRIS/Downloads/ec2-key.pem"
    MASTER_IP="13.40.72.112"

    # Copy the Key to Master (renaming to id_rsa for default usage)
    scp -i "$KEY_PATH" "$KEY_PATH" ubuntu@$MASTER_IP:~/.ssh/id_rsa

    # Copy Ansible folder to Master
    scp -i "$KEY_PATH" -r infrastructure/ansible ubuntu@$MASTER_IP:~/ansible-setup
    ```

2.  **SSH into Master Node**:
    ```bash
    ssh -i "$KEY_PATH" ubuntu@$MASTER_IP
    ```

3.  **Setup Ansible on Master (Run inside SSH)**:
    ```bash
    # Fix Key Permissions
    chmod 600 ~/.ssh/id_rsa

    # Install Ansible
    sudo apt update && sudo apt install -y ansible

    # Go to folder
    cd ~/ansible-setup
    ```

4.  **Update Inventory on Master**:
    Edit `inventory.ini` using `nano`:
    ```bash
    nano inventory.ini
    ```
    Change the key path to:
    ```ini
    ansible_ssh_private_key_file=/home/ubuntu/.ssh/id_rsa
    ```
    *(Ctrl+O to save, Ctrl+X to exit)*

5.  **Run Playbook**:
    ```bash
    ansible-playbook -i inventory.ini playbook.yml
    ```
