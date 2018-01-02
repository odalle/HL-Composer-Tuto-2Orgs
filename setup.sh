#!/bin/bash
#nvm use lts/carbon
# Usage: ./setup.sh [down]


# On MAC OS with "docker tools" instead of "docker for mac"
# the docker machine is hosted in a VirtualBox VM whose
# address is not localhost but found in the DOCKER_HOST
# Variable 
if [ "${DOCKER_HOST}x" == "x" ] ; then
    export DOCKER_HOST_IP=localhost
else
    export DOCKER_HOST_IP=`echo $DOCKER_HOST | cut -d '/' -f 3 | cut -d: -f1`
fi
export ARCH=$(uname -m)
export VERSION=1.0.5
# Unsure if this is needed
export COMPOSER_TLS=true

# Load images once and save in local dir to avoid redownloading when running multiple times
function load_images() {
    if [ ! -d images ] ; then
        mkdir images
        for i in ca	couchdb	orderer	peer tools ; do 
            docker pull hyperledger/fabric-$i:$ARCH-$VERSION
            docker save hyperledger/fabric-$i:$ARCH-$VERSION -o images/$i-$VERSION.tar
        done
    fi
    
}

# Cleanup docker and composer dir to rpepare for a new run
# Call this using "./setup.sh down"
function down() {
    echo "================ DOWN ======================"
    rm -rf fabric-samples
    docker ps -aq | xargs docker kill
    docker ps -aq | xargs docker rm
    docker images -aq | xargs docker rmi 
    #docker images | grep dev | awk '{print $3}' | xargs docker rmi
    #docker images | grep baseos | awk '{print $3}' | xargs docker rmi
    #docker images | grep fabric-ca | awk '{print $3}' | xargs docker rmi
    yes | docker volume prune
    yes | docker system prune
    load_images
    rm -rf ~/.composer/cache
    rm -rf ~/.composer/client-data
}

# Automatically called if fabric-samples dir is missing
# Automatically change docker-compose yaml files to set to a specific version of fabric
function prepare_source() {
    echo "================ PREPARE ======================"
    down
    git clone -b issue-6978 https://github.com/sstone1/fabric-samples.git
    # Replace "image: image-without-version" with  eg. "image: image-without-version:x86_64-1.0.5" 
    find fabric-samples/first-network -name '*.yaml' -exec sed -i .orig -e "s/\(image:.*$\)/\1:$ARCH-$VERSION/g" \{\} \;
    # copy to clone dir and get ready to execute from there
    cp $0 fabric-samples/first-network
    cp tutorial-network@0.0.1.bna fabric-samples/first-network || exit 1
    for i in ca	couchdb	orderer	peer tools ; do 
        docker load -i images/$i-$VERSION.tar
    done
    cd fabric-samples/first-network
    exec $0
}

function pre_requisite() {
    echo "================ PREREQUISITE ======================"
    
    rm -rf crypto-config
    rm -rf PeerAdmin@byfn-* connection-*.json byfn.pid alice bob *.card
    yes | ./byfn.sh -m down
    yes | ./byfn.sh -m generate
    yes | ./byfn.sh -m up -s couchdb -a & echo $! > /tmp/byfn$$.pid
    read rep
    PID=$(cat /tmp/byfn$$.pid)
    # Wait for byfn's end message on output and press enter
    #  _____   _   _   ____
    # | ____| | \ | | |  _ \
    # |  _|   |  \| | | | | |
    # | |___  | |\  | | |_| |
    # |_____| |_| \_| |____/
    #
    kill $PID
    rm -f /tmp/byfn$$.pid
}


function step_one() {
    echo "================ STEP: ONE   ======================"
    composer card delete -n PeerAdmin@byfn-network-org1-only
    composer card delete -n PeerAdmin@byfn-network-org1
    composer card delete -n PeerAdmin@byfn-network-org2-only
    composer card delete -n PeerAdmin@byfn-network-org2
    composer card delete -n alice@tutorial-network
    composer card delete -n bob@tutorial-network
    composer card delete -n admin@tutorial-network
    composer card delete -n PeerAdmin@fabric-network
}

