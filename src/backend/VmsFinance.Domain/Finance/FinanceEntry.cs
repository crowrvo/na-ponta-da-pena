namespace VmsFinance.Domain.Finance;

public enum EntryDirection
{
    Expense = 0,
    Income = 1,
}

public sealed class FinanceEntry
{
    private FinanceEntry() { }

    public FinanceEntry(
        Guid id,
        Guid householdId,
        EntryDirection direction,
        long amountInCents,
        string description,
        DateOnly occurredOn,
        string idempotencyKey,
        DateTimeOffset createdAtUtc)
    {
        if (id == Guid.Empty) throw new ArgumentException("Entry id is required.", nameof(id));
        if (householdId == Guid.Empty) throw new ArgumentException("Household is required.", nameof(householdId));
        if (amountInCents <= 0) throw new ArgumentOutOfRangeException(nameof(amountInCents));
        if (string.IsNullOrWhiteSpace(description)) throw new ArgumentException("Description is required.", nameof(description));
        if (description.Trim().Length > 240) throw new ArgumentOutOfRangeException(nameof(description));
        if (string.IsNullOrWhiteSpace(idempotencyKey)) throw new ArgumentException("Idempotency key is required.", nameof(idempotencyKey));
        if (idempotencyKey.Trim().Length > 100) throw new ArgumentOutOfRangeException(nameof(idempotencyKey));

        Id = id;
        HouseholdId = householdId;
        Direction = direction;
        AmountInCents = amountInCents;
        Description = description.Trim();
        OccurredOn = occurredOn;
        IdempotencyKey = idempotencyKey.Trim();
        Version = 1;
        CreatedAtUtc = createdAtUtc;
        UpdatedAtUtc = CreatedAtUtc;
    }

    public Guid Id { get; private set; }
    public Guid HouseholdId { get; private set; }
    public EntryDirection Direction { get; private set; }
    public long AmountInCents { get; private set; }
    public string Description { get; private set; } = string.Empty;
    public DateOnly OccurredOn { get; private set; }
    public string IdempotencyKey { get; private set; } = string.Empty;
    public long Version { get; private set; }
    public DateTimeOffset CreatedAtUtc { get; private set; }
    public DateTimeOffset UpdatedAtUtc { get; private set; }
}

