# Install PostgreSQL

## Overview

This is my documentation for postgresql installation in LINUX

* Install postgresql 
```bash
sudo apt update
sudo apt upgrade -y
sudo apt install postgresql postgresql-contrib -y
```

* Start postgresql
```bash
sudo service postgresql start
sudo service postgresql status #check status
```

* Switch to postgres superuser
```bash
sudo -i -u postgres
psql
```
Here we logged in to postgresql shell as superuser (postgres), we can create new user by this way.

* Create new user
```sql
CREATE USER shiqo WITH PASSWORD 'password';
CREATE DATABASE mydb OWNER shiqo;
GRANT ALL PRIVILEGES ON DATABASE mydb TO shiqo;
```
That way superuser created a new user `shiqo`, and also created a new database and set user `shiqo` as owner. It also grants all the priviledges to user `shiqo` for that database.

* Set authentication to md5

If you try to login as the new created user
```bash
psql -U shiqo -d mydb -W
``` 
and get `FATAL: Peer authentication failed for user "shiqo"`, then you have to edit `pg_hba.conf`
```bash
sudo nano /etc/postgresql/*/main/pg_hba.conf
```
Find a line like
```bash
local   all             all                                     peer
```
and change into 
```bash
local   all             all                                     md5
```
Restart postgresql:
```bash
sudo service postgresql restart
```
After that you should be able to login to postgresql shell as new user
```bash
psql -U shiqo -d mydb -W
```

* Grant Create Database to user

Go to superuser shell:
```bash
sudo -i -u postgres
psql
```
then inside `psql`
```sql
ALTER ROLE shiqo CREATEDB;
```
Then user `shiqo` should be able able to create database.

## Notes

PostgreSQL Command Line Cheatsheet
* https://quickref.me/postgres.html
* https://gist.github.com/Kartones/dd3ff5ec5ea238d4c546
* https://hasura.io/blog/top-psql-commands-and-flags-you-need-to-know-postgresql