function step_two {
    echo "================ STEP: TWO ======================"
    export ORD_CA_CERT="crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
    export ORG1_CA_CERT="crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    export ORG2_CA_CERT="crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
    export ORG1_MSP_DIR="crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    export ORG2_MSP_DIR="crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"

}

function step_three {
    echo "================ STEP: THREE ===================="
    cat > connection-org1-only.json << EOF1
{
    "name": "byfn-network-org1-only",
    "type": "hlfv1",
    "mspID": "Org1MSP",
    "peers": [
        {
            "requestURL": "grpcs://${DOCKER_HOST_IP}:7051",
            "eventURL": "grpcs://${DOCKER_HOST_IP}:7053",
            "cert": "$ORG1_CA_CERT",
            "hostnameOverride": "peer0.org1.example.com"
        },
        {
            "requestURL": "grpcs://${DOCKER_HOST_IP}:8051",
            "eventURL": "grpcs://${DOCKER_HOST_IP}:8053",
            "cert": "$ORG1_CA_CERT",
            "hostnameOverride": "peer1.org1.example.com"
        }
    ],
    "ca": {
        "url": "https://${DOCKER_HOST_IP}:7054",
        "name": "ca-org1",
        "cert": "$ORG1_CA_CERT",
        "hostnameOverride": "ca.org1.example.com"
    },
    "orderers": [
        {
            "url" : "grpcs://${DOCKER_HOST_IP}:7050",
            "cert": "$ORD_CA_CERT",
            "hostnameOverride": "orderer.example.com"
        }
    ],
    "channel": "mychannel",
    "timeout": 300
}
EOF1

    cat > connection-org1.json << EOF2
{
    "name": "byfn-network-org1",
    "type": "hlfv1",
    "mspID": "Org1MSP",
    "peers": [
        {
            "requestURL": "grpcs://${DOCKER_HOST_IP}:7051",
            "eventURL": "grpcs://${DOCKER_HOST_IP}:7053",
            "cert": "$ORG1_CA_CERT",
            "hostnameOverride": "peer0.org1.example.com"
        },
        {
            "requestURL": "grpcs://${DOCKER_HOST_IP}:8051",
            "eventURL": "grpcs://${DOCKER_HOST_IP}:8053",
            "cert": "$ORG1_CA_CERT",
            "hostnameOverride": "peer1.org1.example.com"
        },
        {
            "requestURL": "grpcs://${DOCKER_HOST_IP}:9051",
            "cert": "$ORG2_CA_CERT",
            "hostnameOverride": "peer0.org2.example.com"
        },
        {
            "requestURL": "grpcs://${DOCKER_HOST_IP}:10051",
            "cert": "$ORG2_CA_CERT",
            "hostnameOverride": "peer1.org2.example.com"
        }
    ],
    "ca": {
        "url": "https://${DOCKER_HOST_IP}:7054",
        "name": "ca-org1",
        "cert": "$ORG1_CA_CERT",
        "hostnameOverride": "ca.org1.example.com"
    },
    "orderers": [
        {
            "url" : "grpcs://${DOCKER_HOST_IP}:7050",
            "cert": "$ORD_CA_CERT",
            "hostnameOverride": "orderer.example.com"
        }
    ],
    "channel": "mychannel",
    "timeout": 300
}
EOF2

}

