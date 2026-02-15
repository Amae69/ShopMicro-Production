# ShopMicro EC2 Setup Guide

This guide details how to set up the ShopMicro project on an AWS EC2 instance.

## 1. Launch EC2 Instance

1.  **Login to AWS Console** and navigate to **EC2**.
2.  **Launch Instance**:
    - **Name**: `ShopMicro-Server`
    - **AMI**: Ubuntu Server 24.04 LTS (HVM), SSD Volume Type
    - **Instance Type**: `t2.medium` (recommended) or `t2.micro` (minimum, might be slow for builds/k8s).
    - **Key Pair**: Create a new one (e.g., `shopmicro-key`) and download the `.pem` file.
    - **Network Settings**:
        - Create a security group allowing:
            - **SSH (22)**: My IP (or Anywhere)
            - **HTTP (80)**: Anywhere
            - **Custom TCP (8080)**: Anywhere (Backend)
            - **Custom TCP (3000)**: Anywhere (Frontend)
            - **Custom TCP (5000)**: Anywhere (ML Service)
            - **HTTPS (443)**: Anywhere (Optional)
    - **Storage**: 20GB+ gp3 (Docker images take space).

3.  **Launch** and wait for the instance to be "Running".

## 2. Connect to Instance

Use SSH to connect. Replace `path/to/key.pem` and `public-ip` with your details.

```bash
chmod 400 shopmicro-key.pem
ssh -i "shopmicro-key.pem" ubuntu@<your-ec2-public-ip>
```

## 3. Install Dependencies

Update the system and install Docker & Docker Compose.

```bash
# Update packages
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable Docker for non-root user (avoid sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

## 4. Deploy Project

### Option A: Clone from Git (Recommended)
If you have pushed this code to GitHub:

```bash
git clone https://github.com/your-username/shopmicro.git
cd shopmicro
```

### Option B: Copy Files Manually (SCP)
If code is local, use `scp` to upload it (run from your local machine, not EC2):

```bash
# Zip your project first to exclude node_modules etc.
# Then:
scp -i "shopmicro-key.pem" -r ./t4dev-capstone/* ubuntu@<your-ec2-public-ip>:~/shopmicro/
```

## 5. run the Application

On the EC2 instance, inside the project folder:

```bash
# Start all services
docker compose up -d --build

# Check status
docker compose ps
```

## 6. Verify Deployment

Open your browser and visit:
- **Frontend**: `http://<your-ec2-public-ip>:3000`
- **Backend API**: `http://<your-ec2-public-ip>:8080/products`
- **ML Service**: `http://<your-ec2-public-ip>:5000/health`

## 7. Troubleshooting

- **Connection Timeout?** Check your Security Group rules in AWS. Ensure ports 3000, 8080, 5000 are open.
- **Permission Denied?** Ensure you ran `newgrp docker` or are using `sudo`.
- **Containers crashing?** Run `docker compose logs -f` to see errors.
