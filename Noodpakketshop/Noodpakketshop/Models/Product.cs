namespace NoodPakketShop.Models;

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string ImageEmoji { get; set; } = "圷";
    public string[] Includes { get; set; } = [];
    public bool IsFeatured { get; set; }
    public int Stock { get; set; } = 99;
}