function step_four() {
    echo "================ STEP: FOUR  ===================="
    cat > connection-org2-only.json << EOF3
{
    "name": "byfn-network-org2-only",
    "type": "hlfv1",
    "mspID": "Org2MSP",
    "peers": [
        {
            "requestURL": "grpcs://${DOCKER_HOST_IP}:9051",
            "eventURL": "grpcs://${DOCKER_HOST_IP}:9053",
            "cert": "$ORG2_CA_CERT",
            "hostnameOverride": "peer0.org2.example.com"
        },
        {
            "requestURL": "grpcs://${DOCKER_HOST_IP}:10051",
            "eventURL": "grpcs://${DOCKER_HOST_IP}:10053",
            "cert": "$ORG2_CA_CERT",
            "hostnameOverride": "peer1.org2.example.com"
        }
    ],
    "ca": {
        "url": "https://${DOCKER_HOST_IP}:8054",
        "name": "ca-org2",
        "cert": "$ORG2_CA_CERT",
        "hostnameOverride": "ca.org2.example.com"
    },
    "orderers": [
        {
            "url" : "grpcs://${DOCKER_HOST_IP}:7050",
            "cert": "$ORD_CA_CERT",
            "hostnameOverride": "orderer.example.com"
        }
    ],
    "channel": "mychannel",
    "timeout": 300
}
EOF3

    cat > connection-org2.json << EOF4
{
    "name": "byfn-network-org2",
    "type": "hlfv1",
    "mspID": "Org2MSP",
    "peers": [
        {
            "requestURL": "grpcs://${DOCKER_HOST_IP}:9051",
            "eventURL": "grpcs://${DOCKER_HOST_IP}:9053",
            "cert": "$ORG2_CA_CERT",
            "hostnameOverride": "peer0.org2.example.com"
        },
        {
            "requestURL": "grpcs://${DOCKER_HOST_IP}:10051",
            "eventURL": "grpcs://${DOCKER_HOST_IP}:10053",
            "cert": "$ORG2_CA_CERT",
            "hostnameOverride": "peer1.org2.example.com"
        },
        {
            "requestURL": "grpcs://${DOCKER_HOST_IP}:7051",
            "cert": "$ORG1_CA_CERT",
            "hostnameOverride": "peer0.org1.example.com"
        },
        {
            "requestURL": "grpcs://${DOCKER_HOST_IP}:8051",
            "cert": "$ORG1_CA_CERT",
            "hostnameOverride": "peer1.org1.example.com"
        }
    ],
    "ca": {
        "url": "https://${DOCKER_HOST_IP}:8054",
        "name": "ca-org2",
        "cert": "$ORG2_CA_CERT",
        "hostnameOverride": "ca.org2.example.com"
    },
    "orderers": [
        {
            "url" : "grpcs://${DOCKER_HOST_IP}:7050",
            "cert": "$ORD_CA_CERT",
            "hostnameOverride": "orderer.example.com"
        }
    ],
    "channel": "mychannel",
    "timeout": 300
}
EOF4

}

function step_five() {
    echo "================ STEP: FIVE  ===================="
    export ORG1_ADMIN_CERT="crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem"
    export ORG1_ADMIN_KEY="`find crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/ -name '*_sk'`"
}

function step_six() {
    echo "================ STEP: SIX  ===================="
    export ORG2_ADMIN_CERT="crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/signcerts/Admin@org2.example.com-cert.pem"
    export ORG2_ADMIN_KEY="`find crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore/ -name '*_sk'`"
}

function step_seven() {
    echo "================ STEP: SEVEN ==================="
    composer card create -p connection-org1-only.json -u PeerAdmin -c $ORG1_ADMIN_CERT -k $ORG1_ADMIN_KEY -r PeerAdmin -r ChannelAdmin
    composer card create -p connection-org1.json -u PeerAdmin -c $ORG1_ADMIN_CERT -k $ORG1_ADMIN_KEY -r PeerAdmin -r ChannelAdmin

}

function step_eight() {
    echo "================ STEP: EIGHT ==================="
    composer card create -p connection-org2-only.json -u PeerAdmin -c $ORG2_ADMIN_CERT -k $ORG2_ADMIN_KEY -r PeerAdmin -r ChannelAdmin
    composer card create -p connection-org2.json -u PeerAdmin -c $ORG2_ADMIN_CERT -k $ORG2_ADMIN_KEY -r PeerAdmin -r ChannelAdmin
}

