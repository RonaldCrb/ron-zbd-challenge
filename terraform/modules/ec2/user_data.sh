#!/bin/bash

# Generic Infrastructure Setup Script for Amazon Linux 2023
# This script prepares the instance for running any Docker application
set -e

LOG_GROUP_NAME="${log_group_name}"
INSTANCE_NAME="${instance_name}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/user-data.log
}

log "Starting infrastructure setup for $INSTANCE_NAME"

# Update system with security patches
dnf update -y --security
dnf install -y docker awscli amazon-cloudwatch-agent curl wget

# Security: Configure automatic security updates
dnf install -y dnf-automatic
systemctl enable --now dnf-automatic.timer

# Start and enable Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "$LOG_GROUP_NAME",
                        "log_stream_name": "$INSTANCE_NAME-userdata"
                    },
                    {
                        "file_path": "/var/log/application.log",
                        "log_group_name": "$LOG_GROUP_NAME",
                        "log_stream_name": "$INSTANCE_NAME-application"
                    }
                ]
            }
        }
    }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Enhanced Security Hardening
log "Applying security hardening measures"

# 1. Configure firewalld (more secure than iptables)
systemctl enable firewalld
systemctl start firewalld

# Allow only necessary ports
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload

# 2. SSH Security Hardening
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
cat >> /etc/ssh/sshd_config << EOF

# Security hardening
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
Protocol 2
AllowUsers ec2-user
EOF
systemctl reload sshd

# 3. System Security Hardening
# Disable unnecessary services
systemctl disable postfix
systemctl stop postfix

# 4. Kernel Security Parameters
cat >> /etc/sysctl.conf << EOF

# Security hardening
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
EOF
sysctl -p

# 5. File System Security
# Set restrictive umask
echo "umask 027" >> /etc/bashrc
echo "umask 027" >> /etc/profile

# Create application directory for future use
mkdir -p /opt/app
chown ec2-user:ec2-user /opt/app

# Create a simple monitoring script
log "Creating monitoring script"
cat > /opt/app/monitor.sh << 'EOF'
#!/bin/bash

# Generic monitoring script for Docker-enabled instance
echo "=== System Status ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Hostname: $(hostname)"
echo ""
echo "=== Disk Usage ==="
df -h
echo ""
echo "=== Memory Usage ==="
free -h
echo ""
echo "=== Docker Status ==="
systemctl status docker --no-pager
echo ""
echo "=== Docker Containers ==="
docker ps
echo ""
echo "=== CloudWatch Agent Status ==="
systemctl status amazon-cloudwatch-agent --no-pager
echo ""
echo "=== Firewall Status ==="
firewall-cmd --list-all
EOF

chmod +x /opt/app/monitor.sh
chown ec2-user:ec2-user /opt/app/monitor.sh

# Set hostname
hostnamectl set-hostname "$INSTANCE_NAME"

# Create welcome message
cat > /etc/motd << EOF
==========================================
  Infrastructure Instance - $INSTANCE_NAME
==========================================
Instance: $INSTANCE_NAME
Docker: $(docker --version)
Docker Compose: $(docker-compose --version)
Monitoring: /opt/app/monitor.sh
Application Directory: /opt/app
Logs: /var/log/application.log
==========================================
Ready for Docker application deployment
==========================================
EOF

# Final security check
log "Running security verification"
systemctl is-active firewalld && log "✅ Firewall active" || log "❌ Firewall inactive"
systemctl is-active docker && log "✅ Docker active" || log "❌ Docker inactive"

log "Infrastructure setup completed for $INSTANCE_NAME - Ready for application deployment"