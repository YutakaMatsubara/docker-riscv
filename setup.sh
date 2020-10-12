#!/bin/bash

#userId=`id -u`
#userName=`whoami`
#groupId=`id -g`
#groupName=`grep ":$groupId:" /etc/group | cut -d: -f1 | uniq`

userId=600
userName="seccamp"
groupId=600
groupName="Seccamp"

echo "user id: ${userName}(${userId}), group: ${groupName}(${groupId})"

docker build --build-arg userName=$userName --build-arg groupName=$groupName --build-arg userId=$userId --build-arg groupId=$groupId -f riscv.dockerfile -t toppers-riscv .