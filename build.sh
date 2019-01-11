#!/bin/bash -e

# Build and squash baseimage
docker build -t docker-rails-base ./base
ID=$(docker run -d docker-rails-base true)
docker export $ID | docker import - se-2019-rails-base-squashed

# Create onbuild image
docker build -t skillsengine/rails-app-2019 ./onbuild
