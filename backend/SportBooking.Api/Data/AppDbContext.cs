using Microsoft.EntityFrameworkCore;
using SportBooking.Api.Models;

namespace SportBooking.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Venue> Venues => Set<Venue>();
    public DbSet<Court> Courts => Set<Court>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<AccessCode> AccessCodes => Set<AccessCode>();
    public DbSet<CheckInLog> CheckInLogs => Set<CheckInLog>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<User>().HasIndex(u => u.Email).IsUnique();
        b.Entity<AccessCode>().HasIndex(a => a.Token).IsUnique();

        b.Entity<Court>().Property(c => c.PricePerHour).HasPrecision(18, 2);
        b.Entity<Booking>().Property(x => x.TotalPrice).HasPrecision(18, 2);
        b.Entity<Payment>().Property(p => p.Amount).HasPrecision(18, 2);

        // lưu enum dạng chữ cho dễ đọc trong DB
        b.Entity<User>().Property(u => u.Role).HasConversion<string>();
        b.Entity<Booking>().Property(x => x.Status).HasConversion<string>();
        b.Entity<Payment>().Property(p => p.Status).HasConversion<string>();
        b.Entity<AccessCode>().Property(a => a.Type).HasConversion<string>();
        b.Entity<AccessCode>().Property(a => a.Status).HasConversion<string>();

        // tránh lỗi "multiple cascade paths" của SQL Server
        b.Entity<Booking>().HasOne(x => x.User).WithMany(u => u.Bookings)
            .HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<Booking>().HasOne(x => x.Court).WithMany()
            .HasForeignKey(x => x.CourtId).OnDelete(DeleteBehavior.Restrict);
        b.Entity<CheckInLog>().HasOne(l => l.AccessCode).WithMany()
            .HasForeignKey(l => l.AccessCodeId).OnDelete(DeleteBehavior.Restrict);
    }
}