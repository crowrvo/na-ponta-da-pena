namespace VmsFinance.Domain.Finance;

public enum EntryDirection
{
    Expense = 0,
    Income = 1,
}

public sealed class FinanceEntry
{
    private FinanceEntry() { }

    public FinanceEntry(Guid householdId, EntryDirection direction, long amountInCents, string description, DateOnly occurredOn)
    {
        if (householdId == Guid.Empty) throw new ArgumentException("Household is required.", nameof(householdId));
        if (amountInCents <= 0) throw new ArgumentOutOfRangeException(nameof(amountInCents));
        if (string.IsNullOrWhiteSpace(description)) throw new ArgumentException("Description is required.", nameof(description));

        Id = Guid.NewGuid();
        HouseholdId = householdId;
        Direction = direction;
        AmountInCents = amountInCents;
        Description = description.Trim();
        OccurredOn = occurredOn;
        CreatedAtUtc = DateTimeOffset.UtcNow;
        UpdatedAtUtc = CreatedAtUtc;
    }

    public Guid Id { get; private set; }
    public Guid HouseholdId { get; private set; }
    public EntryDirection Direction { get; private set; }
    public long AmountInCents { get; private set; }
    public string Description { get; private set; } = string.Empty;
    public DateOnly OccurredOn { get; private set; }
    public DateTimeOffset CreatedAtUtc { get; private set; }
    public DateTimeOffset UpdatedAtUtc { get; private set; }
}

