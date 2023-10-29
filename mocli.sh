#!/bin/bash

# Function to create the first Bench site
create_yaml_docker_compose() {
  # Copy the example.env to erpnext-one.env
  cp example.env gitops/erpnext-one.env

  # Modify the erpnext-one.env file using sed
  sed -i 's/DB_PASSWORD=123/DB_PASSWORD=0914189116aA/g' gitops/erpnext-one.env
  sed -i 's/DB_HOST=/DB_HOST=erpnext.c2lmgf35yljx.ap-southeast-1.rds.amazonaws.com/g' gitops/erpnext-one.env
  sed -i 's/DB_PORT=/DB_PORT=5432/g' gitops/erpnext-one.env
  sed -i 's/SITES=`erp.example.com`/SITES=\`hyperdata.vn\`,\`two.hyperdata.vn\`/g' gitops/erpnext-one.env

  # Append the required environment variables
  echo 'ROUTER=erpnext-one' >> gitops/erpnext-one.env
  echo "BENCH_NETWORK=erpnext-one" >> gitops/erpnext-one.env

  # Create yaml file
  docker compose --project-name erpnext-one \
  --env-file gitops/erpnext-one.env \
  -f compose.yaml \
  -f overrides/compose.redis.yaml config > gitops/erpnext-one.yaml
#   -f overrides/compose.multi-bench.yaml config > gitops/erpnext-one.yaml  
#   -f overrides/compose.multi-bench-ssl.yaml config > gitops/erpnext-one.yaml  

  echo "Created: gitops/erpnext-one.yaml"
}

deploy_bench() {
    docker compose --project-name erpnext-one -f gitops/erpnext-one.yaml up -d
    
    # hyperdata.vn
    docker compose --project-name erpnext-one exec erpnext-one-backend-1 \
    # bench new-site hyperdata.vn --db-type postgres --db-name erpnext --db-password "0914189116aA" --db-host erpnext.c2lmgf35yljx.ap-southeast-1.rds.amazonaws.com --db-port 5432 --install-app erpnext --admin-password "0914189116aA";
    bench new-site frontend --db-type postgres --db-name erpnext --db-password "0914189116aA" --db-host erpnext.c2lmgf35yljx.ap-southeast-1.rds.amazonaws.com --db-port 5432 --admin-password "0914189116aA";
}

# Function to install Docker Compose
install_docker_compose() {
  DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
  mkdir -p $DOCKER_CONFIG/cli-plugins
  curl -SL https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
  chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

  # Check if Docker Compose is installed successfully
  if [ -x "$(command -v docker-compose)" ]; then
    echo "Docker Compose installed successfully."
  else
    echo "Failed to install Docker Compose."
  fi
}

function install_nginx {
    # Check if Nginx is already installed
    if [ -x "$(command -v nginx)" ]; then
        echo "Nginx is already installed. Checking service status..."
        sudo systemctl status nginx
        return
    fi

    # Update the package list
    sudo apt update

    # Install Nginx
    sudo apt install -y nginx

    # Check if Nginx service is found
    if systemctl list-units --type=service | grep -q nginx; then
        service_name="nginx"
    else
        if systemctl list-units --type=service | grep -q httpd; then
            service_name="httpd"
        else
            echo "Nginx service not found. Please check your installation."
            return
        fi
    fi

    # Start and enable Nginx
    sudo systemctl start $service_name
    sudo systemctl enable $service_name

    # Check Nginx service status
    sudo systemctl status $service_name
}

# Define a function to execute an interactive terminal in a Docker container
docker_exec() {
    # Check if a container name is provided
    if [ -z "$1" ]; then
        echo "Usage: docker_exec <container_name>"
        return 1
    fi

    # Find the container ID based on the container name
    container_name="$1"
    container_id=$(docker ps --filter "name=$container_name" -q)

    # Check if the container exists
    if [ -z "$container_id" ]; then
        echo "Container '$container_name' not found or not running."
        return 1
    fi

    # Execute an interactive terminal in the container
    docker exec -it "$container_id" /bin/bash
}

