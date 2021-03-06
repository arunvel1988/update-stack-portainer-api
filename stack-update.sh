#!/usr/bin/env bash
P_USER=${P_USER:-"admin"}
P_PASS=${P_PASS:-"admin"}
P_URL=${P_URL:-"http://localhost:9000"}
P_PRUNE=${P_PRUNE:-"false"}

if [ -z ${1+x} ]; then
  echo "Parameter #1 missing: stack name "
  exit 1
fi
TARGET="$1"

if [ -z ${2+x} ]; then
  echo "Parameter #2 missing: path to yml"
  exit
fi
TARGET_YML="$2"

echo "Updating $TARGET"

echo $token

#INFO=$(curl -s -H "Authorization: Bearer $token" "$P_URL/api/endpoints/1/dccker/info")
#CID=$(echo "$INFO" | awk -F '"Cluster":{"ID":"' '{print $2}' | awk -F '"' '{print $1}')
#echo "Cluster ID: $CID"

echo "Getting stacks..."
STACKS=$(curl -s -H "Authorization: Bearer $token" "$P_URL/api/stacks")

echo "/---" && echo $STACKS && echo "\\---"

found=0
stack=$(echo "$STACKS"|jq --arg TARGET "$TARGET" -jc '.[]| select(.Name == $TARGET)')

if [ -z "$stack" ];then
  echo "Result: Stack not found."
  exit 1
fi
sid="$(echo "$stack" |jq -j ".Id")"
name=$(echo "$stack" |jq -j ".Name")

found=1
echo "Identified stack: $sid / $name"

existing_env_json="$(echo -n "$stack"|jq ".Env" -jc)"

dcompose=$(cat "$TARGET_YML")
dcompose="${dcompose//$'\r'/''}"
dcompose="${dcompose//$'"'/'\"'}"
echo "/-----READ_YML--------"

echo "$dcompose"
echo "\---------------------"
dcompose="${dcompose//$'\n'/'\n'}"
data_prefix="{\"Id\":\"$sid\",\"StackFileContent\":\""
data_suffix="\",\"Env\":"$existing_env_json",\"Prune\":$P_PRUNE}"
sep="'"
echo "/~~~~CONVERTED_JSON~~~~~~"
echo "$data_prefix$dcompose$data_suffix"
echo "\~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$data_prefix$dcompose$data_suffix" > json.tmp

echo "Updating stack..."
UPDATE=$(curl -s \
"$P_URL/api/stacks/$sid?endpointId=1" \
-X PUT \
-H "Authorization: Bearer $token" \
-H "Content-Type: application/json;charset=UTF-8" \
            -H 'Cache-Control: no-cache'  \
            --data-binary "@json.tmp"
        )
rm json.tmp
echo "Got response: $UPDATE"
if [ -z ${UPDATE+x} ]; then
  echo "Result: failure  to update"
  exit 1
else
  echo "Result: successfully updated"
  exit 0
fi


if [ "$found" == "1" ]; then
  echo "Result: found stack but failed to process"
  exit 1
else
  echo "Result: fail"
  exit 1
fi

