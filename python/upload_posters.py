from cassandra.cluster import Cluster
from cassandra.auth import PlainTextAuthProvider
import json

# -------- CONFIG --------
cloud_config = {
    'secure_connect_bundle': 'secure-connect-movies.zip'
}

with open("token.json", encoding="utf-8") as f:
    secrets = json.load(f)

CLIENT_ID = secrets["clientId"]
CLIENT_SECRET = secrets["secret"]

auth_provider = PlainTextAuthProvider(
    username=CLIENT_ID,
    password=CLIENT_SECRET
)

cluster = Cluster(
    cloud=cloud_config,
    auth_provider=auth_provider
)

session = cluster.connect("Movies")
print("Connected to Astra DB successfully")
# ------------------------


def encode_image_to_blob(image_path):
    with open(image_path, "rb") as file:
        return file.read()


def update_movie_poster(movie_id, image_path):
    image_blob = encode_image_to_blob(image_path)

    query = """
    UPDATE Movie
    SET movie_poster = %s
    WHERE id = %s
    """
    session.execute(query, (image_blob, movie_id))
    print(f"Poster updated for movie ID {movie_id}")


def show_movie_posters_status():
    query = "SELECT id, name, movie_poster FROM Movie"
    rows = session.execute(query)

    for row in rows:
        has_poster = row.movie_poster is not None
        print(f"ID={row.id}, Name={row.name}, Poster exists={has_poster}")


def decode_movie_poster(movie_id, output_path):
    query = "SELECT movie_poster FROM Movie WHERE id = %s"
    row = session.execute(query, (movie_id,)).one()

    if row and row.movie_poster:
        with open(output_path, "wb") as img:
            img.write(row.movie_poster)
        print(f"Poster decoded: {output_path}")
    else:
        print("No poster found")


# File paths - update these to match your local machine
image_path1 = r"posters\Inception.jpeg"
image_path2 = r"posters\Spider-Man_No_Way_Home.jpeg"
image_path3 = r"posters\Home_Alone.jpeg"

update_movie_poster(1, image_path1)
update_movie_poster(2, image_path2)
update_movie_poster(3, image_path3)
print()

show_movie_posters_status()

decode_movie_poster(1, "decoded_Inception.jpeg")
decode_movie_poster(2, "decoded_Spiderman.jpeg")
decode_movie_poster(3, "decoded_.Home_Alone.jpeg")

print("All posters processed successfully")
