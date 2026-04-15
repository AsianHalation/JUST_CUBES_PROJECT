using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using NoodPakketShop.Data;
using NoodPakketShop.Models;
using NoodPakketShop.Services;

namespace NoodPakketShop.Pages;

public class CheckoutInput
{
    [Required(ErrorMessage = "Voornaam is verplicht")] public string FirstName { get; set; } = string.Empty;
    [Required(ErrorMessage = "Achternaam is verplicht")] public string LastName { get; set; } = string.Empty;
    [Required(ErrorMessage = "E-mailadres is verplicht")][EmailAddress] public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    [Required(ErrorMessage = "Straatnaam is verplicht")] public string Street { get; set; } = string.Empty;
    [Required(ErrorMessage = "Huisnummer is verplicht")] public string HouseNumber { get; set; } = string.Empty;
    [Required(ErrorMessage = "Postcode is verplicht")] public string PostalCode { get; set; } = string.Empty;
    [Required(ErrorMessage = "Stad is verplicht")] public string City { get; set; } = string.Empty;
    public string Country { get; set; } = "Netherlands";
    public string Notes { get; set; } = string.Empty;
}

public class CheckoutModel(BasketService basket, AppDbContext db) : PageModel
{
    [BindProperty] public CheckoutInput Input { get; set; } = new();
    public List<BasketItem> BasketItems { get; private set; } = [];
    public decimal Subtotal { get; private set; }
    public decimal Total { get; private set; }

    public IActionResult OnGet()
    {
        BasketItems = basket.GetItems();
        if (!BasketItems.Any()) return RedirectToPage("/Basket");
        Subtotal = basket.GetTotal();
        Total = Subtotal + (Subtotal >= 75 ? 0 : 5.95m);
        ViewData["BasketCount"] = basket.GetItemCount();
        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        BasketItems = basket.GetItems();
        Subtotal = basket.GetTotal();
        Total = Subtotal + (Subtotal >= 75 ? 0 : 5.95m);
        ViewData["BasketCount"] = basket.GetItemCount();
        if (!ModelState.IsValid) return Page();
        if (!BasketItems.Any()) return RedirectToPage("/Basket");

        var customer = await db.Customers.FirstOrDefaultAsync(c => c.Email == Input.Email) ?? new Customer();
        customer.FirstName = Input.FirstName; customer.LastName = Input.LastName;
        customer.Email = Input.Email; customer.Phone = Input.Phone;
        customer.Street = Input.Street; customer.HouseNumber = Input.HouseNumber;
        customer.PostalCode = Input.PostalCode; customer.City = Input.City;
        customer.Country = Input.Country;
        if (customer.Id == 0) db.Customers.Add(customer);
        await db.SaveChangesAsync();

        var order = new Order
        {
            CustomerId = customer.Id, TotalAmount = Total,
            Status = OrderStatus.Processing, Notes = Input.Notes,
            TrackingNumber = $"NL{DateTime.UtcNow:yyyyMMdd}{Random.Shared.Next(100000, 999999)}",
            Items = BasketItems.Select(i => new OrderItem { ProductId=i.ProductId, ProductName=i.ProductName, Quantity=i.Quantity, UnitPrice=i.UnitPrice }).ToList()
        };
        db.Orders.Add(order);
        await db.SaveChangesAsync();
        basket.Clear();
        return RedirectToPage("/OrderConfirmation", new { orderId = order.Id });
    }
}
