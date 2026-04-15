namespace NoodPakketShop.Models;

public enum OrderStatus { Pending, Processing, Shipped, Delivered, Cancelled }

public class Order
{
    public int Id { get; set; }
    public int CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;
    public DateTime OrderDate { get; set; } = DateTime.UtcNow;
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public decimal TotalAmount { get; set; }
    public string TrackingNumber { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
    public ICollection<OrderItem> Items { get; set; } = [];
}
