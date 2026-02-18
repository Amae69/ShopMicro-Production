## Infrastructure Provisioning (Terraform)

### Prerequisites

I already have the following:
- AWS Account
- AWS CLI installed in my local machine. Run to check: `aws --version`
- Terraform installed in my local machine. Run to check: `terraform version`

![terraform version](./images/checked%20terraform%20version%20.png)

In my AWS Account, I created an access key and secret key for terraform to use.

![access key](./images/aws%20access%20key.png)

Then I configure the aws cli to use the access key and secret key.

`aws configure`

![aws configure](./images/aws%20configure.png)

### Steps

1. Goto the terraform folder and Initialize Terraform

```bash
cd infrastructure/terraform
terraform init
```

![terraform init](./images/terraform%20init.png)

2. Apply Terraform `terraform apply`

![terraform apply](./images/terraform%20apply.png)

![aws console](./images/aws%20console.png)

## Configuration setup (Ansible)

### Prerequisites

I already have the following:
- Ansible installed in my local machine via wsl. Run to check: `ansible --version`

![ansible installed](./images/ansible%20installed.png)

### Steps

1. Goto the ansible folder and update the inventory file `cd infrastructure/ansible`

![ansible inventory](./images/ansible%20inventory.png)

Create a playbook to setup kubernetes cluster on the EC2 instances.

```
---
- name: Kubernetes Common Configuration
  hosts: all
  become: yes
  tasks:
    - name: Disable swap
      shell: |
        swapoff -a
        sed -i '/ swap / s/^/#/' /etc/fstab

    - name: Load kernel modules
      copy:
        content: |
          overlay
          br_netfilter
        dest: /etc/modules-load.d/k8s.conf

    - name: Modprobe modules
      shell: |
        modprobe overlay
        modprobe br_netfilter

    - name: Apply sysctl params
      copy:
        content: |
          net.bridge.bridge-nf-call-iptables  = 1
          net.bridge.bridge-nf-call-ip6tables = 1
          net.ipv4.ip_forward                 = 1
        dest: /etc/sysctl.d/k8s.conf

    - name: Apply sysctl
      command: sysctl --system

    - name: Install dependencies
      apt:
        name:
          - ca-certificates
          - curl
          - gnupg
          - lsb-release
          - apt-transport-https 
        state: present
        update_cache: yes

    - name: Add Docker GPG key
      shell: |
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
        chmod a+r /etc/apt/keyrings/docker.gpg

    - name: Add Docker repository
      shell: |
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    - name: Install containerd
      apt:
        name: containerd.io
        state: present
        update_cache: yes

    - name: Configure containerd
      shell: |
        mkdir -p /etc/containerd
        containerd config default | tee /etc/containerd/config.toml
        sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
      notify: restart containerd

    - name: Add Kubernetes GPG key
      shell: |
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg --yes

    - name: Add Kubernetes repository
      shell: |
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

    - name: Install Kubernetes components
      apt:
        name:
          - kubelet
          - kubeadm
          - kubectl
        state: present
        update_cache: yes

    - name: Hold Kubernetes packages
      shell: apt-mark hold kubelet kubeadm kubectl

  handlers:
    - name: restart containerd
      service:
        name: containerd
        state: restarted
        enabled: yes

- name: Master Node Setup
  hosts: masters
  become: yes
  tasks:
    - name: Initialize Kubernetes Control Plane
      command: kubeadm init --pod-network-cidr=192.168.0.0/16
      register: kubeadm_output
      ignore_errors: yes # Ignore if already initialized

    - name: Setup kubeconfig for ubuntu user
      shell: |
        mkdir -p /home/ubuntu/.kube
        cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
        chown $(id -u ubuntu):$(id -g ubuntu) /home/ubuntu/.kube/config

    - name: Install Calico Network Plugin
      command: kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml --kubeconfig=/etc/kubernetes/admin.conf

    - name: Generate join command
      command: kubeadm token create --print-join-command
      register: join_command_raw

    - name: Set join command fact
      set_fact:
        join_command: "{{ join_command_raw.stdout }}"

    - name: Save join command to local file (for debugging/reference)
      local_action: copy content="{{ join_command_raw.stdout }}" dest=./join_command.sh
      become: no

    - name: Add dummy host to store join command for workers
      add_host:
        name: "K8S_TOKEN_HOLDER"
        join_command: "{{ join_command_raw.stdout }}"

- name: Worker Node Setup
  hosts: workers
  become: yes
  tasks:
    - name: Join Cluster
      shell: "{{ hostvars['K8S_TOKEN_HOLDER']['join_command'] }}"
      args:
        executable: /bin/bash
      when: hostvars['K8S_TOKEN_HOLDER'] is defined
```

2. Run the playbook `ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini playbook.yml`

![ansible playbook run](./images/ansible%20playbook%20run.png)

3. Check the status of the cluster `kubectl get nodes`

![kubectl get nodes](./images/get%20nodes.png)

On my GitHub, I created a repository named ShopMicro-Production and added my kube congig data and AWS access key and secret key as secrets in the repository settings.

On ks8 master node i run `cat ~/.kube/config` to get the kube config data and paste it in the repository settings secrets.

![github secret](./images/github%20secret.png)

## CI/CD Pipeline Implementation
I implemented a complete GitHub Actions workflow suite:

- ci.yml
: Triggers on Push/PR. Runs linting (Node/Python), Unit Tests, and builds/pushes Docker images to GHCR.

![ci.yml](./images/ci%20pipeline%20success.png)

- cd.yml
: Triggers after CI success on main. Deploys the application to my Kubernetes cluster.

![cd.yml](./images/cd.yml.png)

- iac-ci.yml
: Runs terraform fmt, terraform validate, tflint, and OPA policy checks on infrastructure changes.

- drift-detection.yml
: Runs daily at 8am to check for infrastructure drift. Status: ✅ Implemented. Requires Secrets setup in GitHub.

![drift detection](./images/infrastructure%20drift%20detection.png)