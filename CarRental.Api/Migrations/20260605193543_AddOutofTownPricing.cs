using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CarRental.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddOutofTownPricing : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "DailyRateOutofTownUsd",
                table: "cars",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "DailyRateOutofTownZmw",
                table: "cars",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsOutofTown",
                table: "bookings",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DailyRateOutofTownUsd",
                table: "cars");

            migrationBuilder.DropColumn(
                name: "DailyRateOutofTownZmw",
                table: "cars");

            migrationBuilder.DropColumn(
                name: "IsOutofTown",
                table: "bookings");
        }
    }
}
