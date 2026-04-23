# Cassandra Movie Database

<p align="left">
  <img src="https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white" alt="Python" />
  <img src="https://img.shields.io/badge/Apache%20Cassandra-1287B1?style=flat-square&logo=apachecassandra&logoColor=white" alt="Cassandra" />
  <img src="https://img.shields.io/badge/DataStax%20Astra%20DB-6C4FBB?style=flat-square&logoColor=white" alt="Astra DB" />
  <img src="https://img.shields.io/badge/CQL-Query%20Language-2E86AB?style=flat-square" alt="CQL" />
  <img src="https://img.shields.io/badge/BLOB-Image%20Storage-2E8B57?style=flat-square" alt="BLOB" />
  <img src="https://img.shields.io/badge/TTL-Data%20Expiry-E07B39?style=flat-square" alt="TTL" />
</p>

A NoSQL movie database built with **Apache Cassandra** via **DataStax Astra DB**.

The project covers keyspace and table creation, data insertion with TTL, binary blob storage for movie posters, Python integration, and CQL querying.

---

## Project Overview

This project demonstrates practical use of Apache Cassandra for managing a movie database. Key concepts covered include:

- **Keyspace & Table Design** — Creating a keyspace with replication factor 3 and defining a column-family with complex data types (map, blob)
- **TTL (Time To Live)** — Applying row-level and column-level TTL to control data expiration
- **Blob Storage** — Storing and retrieving movie poster images as binary data using Python
- **Python Integration** — Connecting to Astra DB via the `cassandra-driver` to upload images and query data
- **Query Limitations** — Exploring why `LIKE` and `CONTAINS` operators fail on collection columns, and using application-level filtering instead

---

## Repository Structure

```
Cassandra-Movie-Database/
│
├── README.md
│
├── docs/
│   └── Report.pdf                       # Full project report with screenshots
│
├── posters/
│   ├── Inception.jpeg                   # Movie poster — stored as blob in Cassandra
│   ├── Spider-Man_No_Way_Home.jpeg      # Movie poster — stored as blob in Cassandra
│   └── Home_Alone.jpeg                  # Movie poster — stored as blob in Cassandra
│
├── cql/
│   └── queries.cql                      # All CQL commands (Tasks 1–8)
│
└── python/
    ├── upload_posters.py                # Connects to Astra DB, encodes images to blob, updates DB
    └── query_movies.py                  # Searches movies by actor or director, saves poster locally
```

---

## Database Schema

**Keyspace:** `Movies` — Replication Factor 3, NetworkTopologyStrategy

**Table:** `Movie`

| Column | Type | Description |
|---|---|---|
| `id` | int | Primary key — unique movie identifier |
| `name` | text | Movie title |
| `movie_cast` | map\<text, frozen\<list\<text\>\>\> | Cast info: director(s), actor(s), music |
| `movie_poster` | blob | Movie poster image stored as binary |

---

## Movie Posters

| Inception | Spider-Man: No Way Home | Home Alone |
|---|---|---|
| ![Inception](posters/Inception.jpeg) | ![Spider-Man](posters/Spider-Man_No_Way_Home.jpeg) | ![Home Alone](posters/Home_Alone.jpeg) |

These images are read from the `posters/` folder by `upload_posters.py`, converted to binary (blob), and stored in the `movie_poster` column of the Cassandra database.

---

## CQL Commands

### Task 1 — Keyspace Creation

```sql
CREATE KEYSPACE Movies
WITH replication = {'class': 'NetworkTopologyStrategy', 'eu-west-1': '3'}
AND durable_writes = true;
```

### Task 2 — Table Creation

```sql
USE Movies;

CREATE TABLE Movie (
    id int PRIMARY KEY,
    name text,
    movie_cast map<text, frozen<list<text>>>,
    movie_poster blob
);
```

### Task 3 — Schema Check

```sql
DESCRIBE TABLE Movie;
```

### Task 4 — Insert Movie Data

