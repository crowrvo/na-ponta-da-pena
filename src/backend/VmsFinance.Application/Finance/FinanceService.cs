using VmsFinance.Application.Abstractions;
using VmsFinance.Application.Common;
using System.Security.Cryptography;
using System.Text;
using VmsFinance.Domain.Finance;
using VmsFinance.Domain.Households;

namespace VmsFinance.Application.Finance;

public sealed class FinanceService(IFinanceRepository repository, TimeProvider timeProvider)
{
    public async Task<HouseholdSummary> CreateHouseholdAsync(string userId, string name, CancellationToken cancellationToken)
    {
        EnsureUser(userId);
        var now = timeProvider.GetUtcNow();
        var household = new Household(Guid.NewGuid(), name, now);
        var owner = new HouseholdMember(household.Id, userId, HouseholdRole.Owner, now);

        await repository.AddHouseholdAsync(household, owner, cancellationToken);
        await repository.SaveChangesAsync(cancellationToken);
        return new HouseholdSummary(household.Id, household.Name, owner.Role);
    }

    public async Task<IReadOnlyList<HouseholdSummary>> ListHouseholdsAsync(string userId, CancellationToken cancellationToken)
    {
        EnsureUser(userId);
        var households = await repository.ListHouseholdsAsync(userId, cancellationToken);
        var result = new List<HouseholdSummary>(households.Count);
        foreach (var household in households)
        {
            var membership = await repository.GetMembershipAsync(household.Id, userId, cancellationToken);
            if (membership is not null)
            {
                result.Add(new HouseholdSummary(household.Id, household.Name, membership.Role));
            }
        }

        return result;
    }

    public async Task AddMemberAsync(
        Guid householdId,
        string currentUserId,
        string memberUserId,
        HouseholdRole role,
        CancellationToken cancellationToken)
    {
        EnsureUser(currentUserId);
        EnsureUser(memberUserId);
        var currentMembership = await RequireMembershipAsync(householdId, currentUserId, cancellationToken);
        if (currentMembership.Role != HouseholdRole.Owner)
        {
            throw new HouseholdAccessDeniedException("Only a household owner can add members.");
        }

        var existing = await repository.GetMembershipAsync(householdId, memberUserId, cancellationToken);
        if (existing is not null)
        {
            return;
        }

        await repository.AddMemberAsync(
            new HouseholdMember(householdId, memberUserId, role, timeProvider.GetUtcNow()),
            cancellationToken);
        await repository.SaveChangesAsync(cancellationToken);
    }

    public async Task<CreatedInvitationResult> CreateInvitationAsync(
        Guid householdId,
        string currentUserId,
        TimeSpan validFor,
        CancellationToken cancellationToken)
    {
        var membership = await RequireMembershipAsync(householdId, currentUserId, cancellationToken);
        if (membership.Role != HouseholdRole.Owner)
        {
            throw new HouseholdAccessDeniedException("Only a household owner can create invitations.");
        }

        if (validFor < TimeSpan.FromHours(1) || validFor > TimeSpan.FromDays(30))
        {
            throw new ArgumentOutOfRangeException(nameof(validFor), "Invitation validity must be between one hour and 30 days.");
        }

        var now = timeProvider.GetUtcNow();
        var token = CreateOpaqueToken();
        var invitation = new HouseholdInvitation(
            Guid.NewGuid(),
            householdId,
            HashToken(token),
            currentUserId,
            now,
            now.Add(validFor));

        await repository.AddInvitationAsync(invitation, cancellationToken);
        await repository.SaveChangesAsync(cancellationToken);
        return new CreatedInvitationResult(invitation.Id, token, invitation.ExpiresAtUtc);
    }

    public async Task<IReadOnlyList<InvitationSummary>> ListInvitationsAsync(
        Guid householdId,
        string currentUserId,
        CancellationToken cancellationToken)
    {
        var membership = await RequireMembershipAsync(householdId, currentUserId, cancellationToken);
        if (membership.Role != HouseholdRole.Owner)
        {
            throw new HouseholdAccessDeniedException("Only a household owner can list invitations.");
        }

        var now = timeProvider.GetUtcNow();
        var invitations = await repository.ListInvitationsAsync(householdId, cancellationToken);
        return invitations.Select(invitation => new InvitationSummary(
            invitation.Id,
            invitation.ExpiresAtUtc,
            invitation.AcceptedAtUtc,
            invitation.RevokedAtUtc,
            GetInvitationStatus(invitation, now))).ToArray();
    }

