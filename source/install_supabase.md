# Supabase Installation and Set Up


## Getting the source code
```bash
# Get the code
git clone --depth 1 https://github.com/supabase/supabase

# Make your new supabase project directory
mkdir supabase-project

# Tree should look like this
# .
# ├── supabase
# └── supabase-project

# Copy the compose files over to your project
cp -rf supabase/docker/* supabase-project

# Copy the fake env vars
cp supabase/docker/.env.example supabase-project/.env

# Switch to your project directory
cd supabase-project

# Pull the latest images
docker compose pull
```

## Generate Keys needed
```bash
sh ./utils/generate-keys.sh
```
This command will auto generate and put these needed keys in `.env` file:
* POSTGRES_PASSWORD
* JWT_SECRET
* ANON_KEY
* SERVICE_ROLE_KEY

## Start the service
```bash
docker compose up -d
```


## Accessing Supabase Studio (UI)

You can access Supabase Studio through the API gateway on port 8000. You will be prompted for a username and password. Use username and password that is set in .env file: `DASHBOARD_USERNAME` and `DASHBOARD_PASSWORD`.


## Accessing Postgres by default pooling
By default, the Supabase stack provides the Supavisor connection pooler for accessing Postgres and managing database connections.

You can connect to the Postgres database via Supavisor using the methods described below. Use your domain name, your server IP, or localhost depending on whether you are running self-hosted Supabase on a VPS, or locally.

The default POOLER_TENANT_ID is your-tenant-id (can be changed in .env), and the password is the one you set previously in Configure database password.

For session-based connections (equivalent to a direct Postgres connection):

```bash
psql 'postgres://postgres.[POOLER_TENANT_ID]:[POSTGRES_PASSWORD]@[your-domain]:5432/postgres'```

For pooled transactional connections:

```bash
psql 'postgres://postgres.[POOLER_TENANT_ID]:[POSTGRES_PASSWORD]@[your-domain]:6543/postgres'
```

When using psql with command-line parameters instead of a connection string to connect to Supavisor, the -U parameter should also be postgres.[POOLER_TENANT_ID], and not just postgres.


## Exposing Postgres 

> This is actual recommendation from official documentation of supabase

By default, Postgres is only accessible through Supavisor. If you need direct access to the database (bypassing the connection pooler), you need to disable Supavisor and expose the Postgres port.

Exposing Postgres directly bypasses connection pooling and exposes your database to the network. Configure firewall rules or network policies to restrict access to trusted IPs only.

Edit docker-compose.yml:

* Disable Supavisor - Comment out or remove the entire supavisor service section
* Expose Postgres port - Add the port mapping to the db service, it should look like the example below:

```yaml
db:
  ports:
    - ${POSTGRES_PORT}:${POSTGRES_PORT}
  container_name: supabase-db
```

After restarting, you can connect to the database directly using a standard Postgres connection string:

```postgres://postgres:[POSTGRES_PASSWORD]@[your-server-ip]:5432/[POSTGRES_DB]```


## Exposing Postgres without terminating Supavisor

You can still exposing Postgres without the need to terminate Supavisor container, but you need to redirect the port of exposed postgres, for example from 5432 to 5433.

Find on the docker-compose.yml,

```yaml
db:
    container_name: supabase-db
```
and then add ports redirection, like this.
```yaml
  db:
    container_name: supabase-db
    ports:
      - "5433:5432"
```

Now you can connect to DB with this connection string

```
postgres://postgres:[POSTGRES_PASSWORD]@[your-server-ip]:5433/[POSTGRES_DB]``
```

Notice that you don't need to add `your-tenant-id` value in the username part, unlike using pooled connection by supavisor, but you still can also connect to postgres that way since you dont terminate the supavisor service, just use port 5432.

## More
Read more detailed documentation in:
https://supabase.com/docs/guides/self-hosting/docker