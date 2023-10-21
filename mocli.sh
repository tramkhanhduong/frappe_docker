#!/bin/bash

# Function to create the first Bench site
create_first_bench_site() {
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
  -f overrides/compose.redis.yaml \
  -f overrides/compose.multi-bench.yaml config > gitops/erpnext-one.yaml  
#   -f overrides/compose.multi-bench-ssl.yaml config > gitops/erpnext-one.yaml  

  echo "First Bench site created."
}

deploy_first_bench() {
    docker compose --project-name erpnext-one -f gitops/erpnext-one.yaml up -d
    
    # hyperdata.vn
    docker compose --project-name erpnext-one exec backend \
    bench new-site hyperdata.vn --no-mariadb-socket --db-type postgres \
    --db-host erpnext.c2lmgf35yljx.ap-southeast-1.rds.amazonaws.com \ 
    --db-name erpnext --db-password "0914189116aA" --install-app erpnext --admin-password "0914189116aA";
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
    # Add the SSH command here, replacing the placeholders with your values
    ssh -i erpnext.pem ubuntu@ec2-54-169-203-140.ap-southeast-1.compute.amazonaws.com
    sudo -s
  elif [ "$1" == "install-docker-compose" ]; then
    install_docker_compose  
  elif [ "$1" == "traefik" ]; then
    # Set up Traefik
    docker compose --project-name traefik \
      --env-file gitops/traefik.env \
      -f overrides/compose.traefik.yaml \
      -f overrides/compose.traefik-ssl.yaml up -d
  elif [ "$1" == "traefik-without-ssl" ]; then
    # Set up Traefik
    docker compose --project-name traefik \
      --env-file gitops/traefik.env \
      -f overrides/compose.traefik.yaml up -d
  elif [ "$1" == "create-bench" ]; then  
    create_first_bench_site
  elif [ "$1" == "deploy-first-bench" ]; then 
    deploy_first_bench
  else
    echo "Usage: mocli [local|prod] [up|down|remove volume] [ssh|traefik|create-bench|deploy-first-bench]"
  fi
}

# Call the mocli function with the provided arguments
mocli "$1" "$2"
