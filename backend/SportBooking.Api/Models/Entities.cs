namespace SportBooking.Api.Models;

public enum UserRole { User = 0, Gate = 1, Admin = 2 }
public enum BookingStatus { Pending = 0, Paid = 1, CheckedIn = 2, Completed = 3, Cancelled = 4, Expired = 5 }
public enum PaymentStatus { Pending = 0, Success = 1, Failed = 2 }
public enum AccessCodeType { Owner = 0, Share = 1 }
public enum AccessCodeStatus { Active = 0, Used = 1, Revoked = 2 }

public class User
{
    public int Id { get; set; }
    public string FullName { get; set; } = "";
    public string Email { get; set; } = "";
    public string PasswordHash { get; set; } = "";
    public UserRole Role { get; set; } = UserRole.User;

    public List<Booking> Bookings { get; set; } = new();
}

public class Venue
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Address { get; set; } = "";

    public List<Court> Courts { get; set; } = new();
}

public class Court
{
    public int Id { get; set; }
    public int VenueId { get; set; }
    public string Name { get; set; } = "";
    public string SportType { get; set; } = "";
    public decimal PricePerHour { get; set; }

    public Venue? Venue { get; set; }
}

public class Booking
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int CourtId { get; set; }
    public DateTime StartTime { get; set; }   // lưu UTC
    public DateTime EndTime { get; set; }     // lưu UTC
    public decimal TotalPrice { get; set; }
    public BookingStatus Status { get; set; } = BookingStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public Court? Court { get; set; }
    public List<Payment> Payments { get; set; } = new();
    public List<AccessCode> AccessCodes { get; set; } = new();
}

public class Payment
{
    public int Id { get; set; }
    public int BookingId { get; set; }
    public decimal Amount { get; set; }
    public string Method { get; set; } = "";
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public DateTime? PaidAt { get; set; }
    public string? TransactionRef { get; set; }

    public Booking? Booking { get; set; }
}

public class AccessCode
{
    public int Id { get; set; }
    public int BookingId { get; set; }
    public string Token { get; set; } = "";
    public AccessCodeType Type { get; set; }
    public int MaxUses { get; set; } = 1;
    public int UsedCount { get; set; } = 0;
    public AccessCodeStatus Status { get; set; } = AccessCodeStatus.Active;
    public DateTime ExpiresAt { get; set; }

    public Booking? Booking { get; set; }
}

public class CheckInLog
{
    public int Id { get; set; }
    public int AccessCodeId { get; set; }
    public DateTime ScannedAt { get; set; } = DateTime.UtcNow;
    public string Result { get; set; } = "";
    public string? Reason { get; set; }

    public AccessCode? AccessCode { get; set; }
}