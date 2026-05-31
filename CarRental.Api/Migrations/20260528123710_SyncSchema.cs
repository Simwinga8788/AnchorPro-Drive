using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CarRental.Api.Migrations
{
    /// <inheritdoc />
    public partial class SyncSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "zra_invoices");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "zra_invoices",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    booking_id = table.Column<Guid>(type: "uuid", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, defaultValueSql: "now()"),
                    invoice_number = table.Column<string>(type: "text", nullable: false),
                    submission_payload = table.Column<string>(type: "jsonb", nullable: true),
                    submission_status = table.Column<string>(type: "text", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, defaultValueSql: "now()"),
                    zra_reference_number = table.Column<string>(type: "text", nullable: true),
                    zra_response = table.Column<string>(type: "jsonb", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("zra_invoices_pkey", x => x.id);
                    table.ForeignKey(
                        name: "zra_invoices_booking_id_fkey",
                        column: x => x.booking_id,
                        principalTable: "bookings",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_zra_invoices_booking_id",
                table: "zra_invoices",
                column: "booking_id");

            migrationBuilder.CreateIndex(
                name: "zra_invoices_invoice_number_key",
                table: "zra_invoices",
                column: "invoice_number",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "zra_invoices_zra_reference_number_key",
                table: "zra_invoices",
                column: "zra_reference_number",
                unique: true);
        }
    }
}
