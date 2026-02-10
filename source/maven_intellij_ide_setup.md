# Maven + IntelliJ IDEA Setup & Verification (Ubuntu / Linux)

This guide documents **exactly** how to install, configure, and verify Apache Maven so it works **both in your system terminal and inside IntelliJ IDEA**.

It is written based on a real debugging session where:

* Maven worked in system terminal
* ❌ but **failed inside IntelliJ terminal**
* ❌ dependencies showed red / “not found” even though `mvn clean install` succeeded

---

## 0. Prerequisites

* OS: Ubuntu / Linux
* Java: **Java 17** (required for modern libraries)
* IntelliJ IDEA (Community or Ultimate)

Verify Java first:

```bash
java -version
```

Expected:

```
openjdk version "17.x"
```

---

## 1. DO NOT use Ubuntu default Maven

Ubuntu ships **very old Maven** (3.6.x) which causes:

* fake “dependency not found” errors
* missing POM warnings
* IntelliJ autocomplete failures

### ❌ Wrong

```bash
sudo apt install maven
```

### ✅ Correct approach: install Maven manually

---

## 2. Install modern Maven (3.9.x)

### Download

```bash
cd /tmp
wget https://archive.apache.org/dist/maven/maven-3/3.9.8/binaries/apache-maven-3.9.8-bin.tar.gz
```

### Extract

```bash
sudo tar -xzf apache-maven-3.9.8-bin.tar.gz -C /opt
```

### Create symlink

```bash
sudo ln -s /opt/apache-maven-3.9.8 /opt/maven
```

---

## 3. Configure PATH (IMPORTANT)

If you install Maven manually (not via `apt`), you **must** add Maven to your PATH so that both your system terminal and IntelliJ can find `mvn`.

### 3.1 Add Maven to `~/.profile`

Open your profile file:

```bash
nano ~/.profile
```

Add this at the **bottom**:

```bash
# Maven
export MAVEN_HOME=/opt/maven
export PATH="$MAVEN_HOME/bin:$PATH"
```

Save and exit, then reload:

```bash
source ~/.profile
```

⚠️ Why `.profile`?

* `.profile` is loaded for **login shells**
* IntelliJ terminal inherits environment from it
* More reliable than `.bashrc` for GUI apps

---

## 4. Configure PATH (CRITICAL)

Add Maven to PATH **once**.

Edit shell config:

```bash
nano ~/.bashrc
```

Add:

```bash
export MAVEN_HOME=/opt/maven
export PATH=$MAVEN_HOME/bin:$PATH
```

Reload:

```bash
source ~/.bashrc
```

Verify:

```bash
mvn -version
```

Expected:

```
Apache Maven 3.9.8
Java version: 17
```

---

## 4. Verify Maven Central access

Run:

```bash
mvn help:effective-settings
```

Ensure Maven Central is present:

```xml
<mirror>
  <id>central</id>
  <url>https://repo.maven.apache.org/maven2</url>
</mirror>
```

📌 `~/.m2/settings.xml` is **optional**. Maven works without it.

---

## 5. IntelliJ IDEA configuration

### 5.1 Ensure IntelliJ uses system Maven

Open:

```
Settings → Build, Execution, Deployment → Build Tools → Maven
```

Set:

* **Maven home path** → `/opt/maven`
* **User settings file** → (empty is fine)
* **Local repository** → `~/.m2/repository`

Apply & OK.

---

### 5.2 Verify Maven repositories in IntelliJ

Go to:

```
Settings → Build Tools → Maven → Repositories
```

You should see:

* Local: `~/.m2/repository`
* Remote: `https://repo.maven.apache.org/maven2`

If present → ✅ valid

---

## 6. Fix IntelliJ terminal “mvn not found”

### Symptom

* `mvn` works in normal terminal
* ❌ `mvn` NOT found in IntelliJ terminal

### Root cause

IntelliJ terminal **does not source ~/.bashrc** by default.

### Fix

Go to:

```
Settings → Tools → Terminal
```

Set **Shell path** to:

```bash
/bin/bash --login
```

Restart IntelliJ completely.

Verify inside IntelliJ terminal:

```bash
echo $PATH
mvn -version
```

Expected: `/opt/maven/bin` is present.

---

## 7. Create a minimal sanity-check project

### pom.xml

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>maven-check</artifactId>
  <version>1.0-SNAPSHOT</version>

  <properties>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
  </properties>

  <dependencies>
    <dependency>
      <groupId>com.fasterxml.jackson.core</groupId>
      <artifactId>jackson-databind</artifactId>
      <version>2.17.2</version>
    </dependency>
  </dependencies>
</project>
```

Run:

```bash
mvn clean install
```

Expected:

```
BUILD SUCCESS
```

---

## 8. IntelliJ shows red dependencies but build works?

This means:

* Maven CLI is correct ✅
* IntelliJ index is stale ❌

### Fix

1. Right-click `pom.xml`
2. **Maven → Reload Project**
3. Or click the 🔄 icon in Maven tool window

If still red:

```bash
rm -rf ~/.m2/repository/com/fasterxml
mvn clean install
```

---

## 9. Final verification checklist

✅ `mvn -version` shows **3.9.x**

✅ `java -version` shows **17**

✅ `mvn clean install` works:

* system terminal
* IntelliJ terminal

✅ Dependencies autocomplete works in `pom.xml`

✅ IntelliJ no longer shows false “dependency not found”

---

## 10. Key lessons (important)

* Maven errors can be **tooling**, not dependency issues
* Old Maven versions break modern ecosystems silently
* IntelliJ terminal ≠ system terminal
* Always verify CLI first, IDE second

---

🎉 **Maven is now correctly configured and production-ready.**

This setup is solid for:

* Kafka projects
* Jackson
* Java 17
* Production builds
