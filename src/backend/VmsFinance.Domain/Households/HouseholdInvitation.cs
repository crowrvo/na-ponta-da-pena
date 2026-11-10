namespace VmsFinance.Domain.Households;

public sealed class HouseholdInvitation
{
    private HouseholdInvitation() { }

    public HouseholdInvitation(
        Guid id,
        Guid householdId,
        string tokenHash,
        string createdByUserId,
        DateTimeOffset createdAtUtc,
        DateTimeOffset expiresAtUtc)
    {
        if (id == Guid.Empty) throw new ArgumentException("Invitation id is required.", nameof(id));
        if (householdId == Guid.Empty) throw new ArgumentException("Household is required.", nameof(householdId));
        if (string.IsNullOrWhiteSpace(tokenHash)) throw new ArgumentException("Token hash is required.", nameof(tokenHash));
        if (tokenHash.Length != 64) throw new ArgumentOutOfRangeException(nameof(tokenHash));
        if (string.IsNullOrWhiteSpace(createdByUserId)) throw new ArgumentException("Creator user id is required.", nameof(createdByUserId));
        if (createdByUserId.Trim().Length > 200) throw new ArgumentOutOfRangeException(nameof(createdByUserId));
        if (expiresAtUtc <= createdAtUtc) throw new ArgumentOutOfRangeException(nameof(expiresAtUtc));

        Id = id;
        HouseholdId = householdId;
        TokenHash = tokenHash;
        CreatedByUserId = createdByUserId.Trim();
        CreatedAtUtc = createdAtUtc;
        ExpiresAtUtc = expiresAtUtc;
        Version = 1;
    }

    public Guid Id { get; private set; }
    public Guid HouseholdId { get; private set; }
    public string TokenHash { get; private set; } = string.Empty;
    public string CreatedByUserId { get; private set; } = string.Empty;
    public DateTimeOffset CreatedAtUtc { get; private set; }
    public DateTimeOffset ExpiresAtUtc { get; private set; }
    public string? AcceptedByUserId { get; private set; }
    public DateTimeOffset? AcceptedAtUtc { get; private set; }
    public DateTimeOffset? RevokedAtUtc { get; private set; }
    public long Version { get; private set; }

    public bool IsUsableAt(DateTimeOffset now) =>
        AcceptedAtUtc is null && RevokedAtUtc is null && now < ExpiresAtUtc;

    public void Accept(string userId, DateTimeOffset now)
    {
        if (string.IsNullOrWhiteSpace(userId)) throw new ArgumentException("User id is required.", nameof(userId));
        if (userId.Trim().Length > 200) throw new ArgumentOutOfRangeException(nameof(userId));
        if (!IsUsableAt(now)) throw new InvalidOperationException("Invitation is no longer usable.");

        AcceptedByUserId = userId.Trim();
        AcceptedAtUtc = now;
        Version++;
    }

    public void Revoke(DateTimeOffset now)
    {
        if (AcceptedAtUtc is not null) throw new InvalidOperationException("An accepted invitation cannot be revoked.");
        if (RevokedAtUtc is null)
        {
            RevokedAtUtc = now;
            Version++;
        }
    }
}
