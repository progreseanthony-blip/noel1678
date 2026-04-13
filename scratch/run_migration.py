import psycopg2
import sys

def run():
    try:
        conn = psycopg2.connect('postgresql://supabase_admin:postgres@127.0.0.1:54322/postgres')
        conn.autocommit = True
        cur = conn.cursor()
        
        # Check tables
        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
        tables = [t[0] for t in cur.fetchall()]
        print(f"Tables found in public: {tables}")
        
        sql = """
        -- Add support for Area-based (FT) estimation
        ALTER TABLE public.quote_service_estimations 
        ADD COLUMN IF NOT EXISTS thickness_inches numeric DEFAULT 0;

        ALTER TABLE public.quote_service_estimation_resources
        ADD COLUMN IF NOT EXISTS performance_per_day numeric DEFAULT 0;

        -- Optional: Add a comment to explain the columns
        COMMENT ON COLUMN public.quote_service_estimations.thickness_inches IS 'Thickness in inches for SQFT based calculations';
        COMMENT ON COLUMN public.quote_service_estimation_resources.performance_per_day IS 'Machine performance in Units/Day (e.g. SQFT/Day if unit is FT)';
        """
        
        print("Applying migration...")
        cur.execute(sql)
        print("Migration applied successfully!")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    run()
