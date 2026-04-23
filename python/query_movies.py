import os
from cassandra.cluster import Cluster
from cassandra.auth import PlainTextAuthProvider
from PIL import Image
import io

# -------- CONFIG --------
KEYSPACE = "Movies"      # exact keyspace name
TABLE = "Movie"          # exact table name
ASTRA_CLIENT_ID = "your-client-id"
ASTRA_CLIENT_SECRET = "your-client-secret"
SECURE_BUNDLE_PATH = "secure-connect-movies.zip"
# ------------------------


def connect_astra():
    auth = PlainTextAuthProvider(ASTRA_CLIENT_ID, ASTRA_CLIENT_SECRET)
    cluster = Cluster(
        cloud={"secure_connect_bundle": SECURE_BUNDLE_PATH},
        auth_provider=auth
    )
    session = cluster.connect()       # connect first
    session.set_keyspace("Movies")    # then set keyspace
    return session


def save_image(blob, filename):
    if blob is None:
        return
    image = Image.open(io.BytesIO(blob))
    image.save(filename)


def search_movie(person_name):
    session = connect_astra()
    person_name = person_name.lower()

    rows = session.execute(
        f"SELECT id, name, movie_cast, movie_poster FROM {TABLE}"
    )

    os.makedirs("output_posters", exist_ok=True)

    found = False

    for row in rows:
        cast_text = str(row.movie_cast).lower()
        if person_name in cast_text:
            found = True
            print("Movie:", row.name)

            safe_name = "".join(c for c in row.name if c.isalnum() or c in " _-")
            file_path = f"output_posters/{safe_name.replace(' ', '_')}.png"
            save_image(row.movie_poster, file_path)
            print("Saved poster:", file_path)

    if not found:
        print("No match found")


if __name__ == "__main__":
    name = input("Enter actor or director name: ")
    search_movie(name)
