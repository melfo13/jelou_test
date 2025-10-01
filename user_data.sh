#!/bin/bash


set -e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Updating the system..."
yum update -y

echo "Installing packages required..."
yum install -y \
    git \
    curl \
    wget \
    unzip \
    htop \
    amazon-cloudwatch-agent

echo "Installing Docker..."
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "Installing Node.js..."
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

echo "Installing PostgreSQL..."
yum install -y postgresql15-server postgresql15
postgresql-setup --initdb
systemctl start postgresql
systemctl enable postgresql

echo "Setting PostgreSQL..."
sudo -u postgres psql << 'EOF'
ALTER USER postgres PASSWORD 'postgres123';
CREATE DATABASE users_db;
EOF

echo "local all all md5" >> /var/lib/pgsql/15/data/pg_hba.conf
echo "host all all 127.0.0.1/32 md5" >> /var/lib/pgsql/15/data/pg_hba.conf
systemctl restart postgresql

echo "Creating directory for the application..."
mkdir -p /opt/user-microservice
chown ec2-user:ec2-user /opt/user-microservice

echo "Setting CloudWatch Agent..."
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/aws/ec2/user-microservice",
            "log_stream_name": "{instance_id}/user-data.log"
          },
          {
            "file_path": "/opt/user-microservice/app.log",
            "log_group_name": "/aws/ec2/user-microservice",
            "log_stream_name": "{instance_id}/application.log"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "Setting user for deploy..."
useradd -m -s /bin/bash deploy
usermod -a -G docker deploy
echo "deploy ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/deploy

echo "Installing GitHub CLI..."
yum install -y gh

cat > /opt/deploy.sh << 'EOF'
#!/bin/bash
# Script that will be executed by GitHub Actions
set -e

echo "Starting deployment..."
cd /opt/user-microservice

sudo systemctl stop user-microservice || true

# Install/update dependencies
npm install --production

if [ -f "migrate.js" ]; then
    node migrate.js
fi

sudo systemctl daemon-reload
sudo systemctl start user-microservice
sudo systemctl enable user-microservice

echo "Deployment completed!"
EOF

chmod +x /opt/deploy.sh
chown deploy:deploy /opt/deploy.sh

echo "=========================================="
echo "Basic configuration completed!"
echo "=========================================="