function step_nine() {
    echo "================ STEP: NINE ==================="
    composer card import -f PeerAdmin@byfn-network-org1-only.card
    composer card import -f PeerAdmin@byfn-network-org1.card
}

function step_ten() {
    echo "================ STEP: TEN ==================="
    composer card import -f PeerAdmin@byfn-network-org2-only.card
    composer card import -f PeerAdmin@byfn-network-org2.card
}

function step_eleven() {
    echo "================ STEP: ELEVEN ================"
    composer runtime install -c PeerAdmin@byfn-network-org1-only -n tutorial-network
}
function step_twelve() {
    echo "================ STEP: TWELVE ================"
    composer runtime install -c PeerAdmin@byfn-network-org2-only -n tutorial-network
}

function step_thirteen() {
    echo "================ STEP: THIRTEEN ============="
    cat > endorsement-policy.json << EOF5
{
    "identities": [
        {
            "role": {
                "name": "member",
                "mspId": "Org1MSP"
            }
        },
        {
            "role": {
                "name": "member",
                "mspId": "Org2MSP"
            }
        }
    ],
    "policy": {
        "2-of": [
            {
                "signed-by": 0
            },
            {
                "signed-by": 1
            }
        ]
    }
}
EOF5
}

function step_forteen() {
    echo "================ STEP: FORTEEN ==============="

}

function step_fifteen() {
    echo "================ STEP: FIFTEEN ==============="
    composer identity request -c PeerAdmin@byfn-network-org1-only -u admin -s adminpw -d alice
    # Does not work better when I move the following instructions here instead of step 18.
    #composer card create -p connection-org1.json -u alice -n tutorial-network -c alice/admin-pub.pem -k alice/admin-priv.pem
    #composer card import -f alice@tutorial-network.card

}

function step_sixteen() {
    echo "================ STEP: SIXTEEN ==============="
    composer identity request -c PeerAdmin@byfn-network-org2-only -u admin -s adminpw -d bob
    #composer card create -p connection-org2.json -u bob -n tutorial-network -c bob/admin-pub.pem -k bob/admin-priv.pem
    #composer card import -f bob@tutorial-network.card
}

function step_seventeen() {
    echo "================ STEP: SEVENTEEN ============="
    composer network start -c PeerAdmin@byfn-network-org1 -a tutorial-network@0.0.1.bna -o endorsementPolicyFile=endorsement-policy.json -A alice -C alice/admin-pub.pem -A bob -C bob/admin-pub.pem
}

function step_eighteen() {
    echo "================ STEP: EIGHTEEN =============="
    composer card create -p connection-org1.json -u alice -n tutorial-network -c alice/admin-pub.pem -k alice/admin-priv.pem
    composer card import -f alice@tutorial-network.card
    composer network ping -c alice@tutorial-network
}

function step_nineteen() {
    echo "================ STEP: NINETEEN =============="
    composer card create -p connection-org2.json -u bob -n tutorial-network -c bob/admin-pub.pem -k bob/admin-priv.pem
    composer card import -f bob@tutorial-network.card
    composer network ping -c bob@tutorial-network
}

if [[ "$1" = "down" ]];then
    down
    exit 0
fi

if [[ ! -f "byfn.sh" && ! -d "fabric-samples" ]]; then
    prepare_source
fi

# Assuming source are already prepared
if [[ -f "byfn.sh" && ! -d "fabric-samples" ]] ; then
    pre_requisite
fi

if [[ ! -f "byfn.sh" ]]; then
    echo "Source missing. Aborting."
    exit 1
fi


step_one
step_two
step_three
step_four
step_five
step_six
step_seven
step_eight
step_nine
step_ten
step_eleven
step_twelve
step_thirteen
step_forteen
step_fifteen
step_sixteen
step_seventeen
step_eighteen
step_nineteen



