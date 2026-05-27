import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error("Missing Supabase env vars in .env.local");
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function seed() {
  const email = 'simwinga8788@gmail.com';
  const password = '386599/33/1';

  console.log(`Seeding user: ${email}...`);

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
  });

  if (error) {
    console.error("Error signing up:", error.message);
    return;
  }

  console.log("User seeded successfully!");
  console.log("User ID:", data.user?.id);
}

seed();
