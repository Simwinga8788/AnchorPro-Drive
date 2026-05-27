const { Client } = require('pg');

const connectionString = "Host=aws-1-eu-west-2.pooler.supabase.com;Port=5432;Database=postgres;Username=postgres.ncibebzdxtuglmlfbsmq;Password=386599/33/1;";
const uri = "postgresql://postgres.ncibebzdxtuglmlfbsmq:386599%2F33%2F1@aws-1-eu-west-2.pooler.supabase.com:5432/postgres?sslmode=require";

const client = new Client({
  connectionString: uri,
  ssl: { rejectUnauthorized: false }
});

async function run() {
  await client.connect();
  console.log("Connected to PostgreSQL");

  const email = "simwinga8788@gmail.com";
  const password = "386599/33/1";

  // Check if user already exists
  const check = await client.query(`SELECT id FROM auth.users WHERE email = $1`, [email]);
  if (check.rows.length > 0) {
    console.log("User already exists with ID:", check.rows[0].id);
  } else {
    // Insert into auth.users
    const insertQuery = `
      INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, 
        recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, 
        created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token
      ) VALUES (
        '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', $1, crypt($2, gen_salt('bf')), now(),
        null, now(), '{"provider":"email","providers":["email"]}', '{}',
        now(), now(), '', '', '', ''
      ) RETURNING id;
    `;
    const res = await client.query(insertQuery, [email, password]);
    console.log("Inserted auth.users with ID:", res.rows[0].id);

    // Also insert into public.profiles
    const insertProfile = `
      INSERT INTO public.profiles (
        id, first_name, last_name, created_at
      ) VALUES (
        $1, 'Admin', 'User', now()
      );
    `;
    await client.query(insertProfile, [res.rows[0].id]);
    console.log("Inserted into public.profiles");
  }

  await client.end();
}

run().catch(console.error);
