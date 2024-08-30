# Data definition
I have made some changes in the schema by adding a new Routes table containing all routes in Prices table and their respective Route_codes (PK). The Prices table has been reduced to 3 columns (route_code, price, and day).

The database used is ```postgresql 16``` as Django Rest Framework on my environment was compatible with postgresql version > 13.

All the related data is driven from the initial tables provided in assignment and should be present in the container image of postgresql db. All the scripts to dump initial data are present in ```rates.sql``` file. After the database is successfully connected, please execute the sripts in ```SQLScripts.sql``` to add the necessary functions.

**Ports**

Information about ports, including:
- 5-character port code
- Port name
- Slug describing which region the port belongs to 

**Regions**

A hierarchy of regions, including:

- Slug - a machine-readable form of the region name
- The name of the region
- Slug describing which parent region the region belongs to

Note that a region can have both ports and regions as children, and the region tree does not have a fixed depth.

**Prices**

Individual daily prices between ports, in USD. Instead of origin and destinations, the table now contains Route_Code (FK from Routes table), price and day.

- Route_code
- The day for which the price is valid
- The price in USD

**Routes**

Individual routes table containing routes.

- Route_Code (Primary Key, an incrementing sequence)
- Origin_Port (FK from Ports)
- Dest_Port (FK from Ports) 

# Initial setup

The docker file provided in the initial assignment is used with its set of data. The version of postgresql is 16 in this dockerfile.

You can execute the provided Dockerfile by running:

```bash
docker build -t ratestask .
```

This will create a container with the name *ratestask*, which you can
start in the following way:

```bash
docker run -p 0.0.0.0:5432:5432 --name ratestask ratestask
```

You can connect to the exposed Postgres instance on the Docker host IP address,
usually *127.0.0.1* or *172.17.0.1*. It is started with the default user `postgres` and `ratestask` password.

```bash
PGPASSWORD=ratestask psql -h 127.0.0.1 -U postgres
```

alternatively, use `docker exec` if you do not have `psql` installed:

```bash
docker exec -e PGPASSWORD=ratestask -it ratestask psql -U postgres
```
Once the database is successfully connected, please execute the scripts on SQLScripts.sql on it to include schema changes and new functions.