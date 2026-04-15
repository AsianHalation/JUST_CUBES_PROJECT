using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using NoodPakketShop.Data;
using NoodPakketShop.Models;

namespace NoodPakketShop.Pages;

public class ReturnsModel(AppDbContext db) : PageModel
{
    public List<Order> EligibleOrders { get; private set; } = [];
    public List<Return> Returns { get; private set; } = [];
    public string? SuccessMessage { get; private set; }
    public int? SelectedOrderId { get; private set; }
    public string? Reason { get; private set; }

    public async Task OnGetAsync([FromQuery] int? orderId) { SelectedOrderId = orderId; await LoadDataAsync(); }

    public async Task<IActionResult> OnPostAsync(int orderId, string reason)
    {
        if (orderId <= 0 || string.IsNullOrWhiteSpace(reason)) { ModelState.AddModelError("", "Vul alle verplichte velden in."); await LoadDataAsync(); return Page(); }
        var already = await db.Returns.AnyAsync(r => r.OrderId == orderId && r.Status != ReturnStatus.Rejected);
        if (already) { ModelState.AddModelError("", "Er is al een retour aangevraagd voor deze bestelling."); SelectedOrderId=orderId; Reason=reason; await LoadDataAsync(); return Page(); }
        db.Returns.Add(new Return { OrderId=orderId, Reason=reason, Status=ReturnStatus.Requested });
        await db.SaveChangesAsync();
        SuccessMessage = "Uw retourverzoek is ingediend. U ontvangt binnen 2 werkdagen een bevestiging.";
        await LoadDataAsync();
        return Page();
    }

    private async Task LoadDataAsync()
    {
        EligibleOrders = await db.Orders.Include(o => o.Customer).Where(o => o.Status == OrderStatus.Shipped || o.Status == OrderStatus.Delivered).OrderByDescending(o => o.OrderDate).ToListAsync();
        Returns = await db.Returns.Include(r => r.Order).OrderByDescending(r => r.RequestedAt).ToListAsync();
        ViewData["BasketCount"] = 0;
    }
}
