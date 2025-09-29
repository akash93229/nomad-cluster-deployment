Nomad Cluster Deployment — README (client-ready)

What this repo contains: Terraform to provision an AWS EC2 instance, Nomad server+client configuration, and sample Nomad jobs that demonstrate the cluster is functional.
Use this README to reproduce the environment, run the demo hello-world job, secure the Nomad UI, and collect proof screenshots.

✅ Objective

Provision a reproducible Nomad single-node cluster (server + client) using Terraform, demonstrate workload scheduling by running a containerized hello-world job, and document secure UI access and evidence to share with stakeholders.

📁 Repo structure (important files)
.
├── main.tf                 # Terraform: EC2 + Security Group + (optional) user_data
├── variables.tf            # Terraform variables
├── terraform.tfvars        # Terraform variable values (your values)
├── outputs.tf              # Terraform outputs (public IPs)
├── nomad-minimal.hcl       # Nomad agent config (server+client)
├── nomad.servicev          # systemd unit used in this environment (example)
├── hello-world.nomad       # Nomad job (docker http-echo)
├── nginx.nomad             # Example job (if present)
├── python-server.nomad     # Example job (if present)
├── README.md               # This file (copy into repo)
└── nomad-ui.png            # (Add screenshot file here for evidence)

🔧 Prerequisites

AWS account + IAM credentials configured locally (if running Terraform).

Terraform v1.x installed.

SSH keypair to access EC2 instances.

For remote Nomad installs via user_data: cloud-init / user-data support on chosen AMI (Amazon Linux / Ubuntu).

(Optional) Docker installed on the Nomad client if you run Docker jobs.

🧩 Terraform (skeleton)

Place these in main.tf, variables.tf, outputs.tf. This is a minimal/example skeleton — adapt AMI, instance type, and key names to your environment.

main.tf (simplified)

provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "nomad_sg" {
  name = "nomad-sg"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]   # restrict SSH to admin IP
  }

  ingress {
    description = "Nomad HTTP UI"
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]   # restrict Nomad UI to admin IP
  }

  ingress {
    description = "Optional app port (e.g. 8080)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]         # change to admin IP or load balancer later
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nomad_node" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.nomad_sg.id]
  associate_public_ip_address = true

  # Option A: user_data to install Nomad & Consul, or you can use provisioners/Ansible
  user_data = file("${path.module}/cloud-init/nomad-user-data.sh")
}


variables.tf

variable "aws_region" { default = "ap-south-1" }
variable "ami" {}
variable "instance_type" { default = "t3.micro" }
variable "key_name" {}
variable "admin_ip_cidr" { description = "Your admin IP in CIDR form, e.g. 1.2.3.4/32" }


outputs.tf

output "instance_public_ip" {
  value = aws_instance.nomad_node.public_ip
}


Note: The user_data script should install Nomad, create /opt/nomad data dirs, place nomad-minimal.hcl, enable systemd unit, and start Nomad. If you prefer manual install, run the commands in the README steps later.

🧾 Nomad config (nomad-minimal.hcl) — single-node example

Save as /home/ubuntu/nomad-cluster-deployment/nomad-minimal.hcl (already in repo). This example works for Nomad 1.5.x:

datacenter = "dc1"
data_dir   = "/opt/nomad"
bind_addr  = "0.0.0.0"

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
}

log_level = "INFO"


Make sure /opt/nomad exists and is owned by the Nomad user:

sudo mkdir -p /opt/nomad/{server,client,alloc}
sudo chown -R ubuntu:ubuntu /opt/nomad


Systemd service (example — nomad.service):

[Unit]
Description=Nomad Agent
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/nomad agent -config=/home/ubuntu/nomad-cluster-deployment/nomad-minimal.hcl
Restart=on-failure
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target

🧪 Hello-world Nomad job

hello-world.nomad (docker http-echo — reliable, small):

