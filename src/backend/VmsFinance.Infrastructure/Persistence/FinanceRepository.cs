using Microsoft.EntityFrameworkCore;
using VmsFinance.Application.Abstractions;
using VmsFinance.Domain.Finance;
using VmsFinance.Domain.Households;

namespace VmsFinance.Infrastructure.Persistence;

public sealed class FinanceRepository(FinanceDbContext dbContext) : IFinanceRepository
{
    public async Task AddHouseholdAsync(Household household, HouseholdMember owner, CancellationToken cancellationToken)
    {
        await dbContext.Households.AddAsync(household, cancellationToken);
        await dbContext.HouseholdMembers.AddAsync(owner, cancellationToken);
    }

    public async Task<IReadOnlyList<Household>> ListHouseholdsAsync(string userId, CancellationToken cancellationToken) =>
        await (from household in dbContext.Households.AsNoTracking()
               join member in dbContext.HouseholdMembers.AsNoTracking() on household.Id equals member.HouseholdId
               where member.UserId == userId
               orderby household.Name
               select household).ToListAsync(cancellationToken);

    public Task<Household?> GetHouseholdAsync(Guid householdId, CancellationToken cancellationToken) =>
        dbContext.Households.AsNoTracking().SingleOrDefaultAsync(item => item.Id == householdId, cancellationToken);

    public Task<HouseholdMember?> GetMembershipAsync(Guid householdId, string userId, CancellationToken cancellationToken) =>
        dbContext.HouseholdMembers.AsNoTracking()
            .SingleOrDefaultAsync(item => item.HouseholdId == householdId && item.UserId == userId, cancellationToken);

    public async Task AddMemberAsync(HouseholdMember member, CancellationToken cancellationToken) =>
        await dbContext.HouseholdMembers.AddAsync(member, cancellationToken);

    public Task RemoveMemberAsync(HouseholdMember member, CancellationToken cancellationToken)
    {
        dbContext.HouseholdMembers.Remove(member);
        return Task.CompletedTask;
    }

    public async Task AddInvitationAsync(HouseholdInvitation invitation, CancellationToken cancellationToken) =>
        await dbContext.HouseholdInvitations.AddAsync(invitation, cancellationToken);

    public Task<HouseholdInvitation?> GetInvitationByIdAsync(
        Guid householdId,
        Guid invitationId,
        CancellationToken cancellationToken) =>
        dbContext.HouseholdInvitations.SingleOrDefaultAsync(
            item => item.HouseholdId == householdId && item.Id == invitationId,
            cancellationToken);

    public Task<HouseholdInvitation?> GetInvitationByTokenHashAsync(
        string tokenHash,
        CancellationToken cancellationToken) =>
        dbContext.HouseholdInvitations.SingleOrDefaultAsync(item => item.TokenHash == tokenHash, cancellationToken);

    public async Task<IReadOnlyList<HouseholdInvitation>> ListInvitationsAsync(
        Guid householdId,
        CancellationToken cancellationToken) =>
        await dbContext.HouseholdInvitations.AsNoTracking()
            .Where(item => item.HouseholdId == householdId)
            .OrderByDescending(item => item.CreatedAtUtc)
            .ToListAsync(cancellationToken);

    public Task<FinanceEntry?> GetEntryByIdempotencyKeyAsync(Guid householdId, string idempotencyKey, CancellationToken cancellationToken) =>
        dbContext.FinanceEntries.AsNoTracking()
            .SingleOrDefaultAsync(item => item.HouseholdId == householdId && item.IdempotencyKey == idempotencyKey, cancellationToken);

    public async Task AddEntryAsync(FinanceEntry entry, CancellationToken cancellationToken) =>
        await dbContext.FinanceEntries.AddAsync(entry, cancellationToken);

    public async Task<IReadOnlyList<FinanceEntry>> ListEntriesAsync(Guid householdId, DateOnly from, DateOnly until, CancellationToken cancellationToken) =>
        await dbContext.FinanceEntries.AsNoTracking()
            .Where(item => item.HouseholdId == householdId && item.OccurredOn >= from && item.OccurredOn < until)
            .OrderByDescending(item => item.OccurredOn)
            .ThenByDescending(item => item.CreatedAtUtc)
            .ToListAsync(cancellationToken);

    public async Task SaveChangesAsync(CancellationToken cancellationToken)
    {
        try
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException)
        {
            throw new VmsFinance.Application.Common.InvitationNotUsableException(
                "The invitation was changed by another request.");
        }
    }
}
