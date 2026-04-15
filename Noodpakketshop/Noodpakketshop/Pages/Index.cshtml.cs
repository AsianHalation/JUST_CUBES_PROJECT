using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using NoodPakketShop.Models;
using NoodPakketShop.Services;

namespace NoodPakketShop.Pages;

public class IndexModel(ProductCatalogService catalog, BasketService basket) : PageModel
{
    public IReadOnlyList<Product> Products { get; private set; } = [];
    public IReadOnlyList<Product> Featured { get; private set; } = [];
    public IEnumerable<string> Categories { get; private set; } = [];
    public string? ActiveCategory { get; private set; }

    public void OnGet([FromQuery] string? category)
    {
        ActiveCategory = category;
        Categories = catalog.GetCategories();
        Featured = catalog.GetFeatured();
        Products = string.IsNullOrEmpty(category) ? catalog.Products : catalog.GetByCategory(category);
        ViewData["BasketCount"] = basket.GetItemCount();
    }

    public IActionResult OnPostAddToBasket(int productId)
    {
        basket.AddItem(productId);
        return RedirectToPage();
    }
}
