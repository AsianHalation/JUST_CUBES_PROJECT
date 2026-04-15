namespace NoodPakketShop.Models;

public enum ReturnStatus { Requested, Approved, Received, Refunded, Rejected }

public class Return
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public Order Order { get; set; } = null!;
    public string Reason { get; set; } = string.Empty;
    public ReturnStatus Status { get; set; } = ReturnStatus.Requested;
    public DateTime RequestedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
}
