import psycopg2
try:
    conn = psycopg2.connect('postgresql://supabase_admin:postgres@127.0.0.1:54322/postgres')
    cur = conn.cursor()
    # Search for any table containing 'quote' in the name
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_name ILIKE '%quote%' AND table_schema = 'public'")
    tables = cur.fetchall()
    print("Tables containing 'quote':")
    for t in tables:
        print(f"- {t[0]}")
    
    # Also search for 'machinery' again
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_name ILIKE '%machinery%' AND table_schema = 'public'")
    tables = cur.fetchall()
    print("Tables containing 'machinery':")
    for t in tables:
        print(f"- {t[0]}")

    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