    public async Task<AcceptedInvitationResult> AcceptInvitationAsync(
        string userId,
        string token,
        CancellationToken cancellationToken)
    {
        EnsureUser(userId);
        var normalizedToken = token?.Trim();
        if (string.IsNullOrWhiteSpace(normalizedToken) || normalizedToken.Length > 512)
        {
            throw new ResourceNotFoundException("Invitation was not found.");
        }

        var invitation = await repository.GetInvitationByTokenHashAsync(HashToken(normalizedToken), cancellationToken)
            ?? throw new ResourceNotFoundException("Invitation was not found.");
        var now = timeProvider.GetUtcNow();
        if (!invitation.IsUsableAt(now))
        {
            throw new InvitationNotUsableException("Invitation is expired, revoked, or already used.");
        }

        var household = await repository.GetHouseholdAsync(invitation.HouseholdId, cancellationToken)
            ?? throw new ResourceNotFoundException("Household was not found.");
        var membership = await repository.GetMembershipAsync(invitation.HouseholdId, userId, cancellationToken);
        if (membership is null)
        {
            membership = new HouseholdMember(invitation.HouseholdId, userId, HouseholdRole.Member, now);
            await repository.AddMemberAsync(membership, cancellationToken);
        }

        invitation.Accept(userId, now);
        await repository.SaveChangesAsync(cancellationToken);
        return new AcceptedInvitationResult(household.Id, household.Name, membership.Role);
    }

    public async Task RevokeInvitationAsync(
        Guid householdId,
        Guid invitationId,
        string currentUserId,
        CancellationToken cancellationToken)
    {
        var membership = await RequireMembershipAsync(householdId, currentUserId, cancellationToken);
        if (membership.Role != HouseholdRole.Owner)
        {
            throw new HouseholdAccessDeniedException("Only a household owner can revoke invitations.");
        }

        var invitation = await repository.GetInvitationByIdAsync(householdId, invitationId, cancellationToken)
            ?? throw new ResourceNotFoundException("Invitation was not found.");
        try
        {
            invitation.Revoke(timeProvider.GetUtcNow());
        }
        catch (InvalidOperationException exception)
        {
            throw new InvitationNotUsableException(exception.Message);
        }

        await repository.SaveChangesAsync(cancellationToken);
    }

    public async Task RemoveMemberAsync(
        Guid householdId,
        string currentUserId,
        string memberUserId,
        CancellationToken cancellationToken)
    {
        EnsureUser(memberUserId);
        var currentMembership = await RequireMembershipAsync(householdId, currentUserId, cancellationToken);
        if (currentMembership.Role != HouseholdRole.Owner)
        {
            throw new HouseholdAccessDeniedException("Only a household owner can remove members.");
        }

        var target = await repository.GetMembershipAsync(householdId, memberUserId, cancellationToken)
            ?? throw new ResourceNotFoundException("Household member was not found.");
        if (target.Role == HouseholdRole.Owner)
        {
            throw new HouseholdAccessDeniedException("A household owner cannot be removed.");
        }

        await repository.RemoveMemberAsync(target, cancellationToken);
        await repository.SaveChangesAsync(cancellationToken);
    }

    public async Task LeaveHouseholdAsync(
        Guid householdId,
        string userId,
        CancellationToken cancellationToken)
    {
        var membership = await RequireMembershipAsync(householdId, userId, cancellationToken);
        if (membership.Role == HouseholdRole.Owner)
        {
            throw new HouseholdAccessDeniedException(
                "A household owner must transfer ownership or delete the household before leaving.");
        }

        await repository.RemoveMemberAsync(membership, cancellationToken);
        await repository.SaveChangesAsync(cancellationToken);
    }

    public async Task<CreatedEntryResult> CreateEntryAsync(
        Guid householdId,
        string userId,
        Guid entryId,
        EntryDirection direction,
        long amountInCents,
        string description,
        DateOnly occurredOn,
        string idempotencyKey,
        CancellationToken cancellationToken)
    {
        await RequireMembershipAsync(householdId, userId, cancellationToken);
        var existing = await repository.GetEntryByIdempotencyKeyAsync(householdId, idempotencyKey.Trim(), cancellationToken);
        if (existing is not null)
        {
            if (existing.Id != entryId ||
                existing.Direction != direction ||
                existing.AmountInCents != amountInCents ||
                existing.Description != description.Trim() ||
                existing.OccurredOn != occurredOn)
            {
                throw new IdempotencyConflictException("The idempotency key was already used with different data.");
            }

            return new CreatedEntryResult(ToSummary(existing), false);
        }

        var entry = new FinanceEntry(
            entryId,
            householdId,
            direction,
            amountInCents,
            description,
            occurredOn,
            idempotencyKey,
            timeProvider.GetUtcNow());

        await repository.AddEntryAsync(entry, cancellationToken);
        await repository.SaveChangesAsync(cancellationToken);
        return new CreatedEntryResult(ToSummary(entry), true);
    }