function rm_volume() {
    local volume_name="erpnext-one_sites"
    local containers_using_volume

    # Get a list of containers using the specified volume
    containers_using_volume=$(docker ps -a --filter "volume=${volume_name}" --format "{{.ID}}")

    if [ -z "$containers_using_volume" ]; then
        echo "No containers are using the volume '${volume_name}'."
    else
        # Stop and remove containers using the volume
        for container_id in $containers_using_volume; do
            echo "Stopping and removing container: $container_id"
            docker stop "$container_id"
            docker rm "$container_id"
        done

        # Remove the volume
        echo "Removing volume: ${volume_name}"
        docker volume rm "$volume_name"
    fi
}

function install_postgres() {
  sudo apt update
  sudo apt install postgresql-13
  sudo systemctl status postgresql@13-main # check status
  sudo -u postgres psql
  ALTER USER your_username WITH PASSWORD '123';
  \q # exit
}

function setup_development() {
  # Copy the devcontainer-example directory to .devcontainer
  cp -R devcontainer-example .devcontainer

  # Copy the vscode-example directory to development/.vscode
  cp -R development/vscode-example development/.vscode

  # Run additional commands if necessary
  # command1
  # command2
}


# Function to start or stop the Docker Compose based on the arguments provided
mocli() {
  if [ "$1" == "local" ] && [ "$2" == "up" ]; then
    docker-compose -f compose.local.yaml --env-file .env.local up -d
  elif [ "$1" == "prod" ] && [ "$2" == "up" ]; then
    docker-compose -f compose.yaml --env-file .env.prod up -d
  elif [ "$1" == "local" ] && [ "$2" == "down" ]; then
    docker-compose -f compose.local.yaml down
  elif [ "$1" == "prod" ] && [ "$2" == "down" ]; then
    docker-compose -f compose.yaml down
  elif [ "$1" == "remove" ] && [ "$2" == "volume" ]; then
    docker volume rm $(docker volume ls -q | grep "frappe")
  elif [ "$1" == "ssh" ]; then
    instance_id="i-033be30da0ad8f17e"
    # Retrieve the public IP address of the EC2 instance
    public_ip=$(aws ec2 --profile duong-tram-personal describe-instances --instance-ids "$instance_id" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    
    if [ -z "$public_ip" ]; then
        echo "Error: Unable to retrieve the public IP address for instance $instance_id"
        return 1
    fi
    # Specify your private key file and SSH user
    key_file="erpnext.pem"
    ssh_user="ubuntu"  # Change to the appropriate user for your AMI
    
    # Connect to the EC2 instance via SSH
    ssh -i "$key_file" "$ssh_user@$public_ip"
  elif [ "$1" == "install-docker-compose" ]; then
    install_docker_compose  
  elif [ "$1" == "traefik" ]; then
    # Set up Traefik
    docker-compose -p traefik \
        --env-file gitops/traefik.env \
        -f overrides/compose.traefik.yaml -f overrides/compose.traefik-ssl.yaml config > gitops/traefik.yaml    
    docker-compose -f gitops/traefik.yaml up -d
  elif [ "$1" == "traefik-without-ssl" ]; then
    # Set up Traefik
    docker-compose -p traefik \
        --env-file gitops/traefik.env \
        -f overrides/compose.traefik.yaml config > gitops/traefik.yaml
    docker-compose -f gitops/traefik.yaml up -d
  elif [ "$1" == "create-yaml" ]; then  
    create_yaml_docker_compose
  elif [ "$1" == "deploy-bench" ]; then 
    deploy_bench
  elif [ "$1" == "install_nginx" ]; then 
    install_nginx
  elif [ "$1" == "exec" ] && [ -n "$2" ]; then
    docker_exec "$2"
  elif [ "$1" == "down" ]; then
    for container_id in $(docker ps -q --filter "name=erpnext"); do
        docker stop "$container_id"
    done
    echo "Containers matching 'erpnext':"
    docker ps | grep 'erpnext'
  elif [ "$1" == "rm_volume" ]; then
    rm_volume
  elif [ "$1" == "setup-dev" ]; then
    setup_development  
  else
    echo "Usage: mocli [local|prod] [up|down|remove volume] [ssh|traefik|traefik-without-ssl|create-yaml|deploy-bench|install_nginx|rm_volume]"
  fi
}

# Call the mocli function with the provided arguments
mocli "$1" "$2"
