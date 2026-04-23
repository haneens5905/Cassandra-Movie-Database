-- ============================================================
-- Task 1: KeySpace Creation
-- ============================================================

CREATE KEYSPACE Movies
WITH replication = {'class': 'NetworkTopologyStrategy', 'eu-west-1': '3'}
AND durable_writes = true;


-- ============================================================
-- Task 2: Movie Table Creation (with TTL on first row)
-- ============================================================

USE "Movies";

CREATE TABLE Movie (
    id int PRIMARY KEY,
    name text,
    movie_cast map<text, frozen<list<text>>>,
    movie_poster blob
);


-- ============================================================
-- Task 3: Schema Check
-- ============================================================

DESCRIBE TABLE Movie;


-- ============================================================
-- Task 4: Insert Movie Data
-- ============================================================

-- Movie 1: Inception (with TTL of 7 days = 604800 seconds)
INSERT INTO Movie (id, name, movie_cast)
VALUES (
    1,
    'Inception',
    {
        'director' : ['Christopher Nolan'],
        'actors'   : ['Leonardo DiCaprio', 'Joseph Gordon-Levitt', 'Elliot Page'],
        'music'    : ['Hans Zimmer']
    }
) USING TTL 604800;

-- Movie 2: Spider-Man: No Way Home (no TTL)
INSERT INTO Movie (id, name, movie_cast)
VALUES (
    2,
    'Spider-Man: No Way Home',
    {
        'director' : ['Jon Watts'],
        'actors'   : ['Tom Holland', 'Zendaya', 'Benedict Cumberbatch'],
        'music'    : ['Michael Giacchino']
    }
);

-- Movie 3: Home Alone (no TTL)
INSERT INTO Movie (id, name, movie_cast)
VALUES (
    3,
    'Home Alone',
    {
        'director' : ['Chris Columbus'],
        'actors'   : ['Macaulay Culkin', 'Joe Pesci', 'Daniel Stern'],
        'music'    : ['John Williams']
    }
);

-- Verify inserts
SELECT * FROM Movie;


-- ============================================================
-- Task 6: Query Limitations Testing (LIKE vs CONTAINS)
-- ============================================================

-- LIKE operator test (fails - not supported for collections)
SELECT *
FROM Movie
WHERE movie_cast LIKE '%Nolan%';

-- CONTAINS operator test (fails for frozen<list<text>>)
SELECT id, name, movie_cast
FROM Movie
WHERE movie_cast CONTAINS 'Christopher Nolan'
ALLOW FILTERING;


-- ============================================================
-- Task 7: Update Movie Actors List
-- ============================================================

-- Add Andrew Garfield to Spider-Man: No Way Home (id = 2)
UPDATE Movie
SET movie_cast = movie_cast + {'actors': ['Tom Holland', 'Zendaya', 'Benedict Cumberbatch', 'Andrew Garfield']}
WHERE id = 2;

-- Verify update
SELECT id, name, movie_cast FROM Movie;
SELECT id, name, movie_cast FROM Movie WHERE id = 2;


-- ============================================================
-- Task 8: TTL Update and Observation
-- ============================================================

-- Approach 1: Column-level TTL using UPDATE (columns become null after expiry)
UPDATE Movie USING TTL 3
SET name = 'Inception',
    movie_cast = {'actors': ['Leonardo DiCaprio', 'Joseph Gordon-Levitt', 'Elliot Page'], 'director': ['Christopher Nolan'], 'music': ['Hans Zimmer']}
WHERE id = 1;

-- Query immediately after update
SELECT id, name, movie_cast FROM Movie;
-- Query again after 3 seconds -> name and movie_cast become null, row still exists

-- Approach 2: Row-level TTL using INSERT (entire row deleted after expiry)
DELETE FROM Movie WHERE id = 1;

-- Verify deletion
SELECT id, name FROM Movie;

-- Reinsert with TTL of 3 seconds
INSERT INTO Movie (id, name, movie_cast)
VALUES (1, 'Inception', {'actors': ['Leonardo DiCaprio', 'Joseph Gordon-Levitt', 'Elliot Page'], 'director': ['Christopher Nolan'], 'music': ['Hans Zimmer']})
USING TTL 3;

-- Query immediately -> row exists
SELECT id, name FROM Movie;
-- Query again after 3 seconds -> entire row is gone
SELECT id, name FROM Movie;
