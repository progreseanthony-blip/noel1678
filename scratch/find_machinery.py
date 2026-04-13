import psycopg2
try:
    conn = psycopg2.connect('postgresql://supabase_admin:postgres@127.0.0.1:54322/postgres')
    cur = conn.cursor()
    cur.execute("SELECT n.nspname, c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE c.relname = 'machinery'")
    res = cur.fetchall()
    print("Catalog search results:")
    for r in res:
        print(f"- {r[0]}.{r[1]}")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
