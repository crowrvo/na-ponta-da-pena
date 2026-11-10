namespace VmsFinance.Application.Common;

public sealed class ResourceNotFoundException(string message) : Exception(message);

public sealed class HouseholdAccessDeniedException(string message) : Exception(message);

public sealed class IdempotencyConflictException(string message) : Exception(message);

public sealed class InvitationNotUsableException(string message) : Exception(message);
