using Microsoft.EntityFrameworkCore;
using VmsFinance.Domain.Finance;

namespace VmsFinance.Infrastructure.Persistence;

public sealed class FinanceDbContext(DbContextOptions<FinanceDbContext> options) : DbContext(options)
{
    public DbSet<FinanceEntry> FinanceEntries => Set<FinanceEntry>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        var entry = modelBuilder.Entity<FinanceEntry>();
        entry.ToTable("finance_entries");
        entry.HasKey(item => item.Id);
        entry.Property(item => item.Description).HasMaxLength(240).IsRequired();
        entry.Property(item => item.Direction).HasConversion<string>().HasMaxLength(16);
        entry.HasIndex(item => new { item.HouseholdId, item.OccurredOn });
    }
}

