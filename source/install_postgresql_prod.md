# PostgreSQL Production Installation & Hardening (Linux)

> This guide covers a **production‑ready PostgreSQL setup** on Linux (Ubuntu/Debian style). It intentionally separates **admin**, **application**, and **network access**, and avoids unsafe defaults.

---

## 1. Install PostgreSQL

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install postgresql postgresql-contrib -y
```

Verify versions:

```bash
psql -V
sudo -u postgres psql -c "SELECT version();"
```

---

## 2. Ensure PostgreSQL Is Running

```bash
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl status postgresql
```

---

## 3. Initial Admin Access (Superuser)

```bash
sudo -i -u postgres
psql
```

You are now logged in as the **PostgreSQL superuser**. Use this role **only for administration**.

---

## 4. Create Application Role and Database

> Do **not** use `postgres` for applications.

```sql
CREATE USER shiqo WITH PASSWORD 'STRONG_RANDOM_PASSWORD';
CREATE DATABASE mydb OWNER shiqo;
```

Optional: restrict public access

```sql
REVOKE ALL ON DATABASE mydb FROM PUBLIC;
GRANT ALL ON DATABASE mydb TO shiqo;
```

---

## 5. Authentication Configuration (pg_hba.conf)

Find the active file:

```bash
sudo -u postgres psql -c "SHOW hba_file;"
```

### ✅ Safe Production Defaults

```conf
# Local admin access
local   all         postgres                    peer

# Local application access (password)
local   mydb        shiqo                       md5

# TCP access from localhost
host    mydb        shiqo       127.0.0.1/32    md5

# Example: internal network (adjust CIDR)
# host  mydb        shiqo       10.0.0.0/24     md5
```

⚠️ **Do NOT** use:

```conf
local   all   all   md5
```

Restart:

```bash
sudo systemctl restart postgresql
```

---

## 6. Network Configuration (postgresql.conf)

Locate the file:

```bash
sudo -u postgres psql -c "SHOW config_file;"
```

Edit and set:

```conf
listen_addresses = 'localhost'
```

For remote access (explicit networks only):

```conf
listen_addresses = '*'
```

Restart required after changes.

---

## 7. Application Connection Test

From shell:

```bash
psql -h 127.0.0.1 -U shiqo -d mydb -W
```

Verify:

```sql
SELECT current_user, current_database(), inet_client_addr();
```

---

## 8. Least‑Privilege Rules

### ❌ Avoid for app users

```sql
ALTER ROLE shiqo CREATEDB;
ALTER ROLE shiqo SUPERUSER;
```

### ✅ Create a migration/admin role if needed

```sql
CREATE ROLE mydb_admin LOGIN PASSWORD 'STRONG_PASSWORD' CREATEDB;
GRANT ALL PRIVILEGES ON DATABASE mydb TO mydb_admin;
```

---

## 9. Logging (Minimum Production Baseline)

In `postgresql.conf`:

```conf
log_connections = on
log_disconnections = on
log_statement = 'ddl'
log_line_prefix = '%m [%p] %u@%d '
```

---

## 10. Backups (Mandatory)

### Manual backup

```bash
pg_dump -U shiqo -h 127.0.0.1 mydb > mydb.sql
```

### Restore

```bash
psql -U shiqo -h 127.0.0.1 mydb < mydb.sql
```

Automate backups via `cron` or systemd timers.

---

## 11. Production Checklist

* [ ] App user is **not** superuser
* [ ] `postgres` role uses **peer authentication only**
* [ ] Password authentication scoped by **database + role + CIDR**
* [ ] No `local   all   all   md5` rule exists
* [ ] `listen_addresses` explicitly configured (not implicit defaults)
* [ ] Remote access restricted to trusted networks only
* [ ] Backups configured and **restore tested**
* [ ] Logging enabled (connections + DDL at minimum)
* [ ] PostgreSQL major version documented
* [ ] Credentials stored securely (env vars / secret manager)

---

## 12. Recommended References

* PostgreSQL Authentication Methods
* PostgreSQL Role Management
* pg_hba.conf documentation
* pg_dump / pg_restore

---

**Rule of thumb:**

> If a setting is convenient but global — it is probably unsafe for production.
