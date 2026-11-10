namespace VmsFinance.Domain.Households;

public enum HouseholdRole
{
    Member = 0,
    Owner = 1,
}

public sealed class HouseholdMember
{
    private HouseholdMember() { }

    public HouseholdMember(Guid householdId, string userId, HouseholdRole role, DateTimeOffset joinedAtUtc)
    {
        if (householdId == Guid.Empty) throw new ArgumentException("Household is required.", nameof(householdId));
        if (string.IsNullOrWhiteSpace(userId)) throw new ArgumentException("User id is required.", nameof(userId));
        if (userId.Trim().Length > 200) throw new ArgumentOutOfRangeException(nameof(userId));

        HouseholdId = householdId;
        UserId = userId.Trim();
        Role = role;
        JoinedAtUtc = joinedAtUtc;
    }

    public Guid HouseholdId { get; private set; }
    public string UserId { get; private set; } = string.Empty;
    public HouseholdRole Role { get; private set; }
    public DateTimeOffset JoinedAtUtc { get; private set; }
}
