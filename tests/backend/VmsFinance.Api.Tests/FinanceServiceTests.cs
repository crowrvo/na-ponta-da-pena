using VmsFinance.Application.Abstractions;
using VmsFinance.Application.Common;
using VmsFinance.Application.Finance;
using VmsFinance.Domain.Finance;
using VmsFinance.Domain.Households;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

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

    [Fact]
    public async Task Invitation_is_created_by_owner_with_only_a_hash_persisted_and_is_single_use()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        var service = CreateService(repository);

        var created = await service.CreateInvitationAsync(
            household.Id, "owner", TimeSpan.FromDays(7), CancellationToken.None);

        var persisted = Assert.Single(repository.Invitations);
        Assert.NotEqual(created.Token, persisted.TokenHash);
        Assert.Equal(64, persisted.TokenHash.Length);
        Assert.Equal(HashToken(created.Token), persisted.TokenHash);

        var accepted = await service.AcceptInvitationAsync(
            "member", $"  {created.Token}\r\n", CancellationToken.None);
        Assert.Equal(household.Id, accepted.HouseholdId);
        Assert.Equal(HouseholdRole.Member, accepted.Role);
        Assert.Contains(repository.Members, item => item.HouseholdId == household.Id && item.UserId == "member");

        await Assert.ThrowsAsync<InvitationNotUsableException>(() =>
            service.AcceptInvitationAsync("another-member", created.Token, CancellationToken.None));
    }

    [Fact]
    public async Task Invitation_creation_and_revocation_require_an_owner()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        repository.Members.Add(new HouseholdMember(household.Id, "member", HouseholdRole.Member, Now));
        var service = CreateService(repository);

        await Assert.ThrowsAsync<HouseholdAccessDeniedException>(() => service.CreateInvitationAsync(
            household.Id, "member", TimeSpan.FromDays(1), CancellationToken.None));

        var created = await service.CreateInvitationAsync(
            household.Id, "owner", TimeSpan.FromDays(1), CancellationToken.None);
        await Assert.ThrowsAsync<HouseholdAccessDeniedException>(() => service.RevokeInvitationAsync(
            household.Id, created.Id, "member", CancellationToken.None));

        await service.RevokeInvitationAsync(household.Id, created.Id, "owner", CancellationToken.None);
        await Assert.ThrowsAsync<InvitationNotUsableException>(() =>
            service.AcceptInvitationAsync("new-member", created.Token, CancellationToken.None));
    }

    [Fact]
    public async Task Owner_can_list_safe_invitation_metadata_with_derived_statuses()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        repository.Members.Add(new HouseholdMember(household.Id, "member", HouseholdRole.Member, Now));
        var timeProvider = new FixedTimeProvider(Now);
        var service = new FinanceService(repository, timeProvider);
        var expired = await service.CreateInvitationAsync(
            household.Id, "owner", TimeSpan.FromHours(1), CancellationToken.None);
        var active = await service.CreateInvitationAsync(
            household.Id, "owner", TimeSpan.FromDays(1), CancellationToken.None);
        var revoked = await service.CreateInvitationAsync(
            household.Id, "owner", TimeSpan.FromDays(1), CancellationToken.None);
        var accepted = await service.CreateInvitationAsync(
            household.Id, "owner", TimeSpan.FromDays(1), CancellationToken.None);
        await service.RevokeInvitationAsync(household.Id, revoked.Id, "owner", CancellationToken.None);
        await service.AcceptInvitationAsync("accepted-member", accepted.Token, CancellationToken.None);
        timeProvider.UtcNow = Now.AddHours(2);

        var summaries = await service.ListInvitationsAsync(
            household.Id, "owner", CancellationToken.None);

        Assert.Equal(4, summaries.Count);
        Assert.Equal(InvitationStatus.Expired, summaries.Single(item => item.Id == expired.Id).Status);
        Assert.Equal(InvitationStatus.Active, summaries.Single(item => item.Id == active.Id).Status);
        Assert.Equal(InvitationStatus.Revoked, summaries.Single(item => item.Id == revoked.Id).Status);
        var acceptedSummary = summaries.Single(item => item.Id == accepted.Id);
        Assert.Equal(InvitationStatus.Accepted, acceptedSummary.Status);
        Assert.NotNull(acceptedSummary.AcceptedAtUtc);
        var json = JsonSerializer.Serialize(summaries);
        Assert.DoesNotContain(expired.Token, json, StringComparison.Ordinal);
        Assert.DoesNotContain("Token", json, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("CreatedBy", json, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("AcceptedBy", json, StringComparison.OrdinalIgnoreCase);

        await Assert.ThrowsAsync<HouseholdAccessDeniedException>(() =>
            service.ListInvitationsAsync(household.Id, "member", CancellationToken.None));
    }

    [Fact]
    public async Task Expired_invitation_cannot_be_accepted()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        var timeProvider = new FixedTimeProvider(Now);
        var service = new FinanceService(repository, timeProvider);
        var created = await service.CreateInvitationAsync(
            household.Id, "owner", TimeSpan.FromHours(1), CancellationToken.None);

        timeProvider.UtcNow = Now.AddHours(1);

        await Assert.ThrowsAsync<InvitationNotUsableException>(() =>
            service.AcceptInvitationAsync("member", created.Token, CancellationToken.None));
        Assert.DoesNotContain(repository.Members, item => item.UserId == "member");
    }

    [Fact]
    public async Task Owner_can_remove_member_but_member_cannot_remove_others_or_owner()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        repository.Members.Add(new HouseholdMember(household.Id, "member", HouseholdRole.Member, Now));
        repository.Members.Add(new HouseholdMember(household.Id, "other", HouseholdRole.Member, Now));
        var service = CreateService(repository);

        await Assert.ThrowsAsync<HouseholdAccessDeniedException>(() => service.RemoveMemberAsync(
            household.Id, "member", "other", CancellationToken.None));
        await Assert.ThrowsAsync<HouseholdAccessDeniedException>(() => service.RemoveMemberAsync(
            household.Id, "owner", "owner", CancellationToken.None));

        await service.RemoveMemberAsync(household.Id, "owner", "member", CancellationToken.None);

        Assert.DoesNotContain(repository.Members, item => item.UserId == "member");
        Assert.Contains(repository.Members, item => item.UserId == "owner" && item.Role == HouseholdRole.Owner);
    }

    [Fact]
    public async Task Member_can_leave_household_but_owner_cannot_leave_while_still_owner()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        repository.Members.Add(new HouseholdMember(household.Id, "member", HouseholdRole.Member, Now));
        var service = CreateService(repository);

        await service.LeaveHouseholdAsync(household.Id, "member", CancellationToken.None);

        Assert.DoesNotContain(repository.Members, item => item.UserId == "member");
        await Assert.ThrowsAsync<HouseholdAccessDeniedException>(() =>
            service.LeaveHouseholdAsync(household.Id, "owner", CancellationToken.None));
        Assert.Contains(repository.Members, item => item.UserId == "owner" && item.Role == HouseholdRole.Owner);
    }

    [Fact]
    public async Task SyncEntries_persists_a_batch_once_and_marks_a_retry_as_duplicate()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        var service = CreateService(repository);
        var commands = new[]
        {
            Command("operation-1", EntryDirection.Income, 300_000),
            Command("operation-2", EntryDirection.Expense, 85_000),
        };

        var first = await service.SyncEntriesAsync(household.Id, "owner", commands, CancellationToken.None);
        var retry = await service.SyncEntriesAsync(household.Id, "owner", commands, CancellationToken.None);

        Assert.All(first.Results, result => Assert.True(result.Created));
        Assert.All(retry.Results, result => Assert.False(result.Created));
        Assert.Equal(2, repository.Entries.Count);
        Assert.Equal(1, repository.SaveCount);
    }

    [Fact]
    public async Task SyncEntries_is_atomic_when_a_later_operation_conflicts()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        var existing = Command("operation-existing", EntryDirection.Expense, 500);
        var service = CreateService(repository);
        await service.SyncEntriesAsync(household.Id, "owner", [existing], CancellationToken.None);
        var countBeforeConflict = repository.Entries.Count;
        var savesBeforeConflict = repository.SaveCount;

        var conflicting = existing with { AmountInCents = 501 };
        await Assert.ThrowsAsync<IdempotencyConflictException>(() => service.SyncEntriesAsync(
            household.Id,
            "owner",
            [Command("operation-new", EntryDirection.Income, 1_000), conflicting],
            CancellationToken.None));

        Assert.Equal(countBeforeConflict, repository.Entries.Count);
        Assert.Equal(savesBeforeConflict, repository.SaveCount);
    }

    [Fact]
    public async Task SyncEntries_rejects_non_members_before_processing_the_batch()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        var service = CreateService(repository);

        await Assert.ThrowsAsync<HouseholdAccessDeniedException>(() => service.SyncEntriesAsync(
            household.Id,
            "intruder",
            [Command("operation-1", EntryDirection.Expense, 1_000)],
            CancellationToken.None));

        Assert.Empty(repository.Entries);
    }

    [Fact]
    public async Task SyncEntries_rejects_empty_and_oversized_batches()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        var service = CreateService(repository);

        await Assert.ThrowsAsync<ArgumentOutOfRangeException>(() => service.SyncEntriesAsync(
            household.Id, "owner", [], CancellationToken.None));
        await Assert.ThrowsAsync<ArgumentOutOfRangeException>(() => service.SyncEntriesAsync(
            household.Id,
            "owner",
            Enumerable.Range(1, 101).Select(index => Command($"operation-{index}", EntryDirection.Expense, index)).ToArray(),
            CancellationToken.None));

        Assert.Empty(repository.Entries);
    }

    [Fact]
    public async Task SyncEntries_rejects_a_duplicate_entry_id_before_persisting()
    {
        var repository = new FakeFinanceRepository();
        var household = repository.AddHousehold("owner");
        var service = CreateService(repository);
        var first = Command("operation-1", EntryDirection.Expense, 100);
        var duplicateId = Command("operation-2", EntryDirection.Expense, 200) with { Id = first.Id };

        await Assert.ThrowsAsync<ArgumentException>(() => service.SyncEntriesAsync(
            household.Id, "owner", [first, duplicateId], CancellationToken.None));

        Assert.Empty(repository.Entries);
        Assert.Equal(0, repository.SaveCount);
    }

    private static SyncEntryCommand Command(string key, EntryDirection direction, long amountInCents) =>
        new(Guid.NewGuid(), direction, amountInCents, "Synced entry", new DateOnly(2026, 11, 10), key);

    private static FinanceService CreateService(IFinanceRepository repository) =>
        new(repository, new FixedTimeProvider(Now));

    private static string HashToken(string token) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));

    private sealed class FixedTimeProvider(DateTimeOffset utcNow) : TimeProvider
    {
        public DateTimeOffset UtcNow { get; set; } = utcNow;

        public override DateTimeOffset GetUtcNow() => UtcNow;
    }

    private sealed class FakeFinanceRepository : IFinanceRepository
    {
        public List<Household> Households { get; } = [];
        public List<HouseholdMember> Members { get; } = [];
        public List<HouseholdInvitation> Invitations { get; } = [];
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

        public Task RemoveMemberAsync(HouseholdMember member, CancellationToken cancellationToken)
        {
            Members.Remove(member);
            return Task.CompletedTask;
        }

        public Task AddInvitationAsync(HouseholdInvitation invitation, CancellationToken cancellationToken)
        {
            Invitations.Add(invitation);
            return Task.CompletedTask;
        }

        public Task<HouseholdInvitation?> GetInvitationByIdAsync(
            Guid householdId,
            Guid invitationId,
            CancellationToken cancellationToken) =>
            Task.FromResult(Invitations.SingleOrDefault(item =>
                item.HouseholdId == householdId && item.Id == invitationId));

        public Task<HouseholdInvitation?> GetInvitationByTokenHashAsync(
            string tokenHash,
            CancellationToken cancellationToken) =>
            Task.FromResult(Invitations.SingleOrDefault(item => item.TokenHash == tokenHash));

        public Task<IReadOnlyList<HouseholdInvitation>> ListInvitationsAsync(
            Guid householdId,
            CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<HouseholdInvitation>>(Invitations
                .Where(item => item.HouseholdId == householdId)
                .OrderByDescending(item => item.CreatedAtUtc)
                .ToArray());

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
