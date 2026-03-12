import psycopg2
import sys

try:
    conn = psycopg2.connect(
        dbname="postgres",
        user="postgres",
        password="postgres",
        host="localhost",
        port="54422"
    )
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute("NOTIFY pgrst, 'reload schema';")
    print("Schema reload notification sent")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
