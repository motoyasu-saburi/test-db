#!/bin/bash

function runTestDb () {
  docker run -it --name $MYSQL_BASE -p 3306:3306 -e 'MYSQL_ALLOW_EMPTY_PASSWORD=yes' -d $MYSQL_BASE
}

function stopDevelopDb () {
  # もし開発用のDBがある場合はPortが競合するのでここで停止させておく
  docker stop $DEVELOPMENT_DB_NAME
}

function startTestDb () {
  echo "@ 開発用のDBを停止中"
  stopDefaultDb
  # まだ (テストデータは入っていない) テストDBのベースとなるイメージがない場合は作成する
  isExistsBaseImage=`docker images ${MYSQL_BASE} | awk -F"  +" 'NR>1{print $(NF-4)}'`
  if [ "${isExistsBaseImage}" != "${MYSQL_BASE}" ]; then
    echo "@ テストDBのベース用コンテナ生成中"
    (cd docker && docker build -t ${MYSQL_BASE} ./docker/mysql)
  fi
  echo "@ テストDBのベース用コンテナ起動中"
  runTestDb
  echo "@ テストDBに初期データを挿入します"
  # 初期データを投入するコマンドなどを用意
  (cd docker && ./initialization-test-db.sh ${MYSQL_BASE})
}

function changeToTestDb (){
  stopDefaultDb
  runTestDb
}

function saveTestDb () {
  echo "@ テストDBを保存中"
  docker commit ${MYSQL_BASE} ${MYSQL_IMAGE_NAME}
  docker stop $MYSQL_BASE
  docker rm $MYSQL_BASE
  docker run -it --name $MYSQL_IMAGE_NAME  -p 3306:3306 -e 'MYSQL_ALLOW_EMPTY_PASSWORD=yes' -d ${MYSQL_IMAGE_NAME}
}

# 既にテストDBのイメージが存在しているかを確認する
function isExistsImage (){
  IMAGE_NAME=`docker images ${MYSQL_IMAGE_NAME} | awk -F"  +" 'NR>1{print $(NF-4)}'`
  if [ "${IMAGE_NAME}" = "${MYSQL_IMAGE_NAME}" ]; then
    echo true
  else
    echo false
  fi
}

#####################
#   メインロジック
#####################
BRANCH_NAME=`git symbolic-ref --short HEAD | tr '[A-Z]' '[a-z]'` # ブランチ名を取得
DEVELOPMENT_DB_NAME="mysql"
MYSQL_BASE="test-mysql-base"
MYSQL_IMAGE_NAME="test-mysql-$BRANCH_NAME"

# 既にテストDBのイメージがローカルに存在しているかを確認する
IS_TEST_DB_IMAGE_EXISTS=`isExistsImage`

if [ "${IS_TEST_DB_IMAGE_EXISTS}" = "true" ]; then
  # テストDBが存在する場合は
  # 1. 古いテストDB用のDocker Containerを消し、
  # 2. データ入りDocker ImageからDocker Containerを作成・起動する
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "@"
  echo "@  DBをテスト用に変更します"
  echo "@"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "※ Dockerの起動などでErrorが出るかもしれませんが問題ないです。"
  # 古い方のテストDBを停止する
  docker stop ${MYSQL_IMAGE_NAME}
  docker rm ${MYSQL_IMAGE_NAME}
  echo "@ デフォルトで使用するDockerデータを停止中"
  stopDevelopDb
  echo "@ テスト用のDocker DBを起動中"
  # TODO MysqlImageNameリネームする
  docker run -it --name $MYSQL_IMAGE_NAME  -p 3306:3306 -e 'MYSQL_ALLOW_EMPTY_PASSWORD=yes' -d ${MYSQL_IMAGE_NAME}
else
  # テストDBが存在しない場合は
  # 1. テストDBのベースとなるDocker Containerを作成する
  # 2. テストDBのベースとなるContainerに初期データを入れる
  # 3. 初期データが入った状態をDocker Imageとして保存（コミット）する
  # 4. 初期データが入ったDocker Containerを起動した状態にする
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "@"
  echo "@  テストDB作成して起動します"
  echo "@"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  startTestDb
  saveTestDb
fi
echo "@ テストを開始します。"
