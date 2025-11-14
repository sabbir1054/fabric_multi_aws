### Water Sensor Ranking By Hyper Ledger Fabric

---

#### Clone the repository then follow the steps

> [!IMPORTANT]
>
> ### Install node js on your system
>
> Link: https://nodejs.org/en

> [!TIP]
> Run different project in different terminal tab.

#### 1. Run Hyper Ledger Fabric

- Open Fabric Sample Folder and Open Terminal
- Install script

```
curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x install-fabric.sh

```

- To pull the Docker containers

```
./install-fabric.sh docker samples binary
```

- Go to test-network folder

```
cd test-network
```

- For safety purpose down docker container of test network

```
./network.sh down
```

- Run docker container

```
./network.sh up
```

- Create Channel

```
./network.sh createChannel
```

- Now Deploy Chain code to the network

```
 ./network.sh deployCC -ccn SensorContract -ccp ../asset-transfer-basic/chaincode-typescript -ccl typescript
```

---

#### 2. Run Node js Express Backend

- Open ph_water_backend folder and open another terminal
- Install yarn

```
npm i -g yarn
```

- Install node modules

```
yarn install
```

- Run project in development

```
yarn dev
```

---

#### 3. Run React Frontend

- Open ph_water_frontend folder in another terminal
- Install yarn

```
npm i -g yarn
```

- Install node modules

```
yarn install
```

- Run project in development

```
yarn dev
```
