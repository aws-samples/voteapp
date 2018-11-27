#!/bin/bash
yum -y install java-1.8.0-openjdk
curl front-envoy:8001/stats/prometheus -o file.out
sed -e 's/|/_/g' file.out > front.out
#sed -e 's/_/|/g' file.out > front.out
java -jar prom-stats.jar &
trap "exit" INT
while true
do
  echo "call curl"
  curl front-envoy:8001/stats/prometheus -o file.out
  sed -e 's/|/_/g' file.out > front.out
  #sed -e 's/_/|/g' file.out > front.out
  echo "called curl"
  sleep 5
  echo "sleep 5"
done

trap 'exit 143' SIGTERM # exit = 128 + 15 (SIGTERM)
tail -f /dev/null & wait ${!}