    public async Task<SyncEntriesResult> SyncEntriesAsync(
        Guid householdId,
        string userId,
        IReadOnlyList<SyncEntryCommand> commands,
        CancellationToken cancellationToken)
    {
        await RequireMembershipAsync(householdId, userId, cancellationToken);
        if (commands.Count is < 1 or > 100)
        {
            throw new ArgumentOutOfRangeException(nameof(commands), "A sync batch must contain between 1 and 100 entries.");
        }

        var results = new List<SyncedEntryResult>(commands.Count);
        var entriesByKey = new Dictionary<string, FinanceEntry>(StringComparer.Ordinal);
        var entryIds = new HashSet<Guid>();
        var pendingEntries = new List<FinanceEntry>();

        foreach (var command in commands)
        {
            if (!entryIds.Add(command.Id))
            {
                throw new ArgumentException("An entry id may appear only once in a sync batch.", nameof(commands));
            }

            var key = command.IdempotencyKey?.Trim()
                ?? throw new ArgumentException("Idempotency key is required.", nameof(commands));
            if (!entriesByKey.TryGetValue(key, out var existing))
            {
                existing = await repository.GetEntryByIdempotencyKeyAsync(householdId, key, cancellationToken);
            }

            if (existing is not null)
            {
                EnsureIdempotentMatch(existing, command);
                entriesByKey[key] = existing;
                results.Add(new SyncedEntryResult(existing.Id, key, false, existing.Version));
                continue;
            }

            var entry = new FinanceEntry(
                command.Id,
                householdId,
                command.Direction,
                command.AmountInCents,
                command.Description,
                command.OccurredOn,
                key,
                timeProvider.GetUtcNow());

            entriesByKey[key] = entry;
            pendingEntries.Add(entry);
            results.Add(new SyncedEntryResult(entry.Id, key, true, entry.Version));
        }

        foreach (var entry in pendingEntries)
        {
            await repository.AddEntryAsync(entry, cancellationToken);
        }

        if (pendingEntries.Count > 0)
        {
            await repository.SaveChangesAsync(cancellationToken);
        }

        return new SyncEntriesResult(results);
    }

    public async Task<MonthlyEntriesResult> GetMonthlyEntriesAsync(
        Guid householdId,
        string userId,
        int year,
        int month,
        CancellationToken cancellationToken)
    {
        await RequireMembershipAsync(householdId, userId, cancellationToken);
        if (year is < 2000 or > 9999) throw new ArgumentOutOfRangeException(nameof(year));
        if (month is < 1 or > 12) throw new ArgumentOutOfRangeException(nameof(month));

        var from = new DateOnly(year, month, 1);
        var until = from.AddMonths(1);
        var entries = await repository.ListEntriesAsync(householdId, from, until, cancellationToken);
        var income = entries.Where(item => item.Direction == EntryDirection.Income).Sum(item => item.AmountInCents);
        var expense = entries.Where(item => item.Direction == EntryDirection.Expense).Sum(item => item.AmountInCents);

        return new MonthlyEntriesResult(
            year,
            month,
            income,
            expense,
            income - expense,
            entries.Select(ToSummary).ToArray());
    }

    private async Task<HouseholdMember> RequireMembershipAsync(
        Guid householdId,
        string userId,
        CancellationToken cancellationToken)
    {
        EnsureUser(userId);
        var household = await repository.GetHouseholdAsync(householdId, cancellationToken);
        if (household is null)
        {
            throw new ResourceNotFoundException("Household was not found.");
        }

        return await repository.GetMembershipAsync(householdId, userId, cancellationToken)
            ?? throw new HouseholdAccessDeniedException("The user is not a member of this household.");
    }

    private static EntrySummary ToSummary(FinanceEntry entry) => new(
        entry.Id,
        entry.Direction,
        entry.AmountInCents,
        entry.Description,
        entry.OccurredOn,
        entry.Version,
        entry.UpdatedAtUtc);

    private static void EnsureIdempotentMatch(FinanceEntry existing, SyncEntryCommand command)
    {
        if (existing.Id != command.Id ||
            existing.Direction != command.Direction ||
            existing.AmountInCents != command.AmountInCents ||
            existing.Description != command.Description?.Trim() ||
            existing.OccurredOn != command.OccurredOn)
        {
            throw new IdempotencyConflictException("The idempotency key was already used with different data.");
        }
    }

    private static string CreateOpaqueToken()
    {
        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        return token.TrimEnd('=').Replace('+', '-').Replace('/', '_');
    }

    private static string HashToken(string token) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));

    private static InvitationStatus GetInvitationStatus(HouseholdInvitation invitation, DateTimeOffset now)
    {
        if (invitation.AcceptedAtUtc is not null) return InvitationStatus.Accepted;
        if (invitation.RevokedAtUtc is not null) return InvitationStatus.Revoked;
        return now >= invitation.ExpiresAtUtc ? InvitationStatus.Expired : InvitationStatus.Active;
    }

    private static void EnsureUser(string userId)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("User id is required.", nameof(userId));
        }
    }
}
