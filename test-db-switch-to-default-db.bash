#!/bin/bash

DEVELOP_DB='mysql'
BRANCH_NAME=`git symbolic-ref --short HEAD | tr '[A-Z]' '[a-z]'` # ブランチ名を取得
# TODO 名前変
MYSQL_IMAGE_NAME="test-mysql-$BRANCH_NAME"

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@"
echo "@  テストが終了したので、開発用のDBに切り替えます。"
echo "@"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
docker stop ${MYSQL_IMAGE_NAME}
docker rm ${MYSQL_IMAGE_NAME}
docker start $DEVELOP_DB #
