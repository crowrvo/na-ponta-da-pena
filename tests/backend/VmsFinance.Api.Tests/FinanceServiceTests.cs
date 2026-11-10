using VmsFinance.Application.Abstractions;
using VmsFinance.Application.Common;
using VmsFinance.Application.Finance;
using VmsFinance.Domain.Finance;
using VmsFinance.Domain.Households;

namespace VmsFinance.Api.Tests;

public sealed class FinanceServiceTests
{
    private static readonly DateTimeOffset Now = new(2026, 11, 10, 16, 0, 0, TimeSpan.Zero);

    [Fact]
    public async Task CreateEntry_rejects_user_from_another_household()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        var service = CreateService(repository);

        await Assert.ThrowsAsync<HouseholdAccessDeniedException>(() => service.CreateEntryAsync(
            household.Id,
            "intruder",
            Guid.NewGuid(),
            EntryDirection.Expense,
            1_000,
            "Groceries",
            new DateOnly(2026, 11, 10),
            "request-1",
            CancellationToken.None));

        Assert.Empty(repository.Entries);
        Assert.Equal(0, repository.SaveCount);
    }

    [Fact]
    public async Task CreateEntry_returns_existing_entry_for_an_identical_idempotent_retry()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        var service = CreateService(repository);
        var entryId = Guid.NewGuid();
        var cancellationToken = CancellationToken.None;

        var first = await service.CreateEntryAsync(
            household.Id, "owner", entryId, EntryDirection.Expense, 2_599, "Internet",
            new DateOnly(2026, 11, 5), "request-2", cancellationToken);
        var retry = await service.CreateEntryAsync(
            household.Id, "owner", entryId, EntryDirection.Expense, 2_599, "Internet",
            new DateOnly(2026, 11, 5), "request-2", cancellationToken);

        Assert.True(first.Created);
        Assert.False(retry.Created);
        Assert.Equal(entryId, retry.Entry.Id);
        Assert.Single(repository.Entries);
        Assert.Equal(1, repository.SaveCount);
    }

    [Fact]
    public async Task CreateEntry_rejects_reuse_of_idempotency_key_with_different_data()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        var service = CreateService(repository);
        var cancellationToken = CancellationToken.None;

        await service.CreateEntryAsync(
            household.Id, "owner", Guid.NewGuid(), EntryDirection.Expense, 800, "Lunch",
            new DateOnly(2026, 11, 6), "request-3", cancellationToken);

        await Assert.ThrowsAsync<IdempotencyConflictException>(() => service.CreateEntryAsync(
            household.Id, "owner", Guid.NewGuid(), EntryDirection.Expense, 900, "Lunch",
            new DateOnly(2026, 11, 6), "request-3", cancellationToken));

        Assert.Single(repository.Entries);
        Assert.Equal(1, repository.SaveCount);
    }

    [Fact]
    public async Task GetMonthlyEntries_calculates_totals_and_excludes_other_months_and_households()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        var other = repository.AddHousehold("other-owner");
        repository.AddEntry(household.Id, EntryDirection.Income, 500_000, new DateOnly(2026, 11, 1));
        repository.AddEntry(household.Id, EntryDirection.Expense, 125_050, new DateOnly(2026, 11, 30));
        repository.AddEntry(household.Id, EntryDirection.Income, 99_000, new DateOnly(2026, 12, 1));
        repository.AddEntry(other.Id, EntryDirection.Expense, 999_999, new DateOnly(2026, 11, 15));
        var service = CreateService(repository);

        var result = await service.GetMonthlyEntriesAsync(
            household.Id, "owner", 2026, 11, CancellationToken.None);

        Assert.Equal(500_000, result.IncomeInCents);
        Assert.Equal(125_050, result.ExpenseInCents);
        Assert.Equal(374_950, result.BalanceInCents);
        Assert.Equal(2, result.Entries.Count);
    }

    [Fact]
    public async Task AddMember_requires_owner_role()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        repository.Members.Add(new HouseholdMember(household.Id, "member", HouseholdRole.Member, Now));
        var service = CreateService(repository);

        await Assert.ThrowsAsync<HouseholdAccessDeniedException>(() => service.AddMemberAsync(
            household.Id,
            "member",
            "new-member",
            HouseholdRole.Member,
            CancellationToken.None));

        Assert.DoesNotContain(repository.Members, member => member.UserId == "new-member");
    }

    private static FinanceService CreateService(IFinanceRepository repository) =>
        new(repository, new FixedTimeProvider(Now));

    private sealed class FixedTimeProvider(DateTimeOffset utcNow) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => utcNow;
    }

    private sealed class FakeFinanceRepository : IFinanceRepository
    {
        public List<Household> Households { get; } = [];
        public List<HouseholdMember> Members { get; } = [];
        public List<FinanceEntry> Entries { get; } = [];
        public int SaveCount { get; private set; }

        public Household AddHousehold(string ownerUserId)
        {
            var household = new Household(Guid.NewGuid(), $"{ownerUserId}'s household", Now);
            Households.Add(household);
            Members.Add(new HouseholdMember(household.Id, ownerUserId, HouseholdRole.Owner, Now));
            return household;
        }

        public void AddEntry(Guid householdId, EntryDirection direction, long amountInCents, DateOnly occurredOn) =>
            Entries.Add(new FinanceEntry(
                Guid.NewGuid(), householdId, direction, amountInCents, "Test entry", occurredOn,
                Guid.NewGuid().ToString("N"), Now));

        public Task AddHouseholdAsync(Household household, HouseholdMember owner, CancellationToken cancellationToken)
        {
            Households.Add(household);
            Members.Add(owner);
            return Task.CompletedTask;
        }

        public Task<IReadOnlyList<Household>> ListHouseholdsAsync(string userId, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<Household>>(Households
                .Where(household => Members.Any(member => member.HouseholdId == household.Id && member.UserId == userId))
                .ToArray());

        public Task<Household?> GetHouseholdAsync(Guid householdId, CancellationToken cancellationToken) =>
            Task.FromResult(Households.SingleOrDefault(household => household.Id == householdId));

        public Task<HouseholdMember?> GetMembershipAsync(Guid householdId, string userId, CancellationToken cancellationToken) =>
            Task.FromResult(Members.SingleOrDefault(member => member.HouseholdId == householdId && member.UserId == userId));

        public Task AddMemberAsync(HouseholdMember member, CancellationToken cancellationToken)
        {
            Members.Add(member);
            return Task.CompletedTask;
        }

        public Task<FinanceEntry?> GetEntryByIdempotencyKeyAsync(
            Guid householdId,
            string idempotencyKey,
            CancellationToken cancellationToken) =>
            Task.FromResult(Entries.SingleOrDefault(entry =>
                entry.HouseholdId == householdId && entry.IdempotencyKey == idempotencyKey));

        public Task AddEntryAsync(FinanceEntry entry, CancellationToken cancellationToken)
        {
            Entries.Add(entry);
            return Task.CompletedTask;
        }

        public Task<IReadOnlyList<FinanceEntry>> ListEntriesAsync(
            Guid householdId,
            DateOnly from,
            DateOnly until,
            CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<FinanceEntry>>(Entries
                .Where(entry => entry.HouseholdId == householdId && entry.OccurredOn >= from && entry.OccurredOn < until)
                .ToArray());

        public Task SaveChangesAsync(CancellationToken cancellationToken)
        {
            SaveCount++;
            return Task.CompletedTask;
        }
    }
}
