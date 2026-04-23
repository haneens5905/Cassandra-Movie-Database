# Cassandra Movie Database

<p align="left">
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python" />
  <img src="https://img.shields.io/badge/Apache_Cassandra-1287B1?style=for-the-badge&logo=apachecassandra&logoColor=white" alt="Apache Cassandra" />
  <img src="https://img.shields.io/badge/Astra_DB-0A66C2?style=for-the-badge&logo=datastax&logoColor=white" alt="Astra DB" />
  <img src="https://img.shields.io/badge/CQL-Query_Language-4B5563?style=for-the-badge" alt="CQL" />
  <img src="https://img.shields.io/badge/BLOB-Image_Storage-2E8B57?style=for-the-badge" alt="BLOB" />
  <img src="https://img.shields.io/badge/TTL-Column_Expiry-F59E0B?style=for-the-badge" alt="TTL" />
</p>

A NoSQL movie database built with **Apache Cassandra** via **DataStax Astra DB**, developed as part of the SIS314 Advanced Database course at Cairo University.

The project covers keyspace and table creation, data insertion with TTL, binary blob storage for movie posters, Python integration, and CQL querying.

---

## Team Members

| Name | ID |
|---|---|
| Ziad Tarek | 20236043 |
| Haneen Soliman | 20236032 |
| Mohamed Ahmed | 20237011 |
| Shaza Moatasem | 20236050 |
| Rabab Mohamed | 20237004 |

---

## Project Overview

This assignment demonstrates practical use of Apache Cassandra for managing a movie database. Key concepts covered include:

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
│   └── Assignment2_Report.pdf       # Full assignment report with screenshots
│
├── posters/
│   ├── Inception.jpeg               # Movie poster — stored as blob in Cassandra
│   ├── Spider-Man_No_Way_Home.jpeg  # Movie poster — stored as blob in Cassandra
│   └── Home_Alone.jpeg              # Movie poster — stored as blob in Cassandra
│
├── cql/
│   └── queries.cql                  # All CQL commands (Tasks 1–8)
│
└── python/
    ├── upload_posters.py            # Connects to Astra DB, encodes images to blob, updates DB
    └── query_movies.py              # Searches movies by actor or director, saves poster locally
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

Update the image file paths in `upload_posters.py` to match your local machine:

```python
image_path1 = r"C:\Your\Path\Inception Poster 1.jpeg"
image_path2 = r"C:\Your\Path\Spiderman Poster 2.jpeg"
image_path3 = r"C:\Your\Path\Home Alone Poster 3.jpeg"
```

Then run:

```bash
python python/upload_posters.py
```

### Step 3 — Query Movies by Actor or Director

```bash
python python/query_movies.py
```

You will be prompted to enter an actor or director name. The script will print the matching movie and save the poster to an `output_posters/` folder.

**Example:**
```
Enter actor or director name: Tom Holland
Movie: Spider-Man: No Way Home
Saved poster: output_posters/Spider-Man_No_Way_Home.png
```

---

## Key Findings: Query Limitations in Cassandra

Cassandra does **not** support text-based search inside collection columns using standard CQL operators:

- **`LIKE`** — Not supported for map/list columns at all. Raises an `InvalidRequest` error.
- **`CONTAINS`** — Requires `ALLOW FILTERING` and still fails for `frozen<list<text>>` values due to type mismatch.

**Solution:** The search function fetches all rows and performs filtering at the **application level** in Python, which is more reliable and efficient for this use case.

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
| PyCharm | Python development environment |
