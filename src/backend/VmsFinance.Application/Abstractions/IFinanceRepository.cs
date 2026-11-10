using VmsFinance.Domain.Finance;
using VmsFinance.Domain.Households;

namespace VmsFinance.Application.Abstractions;

public interface IFinanceRepository
{
    Task AddHouseholdAsync(Household household, HouseholdMember owner, CancellationToken cancellationToken);
    Task<IReadOnlyList<Household>> ListHouseholdsAsync(string userId, CancellationToken cancellationToken);
    Task<Household?> GetHouseholdAsync(Guid householdId, CancellationToken cancellationToken);
    Task<HouseholdMember?> GetMembershipAsync(Guid householdId, string userId, CancellationToken cancellationToken);
    Task AddMemberAsync(HouseholdMember member, CancellationToken cancellationToken);
    Task RemoveMemberAsync(HouseholdMember member, CancellationToken cancellationToken);
    Task AddInvitationAsync(HouseholdInvitation invitation, CancellationToken cancellationToken);
    Task<HouseholdInvitation?> GetInvitationByIdAsync(Guid householdId, Guid invitationId, CancellationToken cancellationToken);
    Task<HouseholdInvitation?> GetInvitationByTokenHashAsync(string tokenHash, CancellationToken cancellationToken);
    Task<IReadOnlyList<HouseholdInvitation>> ListInvitationsAsync(Guid householdId, CancellationToken cancellationToken);
    Task<FinanceEntry?> GetEntryByIdempotencyKeyAsync(Guid householdId, string idempotencyKey, CancellationToken cancellationToken);
    Task AddEntryAsync(FinanceEntry entry, CancellationToken cancellationToken);
    Task<IReadOnlyList<FinanceEntry>> ListEntriesAsync(Guid householdId, DateOnly from, DateOnly until, CancellationToken cancellationToken);
    Task SaveChangesAsync(CancellationToken cancellationToken);
}
