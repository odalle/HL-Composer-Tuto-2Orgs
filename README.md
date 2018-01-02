# HyperLedger Composer Automated Multi Orgs Tutorial

This small script runs the [HyperLedger Composer Multi-Orgs tutorial](https://hyperledger.github.io/composer/tutorials/deploy-to-fabric-multi-org.html). It is provided as a mean for identifying some reproducibility issues but it can also serve as a cheat sheet.

This script was tested on MacOS with both [DockerToolbox](https://docs.docker.com/toolbox/toolbox_install_mac/) and [Docker for Mac](https://docs.docker.com/docker-for-mac/).

## INSTALL INSTRUCTIONS

Prior to running the script, you should first follow [these install instructions](https://hyperledger.github.io/composer/installing/development-tools.html) for HyperLedger Composer.

Installing the [Node Version Manager](https://github.com/creationix/nvm) is also a good idea. With nvm, you just need to ensure that you are using the `lts/carbon` version of node. Run this command once prior to running the script:

```bash
$ nvm use lts/carbon
```

Then simply clone this repo and ensure you have docker started. It is recommended to provision docker engine with 4 CPU and 8 GiB RAM, but 1 CPU and 2 GiB should be sufficient.

Once it's downloaded, remember to set the execution permissions on the script:

```bash
$ chmod a+x ./setup.sh
```

## HOW TO USE

Run the follwowing command and wait for the large "END" message to be printed (example below) then press the enter key (bnut *NOT* before the END message!). Note: the first time, depending on your internet connection, it may take a few minutes to get the END message, because several docker image have to be downloaded.

```bash
$ ./setup.sh
```

```
   ... previous traces cut out ...
2017-12-31 09:07:30.998 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 004 Using default vscc
2017-12-31 09:07:30.998 UTC [msp/identity] Sign -> DEBU 005 Sign: plaintext: 0A95070A6708031A0C08D2D1A2D20510...6D7963631A0A0A0571756572790A0161
2017-12-31 09:07:30.998 UTC [msp/identity] Sign -> DEBU 006 Sign: digest: 30820404D6758116D275BF4A39966BC4D1C494A5D25C4B7539286D189E1FCFA3
Query Result: 90
2017-12-31 09:08:04.464 UTC [main] main -> INFO 007 Exiting.....
===================== Query on PEER3 on channel 'mychannel' is successful =====================

========= All GOOD, BYFN execution completed ===========


 _____   _   _   ____
| ____| | \ | | |  _ \
|  _|   |  \| | | | | |
| |___  | |\  | | |_| |
|_____| |_| \_| |____/
```

You can follow the execution of docker containers using the following command:

```bash
$ docker stats --all --format "table {{.Container}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
```

At the end of normal execution, you should see the following message:

```bash
================ STEP: NINETEEN ==============

Successfully created business network card file to
        Output file: bob@tutorial-network.card

Command succeeded


Successfully imported business network card
        Card file: bob@tutorial-network.card
        Card name: bob@tutorial-network

Command succeeded

The connection to the network was successfully tested: tutorial-network
        version: 0.16.0
        participant: org.hyperledger.composer.system.NetworkAdmin#bob

Command succeeded
```

and the docker stats will show the following containers running:

```
CONTAINER           NAME                                                 CPU %               MEM USAGE / LIMIT     NET I/O             BLOCK I/O
ee16cca40529        dev-peer1.org2.example.com-mycc-1.0                  0.00%               2.969MiB / 1.955GiB   6.15kB / 1.94kB     573kB / 0B
93e483f56354        dev-peer0.org1.example.com-mycc-1.0                  0.00%               3.027MiB / 1.955GiB   8.19kB / 2.92kB     799kB / 0B
21e9324e1d28        dev-peer0.org2.example.com-mycc-1.0                  0.00%               3.066MiB / 1.955GiB   6.57kB / 2.2kB      201kB / 0B
ae4522711efb        cli                                                  0.00%               144KiB / 1.955GiB     67.4kB / 129kB      32.7MB / 193kB
629b8ebc9b5b        peer1.org1.example.com                               7.08%               108.9MiB / 1.955GiB   7.82MB / 4.84MB     39.6MB / 262kB
e1c3f06c8aa3        peer1.org2.example.com                               6.79%               123.3MiB / 1.955GiB   7.78MB / 4.75MB     26.7MB / 262kB
e090d78348a4        peer0.org1.example.com                               8.28%               114.6MiB / 1.955GiB   8.07MB / 5.03MB     43.5MB / 262kB
4fc534feef7a        peer0.org2.example.com                               5.93%               104.6MiB / 1.955GiB   7.8MB / 4.79MB      18.9MB / 262kB
1a91dd3040b5        couchdb3                                             0.60%               18.92MiB / 1.955GiB   205kB / 278kB       4.55MB / 1.32MB
f557fc4d073a        orderer.example.com                                  0.00%               11.07MiB / 1.955GiB   156kB / 451kB       17.5MB / 246kB
4ccc3cfcf904        couchdb1                                             0.99%               22.06MiB / 1.955GiB   203kB / 273kB       5.33MB / 1.32MB
8cc66fea9f4e        couchdb0                                             1.27%               20MiB / 1.955GiB      221kB / 351kB       9.02MB / 1.47MB
5a3fbb2cb101        ca_peerOrg2                                          0.00%               72KiB / 1.955GiB      4.75kB / 4.15kB     0B / 311kB
35912b6943f0        ca_peerOrg1                                          0.00%               44KiB / 1.955GiB      4.75kB / 4.16kB     594kB / 360kB
647ccce97790        couchdb2                                             0.63%               31.95MiB / 1.955GiB   217kB / 342kB       23.9MB / 1.37MB
0824880cc5d8        dev-peer1.org1.example.com-tutorial-network-0.16.0   2.26%               92.27MiB / 1.955GiB   103kB / 97kB        28.7kB / 209kB
1d1b7d2b1727        dev-peer0.org1.example.com-tutorial-network-0.16.0   6.63%               131.6MiB / 1.955GiB   156kB / 116kB       0B / 193kB
d705877fa185        dev-peer1.org2.example.com-tutorial-network-0.16.0   1.94%               80.38MiB / 1.955GiB   104kB / 96.8kB      0B / 0B
dbc4e54ba08a        dev-peer0.org2.example.com-tutorial-network-0.16.0   4.24%               147.5MiB / 1.955GiB   156kB / 115kB       0B / 0B
```


Once you are done testing, you can stop containers and cleanup using the following command:

```bash
$ ./setup.sh down
```

## NOTE

When running this script, the following error can occur during the last two steps.

```
================ STEP: EIGHTEEN ==============

Successfully created business network card file to
        Output file: alice@tutorial-network.card

Command succeeded


Successfully imported business network card
        Card file: alice@tutorial-network.card
        Card name: alice@tutorial-network

Command succeeded

Error: Error trying to ping. Error: Error trying to query business network. Error: Failed to deserialize creator identity, err The supplied identity is not valid, Verify() returned x509: certificate has expired or is not yet valid
Command failed

================ STEP: NINETEEN ==============

Successfully created business network card file to
        Output file: bob@tutorial-network.card

Command succeeded


Successfully imported business network card
        Card file: bob@tutorial-network.card
        Card name: bob@tutorial-network

Command succeeded

Error: Error trying to ping. Error: Error trying to query business network. Error: Failed to deserialize creator identity, err The supplied identity is not valid, Verify() returned x509: certificate has expired or is not yet valid
Command failed
```

The issue is being reported.