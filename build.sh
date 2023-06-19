#!/bin/bash

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 752378938230.dkr.ecr.us-east-1.amazonaws.com
docker build -t 752378938230.dkr.ecr.us-east-1.amazonaws.com/k8s-testing:latest -f Dockerfile .
docker push 752378938230.dkr.ecr.us-east-1.amazonaws.com/k8s-testing:latest