```sql
-- Inception (with TTL of 7 days = 604800 seconds)
INSERT INTO Movie (id, name, movie_cast)
VALUES (
    1, 'Inception',
    {
        'director' : ['Christopher Nolan'],
        'actors'   : ['Leonardo DiCaprio', 'Joseph Gordon-Levitt', 'Elliot Page'],
        'music'    : ['Hans Zimmer']
    }
) USING TTL 604800;

-- Spider-Man: No Way Home
INSERT INTO Movie (id, name, movie_cast)
VALUES (
    2, 'Spider-Man: No Way Home',
    {
        'director' : ['Jon Watts'],
        'actors'   : ['Tom Holland', 'Zendaya', 'Benedict Cumberbatch'],
        'music'    : ['Michael Giacchino']
    }
);

-- Home Alone
INSERT INTO Movie (id, name, movie_cast)
VALUES (
    3, 'Home Alone',
    {
        'director' : ['Chris Columbus'],
        'actors'   : ['Macaulay Culkin', 'Joe Pesci', 'Daniel Stern'],
        'music'    : ['John Williams']
    }
);

-- Verify
SELECT * FROM Movie;
```

### Task 7 — Update Actors List

```sql
-- Add Andrew Garfield to Spider-Man: No Way Home (id = 2)
UPDATE Movie
SET movie_cast = movie_cast + {'actors': ['Tom Holland', 'Zendaya', 'Benedict Cumberbatch', 'Andrew Garfield']}
WHERE id = 2;
```

### Task 8 — TTL Update and Observation

**Approach 1: Column-Level TTL (columns become null after expiry)**
```sql
UPDATE Movie USING TTL 3
SET name = 'Inception',
    movie_cast = {'actors': ['Leonardo DiCaprio', 'Joseph Gordon-Levitt', 'Elliot Page'],
                  'director': ['Christopher Nolan'],
                  'music': ['Hans Zimmer']}
WHERE id = 1;

-- Query immediately → data exists
-- Query after 3 seconds → name and movie_cast become null, row remains
SELECT id, name, movie_cast FROM Movie;
```

**Approach 2: Row-Level TTL (entire row deleted after expiry)**
```sql
DELETE FROM Movie WHERE id = 1;

INSERT INTO Movie (id, name, movie_cast)
VALUES (1, 'Inception', {'actors': ['Leonardo DiCaprio', 'Joseph Gordon-Levitt', 'Elliot Page'],
                         'director': ['Christopher Nolan'],
                         'music': ['Hans Zimmer']})
USING TTL 3;

-- Query immediately → row exists
-- Query after 3 seconds → entire row is gone
SELECT id, name FROM Movie;
```

---

## Movies Inserted

| ID | Title | Director |
|---|---|---|
| 1 | Inception | Christopher Nolan |
| 2 | Spider-Man: No Way Home | Jon Watts |
| 3 | Home Alone | Chris Columbus |

---

## How to Run

### Requirements
- Python 3.x
- DataStax Astra DB account
- Secure connect bundle (`secure-connect-movies.zip`) from Astra DB
- Astra DB token JSON file with `clientId` and `secret`

### Install Dependencies

```bash
pip install cassandra-driver Pillow
```

### Step 1 — Run CQL Commands

Open the CQL Console in your Astra DB dashboard and run the commands in `cql/queries.cql` in order (Tasks 1 → 8).

### Step 2 — Upload Movie Posters

```bash
python python/upload_posters.py
```

### Step 3 — Query Movies by Actor or Director

```bash
python python/query_movies.py
```

You will be prompted to enter an actor or director name. The script prints the matching movie and saves the poster to an `output_posters/` folder.

```
Enter actor or director name: Tom Holland
Movie: Spider-Man: No Way Home
Saved poster: output_posters/Spider-Man_No_Way_Home.png
```

---

## Key Findings: Query Limitations in Cassandra

Cassandra does **not** support text-based search inside collection columns using standard CQL operators:

- **`LIKE`** — Not supported for map/list columns. Raises an `InvalidRequest` error.
- **`CONTAINS`** — Requires `ALLOW FILTERING` and still fails for `frozen<list<text>>` values due to type mismatch.

**Solution:** The search function fetches all rows and filters at the **application level** in Python.

---

## TTL Behavior Summary

| Approach | Method | Result after expiry |
|---|---|---|
| Column-level TTL | `UPDATE ... USING TTL 3` | Column values become `null`, row structure remains |
| Row-level TTL | `INSERT ... USING TTL 3` | Entire row is completely deleted |

---

## Technologies Used

| Technology | Purpose |
|---|---|
| DataStax Astra DB | Cloud-hosted Cassandra instance |
| CQL (Cassandra Query Language) | Database definition and manipulation |
| Python 3 + cassandra-driver | Application-level DB interaction |
| Pillow (PIL) | Image encoding/decoding for blob storage |
