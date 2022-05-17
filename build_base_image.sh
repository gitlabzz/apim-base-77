#! /bin/bash

# ./build_base_image.sh 7_7_20220228_20220518_3 harbor.com /apim_sit /apim_base
# ./build_base_image.sh 7_7_20220228_20220518_3 harbor.com /apim_uat /apim_base
# ./build_base_image.sh 7_7_20220228_20220518_3 harbor.com /apim /apim_base

#1 = release/ Image Tag = 7_7_20220228_20220518_3
#2 = Harbor = harbor.com
#3 = Harbor Project = /apim_sit
#4 = Image Name = /apim_base

echo
echo "----------- Building Base Image For Release '$1' ----------- "
tar xf APIGateway_7.7.20220228-DockerScripts-2.4.0.tar

./apigw-emt-scripts-2.4.0/build_base_image.py \
  --installer=$HOME/APIGateway_7.7.20220228_Install_linux-x86-64_BN02.run \
  --os=centos7 \
  --out-image=$2$3$4:$1

# create latest tag
docker tag $2$3$4:$1 $2$3$4:latest

# push image with release tag
docker push $2$3$4:$1

# push same image using 'latest' tag
docker push $2$3$4:latest
