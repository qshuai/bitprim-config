#!/bin/bash

_term() {
  echo "Caught SIGTERM signal!"
  echo Waiting for $child
  echo "kill -TERM "$child" ; wait $child 2>/dev/null"
}

start_bitcore()
{
trap _term SIGTERM
tail -f /dev/null &
child=$!
wait $child
}

start_bitcore
