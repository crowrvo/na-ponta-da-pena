using VmsFinance.Domain.Finance;
using VmsFinance.Domain.Households;

namespace VmsFinance.Application.Finance;

public sealed record HouseholdSummary(Guid Id, string Name, HouseholdRole Role);

public sealed record EntrySummary(
    Guid Id,
    EntryDirection Direction,
    long AmountInCents,
    string Description,
    DateOnly OccurredOn,
    long Version,
    DateTimeOffset UpdatedAtUtc);

public sealed record MonthlyEntriesResult(
    int Year,
    int Month,
    long IncomeInCents,
    long ExpenseInCents,
    long BalanceInCents,
    IReadOnlyList<EntrySummary> Entries);

public sealed record CreatedEntryResult(EntrySummary Entry, bool Created);

public sealed record SyncEntryCommand(
    Guid Id,
    EntryDirection Direction,
    long AmountInCents,
    string Description,
    DateOnly OccurredOn,
    string IdempotencyKey);

public sealed record SyncedEntryResult(Guid Id, string IdempotencyKey, bool Created, long Version);

public sealed record SyncEntriesResult(IReadOnlyList<SyncedEntryResult> Results);
