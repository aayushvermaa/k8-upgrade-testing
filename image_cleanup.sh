#!/bin/bash
#fetch all the none tagged images and remove them
docker images | grep none | awk '{ print $3; }' | xargs docker rmi -f > /dev/null 2>&1

#Remove all unused images not just dangling ones
docker system prune --all -f > /dev/null 2>&1

# List of images to pull
images=(
#update  below registry  images with your system images  using  below command"
# docker images | grep registry | grep -v okts | awk '{ print $1":"$2 } '| sed 's/.*/"&"/'
"registry.buildpiper.in/git-clone:v2.0.0.1"
"registry.buildpiper.in/workspace-cleaner:0.1"
"registry.buildpiper.in/okts/sonar-scan:nr_v0.1"
"registry.buildpiper.in/docker-image-build:v2.0.0.2"

#impl
"registry.buildpiper.in/impl/gitleaks-scan:nr_v0.1"
"registry.buildpiper.in/impl/image_cleanup:nr_v0.1"
"registry.buildpiper.in/impl/image_layer_validator:nr_v0.1"
"registry.buildpiper.in/impl/image_size_validator:nr_v0.1"
"registry.buildpiper.in/impl/pre-hooks:nr_v0.1"
"registry.buildpiper.in/impl/post-hooks:nr_v0.1"
"registry.buildpiper.in/impl/trivy-scan:nr_v0.1"

)

# Pull images
for image in "${images[@]}"; do
  docker pull "$image"
   echo "$image"
done
