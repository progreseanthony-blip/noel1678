import psycopg2
try:
    conn = psycopg2.connect('postgresql://postgres:postgres@127.0.0.1:54322/postgres')
    cur = conn.cursor()
    cur.execute("SELECT table_schema, table_name FROM information_schema.tables WHERE table_name ILIKE '%machinery%'")
    res = cur.fetchall()
    print("Search results:")
    for r in res:
        print(f"- {r[0]}.{r[1]}")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
