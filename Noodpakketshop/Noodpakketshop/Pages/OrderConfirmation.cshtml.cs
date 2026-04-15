using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using NoodPakketShop.Data;
using NoodPakketShop.Models;

namespace NoodPakketShop.Pages;

public class OrderConfirmationModel(AppDbContext db) : PageModel
{
    public Order Order { get; private set; } = null!;

    public async Task<IActionResult> OnGetAsync(int orderId)
    {
        var order = await db.Orders.Include(o => o.Customer).Include(o => o.Items).FirstOrDefaultAsync(o => o.Id == orderId);
        if (order is null) return RedirectToPage("/Index");
        Order = order;
        return Page();
    }
}
