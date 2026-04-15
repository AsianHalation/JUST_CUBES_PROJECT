using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using NoodPakketShop.Data;
using NoodPakketShop.Models;

namespace NoodPakketShop.Pages;

public class OrdersModel(AppDbContext db) : PageModel
{
    public List<Order> Orders { get; private set; } = [];

    public async Task OnGetAsync()
    {
        Orders = await db.Orders.Include(o => o.Customer).Include(o => o.Items).OrderByDescending(o => o.OrderDate).ToListAsync();
        ViewData["BasketCount"] = 0;
    }
}
