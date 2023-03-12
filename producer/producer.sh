#!/bin/bash

function list_args
{
  for arg in "${@}"
  do
    echo -n "${arg} "
  done
}

echo $(list_args $@) > /opt/app/output.txt
java -javaagent:/opt/app/opentelemetry-javaagent.jar $(list_args $@) -jar /opt/app/producer.jar

