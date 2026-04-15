using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using NoodPakketShop.Services;

namespace NoodPakketShop.Pages;

public class BasketModel(BasketService basket) : PageModel
{
    public List<BasketItem> Items { get; private set; } = [];
    public decimal Total { get; private set; }

    public void OnGet()
    {
        Items = basket.GetItems();
        Total = basket.GetTotal();
        ViewData["BasketCount"] = basket.GetItemCount();
    }

    public IActionResult OnPostUpdateQuantity(int productId, int delta)
    {
        var items = basket.GetItems();
        var item = items.FirstOrDefault(i => i.ProductId == productId);
        if (item is not null) basket.UpdateQuantity(productId, item.Quantity + delta);
        return RedirectToPage();
    }

    public IActionResult OnPostRemove(int productId)
    {
        basket.RemoveItem(productId);
        return RedirectToPage();
    }
}
