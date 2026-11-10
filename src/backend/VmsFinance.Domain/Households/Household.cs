namespace VmsFinance.Domain.Households;

public sealed class Household
{
    private Household() { }

    public Household(Guid id, string name, DateTimeOffset createdAtUtc)
    {
        if (id == Guid.Empty) throw new ArgumentException("Household id is required.", nameof(id));
        if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Household name is required.", nameof(name));
        if (name.Trim().Length > 120) throw new ArgumentOutOfRangeException(nameof(name));

        Id = id;
        Name = name.Trim();
        CreatedAtUtc = createdAtUtc;
    }

    public Guid Id { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public DateTimeOffset CreatedAtUtc { get; private set; }
}
