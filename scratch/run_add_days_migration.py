import psycopg2
import sys
import os

def run():
    try:
        # Use the connection string from the existing run_migration.py
        conn = psycopg2.connect('postgresql://supabase_admin:postgres@127.0.0.1:56422/postgres')
        conn.autocommit = True
        cur = conn.cursor()
        
        migration_file = 'supabase/migrations/20260415173000_add_days_to_instruments.sql'
        if not os.path.exists(migration_file):
            print(f"File not found: {migration_file}")
            sys.exit(1)
            
        with open(migration_file, 'r', encoding='utf-8') as f:
            sql = f.read()
            
        print(f"Applying migration from {migration_file}...")
        cur.execute(sql)
        print("Migration applied successfully!")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    run()
