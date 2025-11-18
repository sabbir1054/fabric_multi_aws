#!/bin/bash

echo "Checking orderer status..."
docker ps -a | grep orderer

echo -e "\n\nOrderer logs:"
docker logs orderer.example.com 2>&1 | tail -50
