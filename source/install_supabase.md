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

You can access Supabase Studio through the API gateway on port 8000. You will be prompted for a username and password. Use username and password that is set in .env file: `DASHBOARD_USERNAME` and `DASHBOARD_PASSWORD`