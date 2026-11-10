using Microsoft.EntityFrameworkCore;
using VmsFinance.Domain.Finance;
using VmsFinance.Domain.Households;

namespace VmsFinance.Infrastructure.Persistence;

public sealed class FinanceDbContext(DbContextOptions<FinanceDbContext> options) : DbContext(options)
{
    public DbSet<FinanceEntry> FinanceEntries => Set<FinanceEntry>();
    public DbSet<Household> Households => Set<Household>();
    public DbSet<HouseholdMember> HouseholdMembers => Set<HouseholdMember>();
    public DbSet<HouseholdInvitation> HouseholdInvitations => Set<HouseholdInvitation>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        var entry = modelBuilder.Entity<FinanceEntry>();
        entry.ToTable("finance_entries");
        entry.HasKey(item => item.Id);
        entry.Property(item => item.Description).HasMaxLength(240).IsRequired();
        entry.Property(item => item.IdempotencyKey).HasMaxLength(100).IsRequired();
        entry.Property(item => item.Direction).HasConversion<string>().HasMaxLength(16);
        entry.HasOne<Household>().WithMany().HasForeignKey(item => item.HouseholdId).OnDelete(DeleteBehavior.Cascade);
        entry.HasIndex(item => new { item.HouseholdId, item.OccurredOn });
        entry.HasIndex(item => new { item.HouseholdId, item.IdempotencyKey }).IsUnique();

        var household = modelBuilder.Entity<Household>();
        household.ToTable("households");
        household.HasKey(item => item.Id);
        household.Property(item => item.Name).HasMaxLength(120).IsRequired();

        var member = modelBuilder.Entity<HouseholdMember>();
        member.ToTable("household_members");
        member.HasKey(item => new { item.HouseholdId, item.UserId });
        member.Property(item => item.UserId).HasMaxLength(200);
        member.Property(item => item.Role).HasConversion<string>().HasMaxLength(16);
        member.HasOne<Household>().WithMany().HasForeignKey(item => item.HouseholdId).OnDelete(DeleteBehavior.Cascade);

        var invitation = modelBuilder.Entity<HouseholdInvitation>();
        invitation.ToTable("household_invitations");
        invitation.HasKey(item => item.Id);
        invitation.Property(item => item.TokenHash).HasMaxLength(64).IsFixedLength().IsRequired();
        invitation.Property(item => item.CreatedByUserId).HasMaxLength(200).IsRequired();
        invitation.Property(item => item.AcceptedByUserId).HasMaxLength(200);
        invitation.Property(item => item.Version).IsConcurrencyToken();
        invitation.HasIndex(item => item.TokenHash).IsUnique();
        invitation.HasIndex(item => new { item.HouseholdId, item.ExpiresAtUtc });
        invitation.HasOne<Household>().WithMany().HasForeignKey(item => item.HouseholdId).OnDelete(DeleteBehavior.Cascade);
    }
}

