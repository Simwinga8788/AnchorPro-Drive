const { Client } = require('pg');

const uri = "postgresql://postgres.ncibebzdxtuglmlfbsmq:386599%2F33%2F1@aws-1-eu-west-2.pooler.supabase.com:5432/postgres";

const client = new Client({
  connectionString: uri,
  ssl: { rejectUnauthorized: false }
});

async function run() {
  await client.connect();
  console.log("Connected to PostgreSQL");

  // 1. Create bucket if not exists
  await client.query(`
    INSERT INTO storage.buckets (id, name, public) 
    VALUES ('fleet-images', 'fleet-images', true)
    ON CONFLICT (id) DO NOTHING;
  `);
  console.log("Bucket created/verified.");



  // 3. Create policies
  const policies = [
    `CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'fleet-images');`,
    `CREATE POLICY "Auth Uploads" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'fleet-images' AND auth.role() = 'authenticated');`,
    `CREATE POLICY "Auth Updates" ON storage.objects FOR UPDATE USING (bucket_id = 'fleet-images' AND auth.role() = 'authenticated');`,
    `CREATE POLICY "Auth Deletes" ON storage.objects FOR DELETE USING (bucket_id = 'fleet-images' AND auth.role() = 'authenticated');`
  ];

  for (const p of policies) {
    try {
      await client.query(p);
      console.log("Created policy.");
    } catch (e) {
      // Ignore errors if policy already exists
      if (!e.message.includes("already exists")) {
        console.error("Policy error:", e.message);
      }
    }
  }

  console.log("Storage bucket 'fleet-images' configured!");
  await client.end();
}

run().catch(console.error);
