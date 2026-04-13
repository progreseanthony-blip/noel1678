import psycopg2
import os
import sys

def sync():
    migrations_dir = 'supabase/migrations'
    if not os.path.exists(migrations_dir):
        print(f"Directory {migrations_dir} does not exist.")
        return

    files = sorted([f for f in os.listdir(migrations_dir) if f.endswith('.sql')])
    
    # Noel_1678 database port is 56422
    try:
        conn = psycopg2.connect('postgresql://supabase_admin:postgres@127.0.0.1:56422/postgres')
        conn.autocommit = True
        cur = conn.cursor()
        
        print(f"Applying {len(files)} migrations to Noel_1678...")
        for f in files:
            print(f"  -> {f}", end="... ")
            with open(os.path.join(migrations_dir, f), 'r', encoding='utf-8') as sql_file:
                sql = sql_file.read()
                try:
                    cur.execute(sql)
                    print("SUCCESS")
                except Exception as e:
                    # Ignore "already exists" errors
                    if "already exists" in str(e).lower() or "already a member" in str(e).lower():
                        print("SKIPPED (Existing)")
                    else:
                        print(f"ERROR: {e}")
        
        cur.close()
        conn.close()
        print("\nDatabase synchronization completed successfully on Noel_1678!")
    except Exception as e:
        print(f"Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    sync()
