#!/bin/bash

v=$1
osver=$2
patch=$3

v=${v:-3.5.8}
osver=${osver:-buster}
patch=${patch:-1}

image="deb-builder:$osver"

function die() {
    echo $@
    exit 2
}

if [ -z "$(docker images -q "$image" 2>/dev/null)" ]; then
    echo "Docker builder image not found. Building it..."
    if [ -e "./Dockerfile-$osver" ]; then
        docker build -t "$image" -f "Dockerfile-$osver" . || die "Failed to build the Docker image"
    else
        die "./Dockerfile-$osver not found"
    fi
fi

#if [ ! -d "apache-zookeeper-$v-bin" ]; then
#    if [ ! -e "apache-zookeeper-$v-bin.tar.gz" ]; then
#        wget "https://archive.apache.org/dist/zookeeper/zookeeper-$v/apache-zookeeper-$v-bin.tar.gz"
#    fi
#    tar -xzf "apache-zookeeper-$v-bin.tar.gz"
#fi

if [ ! -d "apache-zookeeper-$v" ]; then
    if [ ! -e "apache-zookeeper-$v.tar.gz" ]; then
        wget "https://archive.apache.org/dist/zookeeper/zookeeper-$v/apache-zookeeper-$v.tar.gz"
    fi
    tar -xzf "apache-zookeeper-$v.tar.gz"
fi
rm -rf "apache-zookeeper-$v/debian"
cp -r debian "./apache-zookeeper-$v/"

docker_args="-v $PWD/apache-zookeeper-$v:/source-ro:ro -v $PWD/output:/output -v $PWD/_build-helper.sh:/build-helper.sh:ro "
docker_args+="-e USER=$(id -u) -e GROUP=$(id -g) "
docker_args+="--rm "
image="deb-builder:$osver"
cmd="docker run -it $docker_args $image /build-helper.sh $v $patch"

echo "Running docker:"
echo "$cmd"

eval "$cmd"
