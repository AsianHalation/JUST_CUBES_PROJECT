using System.Text.Json;
using NoodPakketShop.Models;

namespace NoodPakketShop.Services;

public class BasketItem
{
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public string ImageEmoji { get; set; } = "圷";
    public decimal Subtotal => UnitPrice * Quantity;
}

public class BasketService(IHttpContextAccessor httpContextAccessor, ProductCatalogService catalog)
{
    private const string SessionKey = "basket";
    private ISession Session => httpContextAccessor.HttpContext!.Session;

    private List<BasketItem> LoadBasket()
    {
        var json = Session.GetString(SessionKey);
        return string.IsNullOrEmpty(json) ? [] : JsonSerializer.Deserialize<List<BasketItem>>(json) ?? [];
    }

    private void SaveBasket(List<BasketItem> items) =>
        Session.SetString(SessionKey, JsonSerializer.Serialize(items));

    public List<BasketItem> GetItems() => LoadBasket();
    public int GetItemCount() => LoadBasket().Sum(i => i.Quantity);
    public decimal GetTotal() => LoadBasket().Sum(i => i.Subtotal);

    public void AddItem(int productId, int quantity = 1)
    {
        var product = catalog.GetById(productId);
        if (product is null) return;
        var basket = LoadBasket();
        var existing = basket.FirstOrDefault(i => i.ProductId == productId);
        if (existing is not null) existing.Quantity += quantity;
        else basket.Add(new BasketItem { ProductId=productId, ProductName=product.Name, UnitPrice=product.Price, Quantity=quantity, ImageEmoji=product.ImageEmoji });
        SaveBasket(basket);
    }

    public void RemoveItem(int productId) { var b = LoadBasket(); b.RemoveAll(i => i.ProductId == productId); SaveBasket(b); }

    public void UpdateQuantity(int productId, int quantity)
    {
        var basket = LoadBasket();
        var item = basket.FirstOrDefault(i => i.ProductId == productId);
        if (item is null) return;
        if (quantity <= 0) basket.Remove(item); else item.Quantity = quantity;
        SaveBasket(basket);
    }

    public void Clear() => Session.Remove(SessionKey);
}