job "hello-world" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 1

    task "http-echo" {
      driver = "docker"
      config {
        image = "hashicorp/http-echo:0.2.3"
        args  = ["-text=Hello, Nomad!"]
        port_map {
          http = 5678
        }
      }

      resources {
        cpu    = 100
        memory = 64
      }

      service {
        name = "hello-world"
        port = "http"
        check {
          name     = "tcp"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

    network {
      port "http" {
        static = 8080   # optional static port; or remove static to use dynamic mapping
      }
    }
  }
}


Deploy:

nomad job run hello-world.nomad


Verify:

nomad job status hello-world
nomad alloc status <alloc-id>

Architecture Diagram Description
                       +--------------------+
                       |    Terraform CLI    |
                       | (Provision Infra)   |
                       +----------+---------+
                                  |
                                  | Provisions AWS Infrastructure
                                  |
                      +-----------v------------+
                      |       AWS Cloud        |
                      |                        |
                      |  +------------------+  |
                      |  |  EC2 Instances   |  |
                      |  |  (Nomad Servers) |  |
                      |  +--------+---------+  |
                      |           |            |
                      |  +--------v---------+  |
                      |  |  EC2 Instances   |  |
                      |  |  (Nomad Clients) |  |
                      |  +--------+---------+  |
                      |           |            |
                      |  +--------v---------+  |
                      |  |  Applications    |  |
                      |  |  (hello-world,   |  |
                      |  |   python-server) |  |
                      |  +------------------+  |
                      +------------------------+

Nomad Cluster components:

- **Nomad Servers**: Responsible for cluster management, scheduling, and leader election.
- **Nomad Clients**: Run workloads and applications, execute tasks as per jobs.
- **Applications/Jobs**: Defined in `.nomad` files, like `hello-world` and `python-server`.
- **Terraform**: Automates provisioning of EC2 instances and networking resources.
- **Nomad UI**: Accessed via EC2 public IP and port 4646, provides job and cluster status.

---

### Visual Diagram (ASCII Art)



[Terraform] ---> [AWS Cloud]
|
+-------+-------+
| |
[Nomad Servers] [Nomad Clients]
| |
+-----+-----+ +---+---+
| | | |
[Nomad UI] [Jobs: hello-world, python-server]


---

### Explanation

- **Terraform CLI** runs on your local machine or CI system to provision the AWS infrastructure needed for the cluster.
- AWS EC2 instances are split into **Nomad Servers** and **Nomad Clients**.
- **Nomad Servers** handle cluster state, leader election, and job scheduling.
- **Nomad Clients** run the actual jobs and applications.
- Nomad UI runs on the Nomad Server and is accessible via the public IP for monitoring and job management.
- Jobs like `hello-world` and `python-server` are deployed to clients through the Nomad cluster.

---

If you want, I can create a simple diagram image (PNG or SVG) based on this and you can include it in your repo too! Would you like that?

Open Browser: http://<PUBLIC_IP>:8080 (or the mapped port shown by nomad alloc status).

🔒 Secure Nomad UI (recommended before sharing)

Minimum steps to make UI safe to share with client:

Restrict Security Group — only allow your admin IP (or corporate IP) to access port 4646:

In Terraform: set aws_security_group ingress for 4646 to var.admin_ip_cidr.

In AWS Console: edit SG rules accordingly.

Run a reverse proxy with TLS (NGINX) for nicer UX & HTTPS:

On the same server, install nginx and Certbot, then configure:

/etc/nginx/conf.d/nomad-ui.conf:

server {
  listen 80;
  server_name <YOUR_PUBLIC_DOMAIN>;
  location /.well-known/acme-challenge/ { root /var/www/certbot; }
  location / { return 301 https://$host$request_uri; }
}

server {
  listen 443 ssl;
  server_name <YOUR_PUBLIC_DOMAIN>;

  ssl_certificate /etc/letsencrypt/live/<YOUR_PUBLIC_DOMAIN>/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/<YOUR_PUBLIC_DOMAIN>/privkey.pem;

  location / {
    proxy_pass http://127.0.0.1:4646;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}


Use Certbot to obtain cert:

sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y
sudo certbot --nginx -d <YOUR_PUBLIC_DOMAIN>


(Optional, advanced) Enable mTLS in nomad.hcl (recommended for production).

🐞 Debugging failing jobs (like python-server)

If a job appears DEAD or FAILED, inspect the allocation logs:

List allocations for job:

nomad job status python-server


For a failing allocation ID (e.g. bd93e206):

nomad alloc status bd93e206
nomad alloc logs bd93e206 web         # stdout/stderr from the task
nomad alloc logs -stderr bd93e206 web # show stderr only


Common causes:

Docker image pull failures (network/registry/auth).

Command inside task is wrong (path, arguments).

Port conflicts (static ports already used).

Resource constraints (not enough memory/CPU).

✅ Deliverables checklist (what to hand to client)

 Terraform files: main.tf, variables.tf, outputs.tf, terraform.tfvars

 Nomad config: nomad-minimal.hcl + systemd unit

 Nomad job file: hello-world.nomad

 Evidence: place nomad-ui.png (screenshot) into repo root and reference below

 Security: restrict SG / add NGINX + TLS (recommended)

 Optional extras: CI/CD automation, Prometheus/Grafana telemetry

📸 Add your screenshot to README

Move the screenshot into the repo and reference it in the README:

# if screenshot is at /mnt/data/f9228b73-...png
mv /mnt/data/f9228b73-886b-444a-ae1e-6913341e89e5.png ./nomad-ui.png
git add nomad-ui.png README.md hello-world.nomad main.tf variables.tf outputs.tf
git commit -m "Add README, terraform, nomad job and screenshot"
git push


Markdown snippet to embed:

## Proof — Nomad UI & Job

![Nomad UI Screenshot](./nomad-ui.png)

Above: Nomad UI showing `hello-world` (RUNNING) and `python-server` (DEAD).

🚀 Quick sanity-run (commands)
# 1. Ensure /opt/nomad exists & ownership correct
sudo mkdir -p /opt/nomad/{server,client,alloc}
sudo chown -R ubuntu:ubuntu /opt/nomad

# 2. Start nomad (systemd or foreground for debug)
sudo systemctl enable nomad
sudo systemctl start nomad
# OR debug in foreground:
nomad agent -config=/home/ubuntu/nomad-cluster-deployment/nomad-minimal.hcl

# 3. Run job:
nomad job run hello-world.nomad

# 4. Verify:
nomad job status hello-world
nomad node status -verbose

# 5. Debug failing alloc:
nomad alloc status <alloc-id>
nomad alloc logs <alloc-id> <task-name>
# Navigate to the folder where you want the repo
cd "C:\Users\<ClientName>\Desktop\"

# Clone the main repo along with all submodules
git clone --recurse-submodules https://github.com/akash93229/nomad-cluster-deployment.git

# Navigate into the cloned repo
cd nomad-cluster-deployment

# Ensure the main branch is checked out
git checkout main

# Pull the latest changes from main
git pull origin main

# Initialize and update submodules recursively
git submodule update --init --recursive

# Update submodules to track the remote branch
git submodule update --remote

# Optional: verify the submodule status
git submodule status


Contact / Notes

If you want, I can:

Insert real content from your main.tf and hello-world.nomad into this README (so the client sees your exact configs).

Produce an nginx+certbot snippet and a Terraform user_data that automatically installs and configures Nomad + nginx TLS.

Help fix the failing python-server job — paste its alloc logs output and I’ll triage.
