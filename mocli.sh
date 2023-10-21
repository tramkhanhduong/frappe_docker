#!/bin/bash

# Function to start or stop the Docker Compose based on the arguments provided
mocli() {
  if [ "$1" == "local" ] && [ "$2" == "up" ]; then
    docker-compose -f compose.local.yaml --env-file .env.local up
  elif [ "$1" == "prod" ] && [ "$2" == "up" ]; then
    docker-compose -f compose.yaml  --env-file .env.prod up
  elif [ "$1" == "local" ] && [ "$2" == "down" ]; then
    docker-compose -f compose.local.yaml down
  elif [ "$1" == "prod" ] && [ "$2" == "down" ]; then
    docker-compose -f compose.yaml down
  elif [ "$1" == "remove" ] && [ "$2" == "volume" ]; then
    docker volume rm $(docker volume ls -q | grep "frappe")
  elif [ "$1" == "ssh" ]; then
    # Add the SSH command here, replacing the placeholders with your values
    ssh -i erpnext.pem ubuntu@ec2-54-169-203-140.ap-southeast-1.compute.amazonaws.com
  else
    echo "Usage: mocli [local|prod] [up|down|remove volume] [ssh]"
  fi
}

# Call the mocli function with the provided arguments
mocli "$1" "$2"
