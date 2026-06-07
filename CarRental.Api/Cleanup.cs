using System;
using System.Threading.Tasks;
using Npgsql;

namespace Cleanup
{
    class Program
    {
        static async Task Main(string[] args)
        {
            var connString = "Host=aws-1-eu-west-2.pooler.supabase.com;Port=5432;Database=postgres;Username=postgres.ncibebzdxtuglmlfbsmq;Password=386599/33/1;";
            await using var conn = new NpgsqlConnection(connString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand("DELETE FROM auth.users WHERE id NOT IN (SELECT \"Id\" FROM public.\"Profiles\");", conn);
            var rowsAffected = await cmd.ExecuteNonQueryAsync();
            Console.WriteLine($"Deleted {rowsAffected} orphaned users from auth.users.");
        }
    }
}
