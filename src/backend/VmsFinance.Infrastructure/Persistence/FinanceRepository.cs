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

    public Task SaveChangesAsync(CancellationToken cancellationToken) => dbContext.SaveChangesAsync(cancellationToken);
}
