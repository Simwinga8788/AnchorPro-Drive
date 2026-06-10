const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgres://postgres.ncibebzdxtuglmlfbsmq:386599%2F33%2F1@aws-1-eu-west-2.pooler.supabase.com:5432/postgres'
});

async function run() {
  await client.connect();
  
  const res = await client.query(`ALTER TABLE cars ALTER COLUMN license_plate DROP NOT NULL`);
  console.log("Mwangala's Profile:", res.rows);
  
  const res2 = await client.query(`SELECT * FROM auth.users WHERE email = 'mwangalamuyangana3@gmail.com'`);
  console.log("Supabase Auth User:", res2.rows.map(r => ({ id: r.id, email: r.email, created_at: r.created_at })));

  await client.end();
}

run().catch(console.error);




