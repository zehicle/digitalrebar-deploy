#!/bin/bash
#set -e
set -x

while [[ ! -e /vagrant/compose/data-dir/node/rebar-key.sh ]] ; do
  echo "Waiting for rebar-key.sh to show up"
  sleep 5
done

# Wait fo/vagrant/compose/data-dir/node/rebar-key.shr the webserver to be ready.
. /vagrant/compose/data-dir/node/rebar-key.sh

#set -e
ip_re='([0-9a-f.:]+/[0-9]+)'
if ! [[ $(ip -4 -o addr show |grep 'scope global' |grep -v ' lo' |grep -v ' dynamic'|grep eth1) =~ $ip_re ]]; then
  echo "Cannot find IP address for the admin node!"
  exit 1
fi
IPADDR="${BASH_REMATCH[1]}"
MAC=$(cat /sys/class/net/eth1/address)

while ! curl -f -g --digest -u "$REBAR_KEY" -X GET "$REBAR_ENDPOINT/api/v2/deployments/system"; do
  sleep 1
  . /vagrant/compose/data-dir/node/rebar-key.sh
  echo "looking for system"
done

DOMAIN=$(curl -f -g --digest -u "$REBAR_KEY" -X GET "$REBAR_ENDPOINT/api/v2/nodes/system-phantom.internal.local/attribs/dns-domain" | jq -r .value)
HOSTNAME="$(hostname).$DOMAIN"

echo "Using $HOSTNAME / $IPADDR / $MAC for on $REBAR_ENDPOINT"

# Create a new node for us,
# Add the default noderoles we will need, and
# Let the annealer do its thing.
node=$(curl -s -o /dev/null -w "%{http_code}" --digest -u "$REBAR_KEY" \
      -X GET "$REBAR_ENDPOINT/api/v2/nodes/$HOSTNAME")
if [[ $node == 404 ]]; then
  curl -f -g --digest -u "$REBAR_KEY" -X POST \
    -d "name=$HOSTNAME" \
    -d "mac=$MAC" \
    -d "ip=$IPADDR" \
    -d "variant=virtual" \
    -d "available=true" \
    -d "os_family=linux" \
    -d "arch=$(uname -m)" \
    "$REBAR_ENDPOINT/api/v2/nodes/" || {
      echo "We could not create a node for ourself!"
      exit 1
  }
  echo "Node $HOSTNAME created"
else
  echo "Node already created, moving on"
fi

# does the rebar-joined-role exist?
joined=$(curl -s -o /dev/null -w "%{http_code}" --digest -u "$REBAR_KEY" \
  -X GET "$REBAR_ENDPOINT/api/v2/nodes/$HOSTNAME/node_roles/rebar-joined-node")
if [[ $joined == 404 ]]; then
    curl -f -g --digest -u "$REBAR_KEY" -X POST \
      -d "node=$HOSTNAME" \
      -d "role=rebar-joined-node" \
      "$REBAR_ENDPOINT/api/v2/node_roles/" && \
    curl -f -g --digest -u "$REBAR_KEY" -X PUT \
      "$REBAR_ENDPOINT/api/v2/nodes/$HOSTNAME/commit" || {
        echo "We could not commit the node!"
        exit 1
    }
else
    echo "Node already committed, moving on"
fi

# get the SSH keys
if blob="$(curl -f -g --digest -u "$REBAR_KEY" -X GET "$REBAR_ENDPOINT/api/v2/deployments/system/attribs/rebar-access_keys" | jq -r .value)"; then
  sudo awk -F\" '{ print $4 }' <<<"$blob" >> ~/.ssh/authorized_keys
fi


# Always make sure we are marking the node alive. It will comeback later.
curl -f -g --digest -u "$REBAR_KEY" -X PUT \
  -d "alive=true" \
  "$REBAR_ENDPOINT/api/v2/nodes/$HOSTNAME" 
