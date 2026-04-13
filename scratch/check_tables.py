import psycopg2
try:
    conn = psycopg2.connect('postgresql://supabase_admin:postgres@127.0.0.1:54322/postgres')
    cur = conn.cursor()
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
    tables = cur.fetchall()
    print("Tables found with supabase_admin:")
    for t in tables:
        print(f"- {t[0]}")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
