set -e

mkdir -p /tmp/ocis/ocis-config \
mkdir -p /tmp/ocis/ocis-data
#sudo chown -Rfv 1000:1000 /tmp/ocis/
podman pull docker.io/owncloud/ocis
podman run --rm -it \
    --mount type=bind,source=/tmp/ocis/ocis-config,target=/etc/ocis,U=true \
    --mount type=bind,source=/tmp/ocis/ocis-data,target=/var/lib/ocis,U=true \
    docker.io/owncloud/ocis init --insecure yes
podman run \
    --name ocis_runtime \
    --rm \
    -it \
    -p 9200:9200 \
    --mount type=bind,source=/tmp/ocis/ocis-config,target=/etc/ocis,U=true \
    --mount type=bind,source=/tmp/ocis/ocis-data,target=/var/lib/ocis,U=true \
    -e OCIS_INSECURE=true \
    -e PROXY_HTTP_ADDR=0.0.0.0:9200 \
    -e OCIS_URL=https://localhost:9200 \
    docker.io/owncloud/ocis
