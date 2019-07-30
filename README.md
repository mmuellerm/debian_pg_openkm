# debian_pg_openkm
Dockerfile for an image for document management system 'OpenKM' based on Debian using Postgres database

# usage:
For using this image you have to build your own image because you must replace the parameters for the database user, password and host in the image with concrete values.

# example:
docker build -t my-openkm --build-arg=PG_USERNAME="openkm" --build-arg=PG_PASSWORD="*secret*" --build-arg=PG_HOST="postgres-host" .

This example needs a simple dockerfile in the current directory containing only one line:

FROM mmuellerm/openkm-debian-pg


After building the image you can create your container:

docker create --name openkm -p 8080:8080 my-openkm


This example requires a host with name "postgres-host" and a running postgres instance. It must contains a database 'okmdb' and a database user "openkm" with password "*secret*" with full access rights to the database 'okmdb'.
