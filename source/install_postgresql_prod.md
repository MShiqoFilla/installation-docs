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


---

---


# Exposing a Local PostgreSQL Database to Other Machines (LAN & VPN)

This guide explains **how to allow other machines to connect to your local PostgreSQL database**, either over **local network (LAN)** or via **VPN**.

> ⚠️ **Security note**: Do **NOT** expose PostgreSQL directly to the public internet. This tutorial is intended for **internal network, office, or VPN usage only**.

---

## 1. Prerequisites

* PostgreSQL installed and running
* You can connect locally using:

```bash
psql -U <user> -d <database>
```

* You have **sudo** access to the machine
* VPN client configured if you plan to use VPN

---

## 2. Identify Your Machine IP Address

Run:

```bash
ip addr
```

Look for interfaces with `inet` IPs. Typical candidates:

* `lo` → 127.0.0.1 (ignore, local only)
* Wi-Fi / Ethernet (`wlp0s20f3`, `enp0s31f6`) → local LAN IP (office network)
* VPN interface (`tun0`) → VPN network IP

### Example (LAN active):

```
wlp0s20f3: inet 10.1.20.95/18
```

### Example (VPN active):

```
tun0: inet 10.0.128.13/17
```

**Tip:** Test reachability from the client:

```bash
ping <candidate IP>
nc -vz <candidate IP> 5432  # test PostgreSQL port
```

Choose the IP that responds / is reachable.

* **LAN access:** use your Wi-Fi/Ethernet IP
* **VPN access:** use your VPN interface IP (`tun0`)

---

## 3. Configure PostgreSQL to Listen on All Interfaces

Edit `postgresql.conf`:

```bash
sudo nano /etc/postgresql/14/main/postgresql.conf
```

Set:

```conf
listen_addresses = '*'
```

Restart PostgreSQL:

```bash
sudo systemctl restart postgresql
```

Verify PostgreSQL is listening:

```bash
ss -lntp | grep 5432
```

Expected output:

```text
0.0.0.0:5432
[::]:5432
```

---

## 4. Allow Remote Clients in `pg_hba.conf`

Edit:

```bash
sudo nano /etc/postgresql/14/main/pg_hba.conf
```

Add a rule for the reachable IP or subnet:

### For LAN access:

```conf
host my_localdb shiqo 10.1.20.0/18 md5
```

### For VPN access:

```conf
host my_localdb shiqo 10.0.128.0/17 md5
```

Or allow a single IP:

```conf
host my_localdb shiqo 10.1.20.95/32 md5  # LAN
host my_localdb shiqo 10.0.128.13/32 md5 # VPN
```

Reload PostgreSQL:

```bash
sudo systemctl reload postgresql
```

---

## 5. Set / Verify User Password

Connect locally:

```bash
psql -U postgres
```

Set password:

```sql
ALTER USER shiqo WITH PASSWORD 'strong_password_here';
```

Exit:

```sql
\q
```

---

## 6. Connect from Another Machine (CLI)

Use the IP you verified as reachable:

### LAN example:

```bash
psql -h 10.1.20.95 -U shiqo -d my_localdb -W
```

### VPN example:

```bash
psql -h 10.0.128.13 -U shiqo -d my_localdb -W
```

> Ping may fail due to firewall/ICMP restrictions, but PostgreSQL TCP connection works if allowed.

---

## 7. Connect Using DBeaver

**Connection settings:**

* Host: LAN or VPN IP
* Port: 5432
* Database: `my_localdb`
* Username: `shiqo`
* Password: your password

Click **Test Connection** → should succeed.

---

## 8. Common Errors & Fixes

### ❌ `no pg_hba.conf entry for host ...`

* Cause: Client IP not allowed
* Fix: Add the client IP/subnet to `pg_hba.conf`, reload PostgreSQL

### ❌ Works on one network, fails on another

* Cause: Client IP changed (Wi-Fi / hotspot / VPN)
* Fix: Use correct interface IP in `pg_hba.conf` and client connection; consider SSH tunnel or VPN

---

## 9. Understanding `/24` vs `/32`

| CIDR  | Meaning                      |
| ----- | ---------------------------- |
| `/32` | Single IP only (most secure) |
| `/24` | 256 IPs (same subnet)        |
| `/16` | 65k IPs (use carefully)      |

Recommended:

* Single machine → `/32`
* Office LAN or VPN subnet → `/24` or `/17` depending on network size

---

## 10. Recommended Safer Alternatives

* SSH tunnel (works regardless of dynamic IP)
* VPN (Tailscale, WireGuard)
* Docker + internal network

---

## 11. Quick Checklist

* [x] PostgreSQL running
* [x] `listen_addresses = '*'`
* [x] `pg_hba.conf` updated for reachable IP/subnet (LAN and/or VPN)
* [x] Password set
* [x] Port 5432 listening
* [x] Client can reach server IP (LAN or VPN)

---

## Done ✅

Your local PostgreSQL is now accessible from other machines **over LAN or VPN** securely.
