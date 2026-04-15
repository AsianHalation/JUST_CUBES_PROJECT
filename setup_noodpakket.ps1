# =============================================================
# NoodPakket.nl — Full scaffold script
# Run from: JUST_CUBES_PROJECT root
# Usage: Right-click -> "Run with PowerShell"   OR
#        powershell -ExecutionPolicy Bypass -File setup_noodpakket.ps1
# =============================================================

$root = "$PSScriptRoot\NoodPakketShop\NoodPakketShop"
Write-Host "`n== NoodPakket Setup ==" -ForegroundColor Cyan
Write-Host "Target: $root`n"

# ── 1. Create all directories ──────────────────────────────────
$dirs = @(
    "Data\Migrations",
    "Models",
    "Services",
    "Pages\Shared",
    "wwwroot\css",
    "wwwroot\js"
)
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path "$root\$d" | Out-Null
}
Write-Host "[OK] Directories created" -ForegroundColor Green

# ── 2. Rewrite NoodPakketShop.csproj ──────────────────────────
@'
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <RootNamespace>NoodPakketShop</RootNamespace>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" Version="9.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="9.0.0">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
  </ItemGroup>
</Project>
'@ | Set-Content "$root\NoodPakketShop.csproj" -Encoding UTF8
Write-Host "[OK] NoodPakketShop.csproj" -ForegroundColor Green

# ── 3. appsettings.json ────────────────────────────────────────
@'
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=noodpakket.db"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
'@ | Set-Content "$root\appsettings.json" -Encoding UTF8
Write-Host "[OK] appsettings.json" -ForegroundColor Green

# ── 4. Program.cs ──────────────────────────────────────────────
@'
using Microsoft.EntityFrameworkCore;
using NoodPakketShop.Data;
using NoodPakketShop.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromHours(2);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

builder.Services.AddHttpContextAccessor();
builder.Services.AddSingleton<ProductCatalogService>();
builder.Services.AddScoped<BasketService>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
}

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseSession();
app.UseAuthorization();
app.MapRazorPages();

app.Run();
'@ | Set-Content "$root\Program.cs" -Encoding UTF8
Write-Host "[OK] Program.cs" -ForegroundColor Green

# ── 5. Models ──────────────────────────────────────────────────
@'
namespace NoodPakketShop.Models;

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string ImageEmoji { get; set; } = "🚨";
    public string[] Includes { get; set; } = [];
    public bool IsFeatured { get; set; }
    public int Stock { get; set; } = 99;
}
'@ | Set-Content "$root\Models\Product.cs" -Encoding UTF8

@'
namespace NoodPakketShop.Models;

public class Customer
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Street { get; set; } = string.Empty;
    public string HouseNumber { get; set; } = string.Empty;
    public string PostalCode { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Country { get; set; } = "Netherlands";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public ICollection<Order> Orders { get; set; } = [];
    public string FullName => $"{FirstName} {LastName}";
    public string FullAddress => $"{Street} {HouseNumber}, {PostalCode} {City}, {Country}";
}
'@ | Set-Content "$root\Models\Customer.cs" -Encoding UTF8

@'
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
'@ | Set-Content "$root\Models\Order.cs" -Encoding UTF8

@'
namespace NoodPakketShop.Models;

public class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public Order Order { get; set; } = null!;
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal Subtotal => UnitPrice * Quantity;
}
'@ | Set-Content "$root\Models\OrderItem.cs" -Encoding UTF8

@'
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
'@ | Set-Content "$root\Models\Return.cs" -Encoding UTF8
Write-Host "[OK] Models (Product, Customer, Order, OrderItem, Return)" -ForegroundColor Green

# ── 6. Data/AppDbContext.cs ────────────────────────────────────
@'
using Microsoft.EntityFrameworkCore;
using NoodPakketShop.Models;

namespace NoodPakketShop.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<Return> Returns => Set<Return>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Order>()
            .HasOne(o => o.Customer).WithMany(c => c.Orders).HasForeignKey(o => o.CustomerId);
        modelBuilder.Entity<OrderItem>()
            .HasOne(oi => oi.Order).WithMany(o => o.Items).HasForeignKey(oi => oi.OrderId);
        modelBuilder.Entity<Return>()
            .HasOne(r => r.Order).WithMany().HasForeignKey(r => r.OrderId);
        modelBuilder.Entity<Order>().Property(o => o.TotalAmount).HasColumnType("decimal(18,2)");
        modelBuilder.Entity<OrderItem>().Property(oi => oi.UnitPrice).HasColumnType("decimal(18,2)");
    }
}
'@ | Set-Content "$root\Data\AppDbContext.cs" -Encoding UTF8
Write-Host "[OK] Data/AppDbContext.cs" -ForegroundColor Green

# ── 7. Services ────────────────────────────────────────────────
@'
using NoodPakketShop.Models;

namespace NoodPakketShop.Services;

public class ProductCatalogService
{
    public IReadOnlyList<Product> Products { get; } = new List<Product>
    {
        new() { Id=1, Name="Basis Noodpakket", Description="Het essentiële noodpakket voor 1 persoon. Voorziet u 3 dagen van alles wat nodig is bij een ramp of crisis.", Category="Basis", Price=49.95m, ImageEmoji="🎒", IsFeatured=true, Includes=["3L drinkwater","Noodrantsoenen (3 dagen)","Ehbo-set","Zaklamp + batterijen","Fluitje","Aluminium deken"] },
        new() { Id=2, Name="Gezinspakket (4 personen)", Description="Compleet noodpakket voor een gezin van 4. Inclusief alles voor 72 uur overleven bij stroomuitval of evacuatie.", Category="Gezin", Price=149.95m, ImageEmoji="👨‍👩‍👧‍👦", IsFeatured=true, Includes=["12L drinkwater","Noodrantsoenen (4 × 3 dagen)","Uitgebreide EHBO-set","2× Zaklamp","Handradio","4× Alu deken","Hygiënepakket","Speciaal kindervoedsel"] },
        new() { Id=3, Name="Brandpakket Pro", Description="Specifiek samengesteld voor brand-noodsituaties. Inclusief brandwerende handschoenen en rookmaskers.", Category="Brand", Price=89.95m, ImageEmoji="🔥", Includes=["Rookmaskers (P3 filter, 2×)","Brandwerende handschoenen","Ontsnappingsladder 2e verdieping","Zaklamp","Fluitje","Alu deken","EHBO-set"] },
        new() { Id=4, Name="Overstroming Pakket", Description="Bescherming en overleving bij overstromingen. Waterdichte opslag en reddingsmiddelen.", Category="Overstroming", Price=119.95m, ImageEmoji="🌊", Includes=["Waterdichte opbergzak","Drijfvest (zelfopblazend)","Drinkwaterfilter","Waterproof zaklamp","Noodrantsoenen","Warmtedeken","Noodflares (3×)"] },
        new() { Id=5, Name="Auto Noodpakket", Description="Altijd klaar voor pech onderweg. Past in iedere kofferbak en bevat alles voor noodsituaties op de weg.", Category="Auto", Price=39.95m, ImageEmoji="🚗", IsFeatured=true, Includes=["Gevarendriehoek","EHBO-set","Jumpstartkabels","Zaklamp","Alu deken","Noodratio 24h","Veiligheidsvestje","Glasbreker + gordelsnijder"] },
        new() { Id=6, Name="72-Uurs Professioneel Pakket", Description="Het meest complete pakket voor maximale voorbereiding. Aanbevolen door het Rode Kruis.", Category="Premium", Price=199.95m, ImageEmoji="⭐", IsFeatured=true, Includes=["10L drinkwater","Noodrantsoenen (6 dagen)","Professionele EHBO-set","Handradio","Zonnepaneel oplader","Slaapzak","Tent (2 pers.)","Multi-tool","Medicijndoos","Hygiëneset","Waterfilter"] },
        new() { Id=7, Name="Pandemie Noodpakket", Description="Speciaal samengesteld voor infectieziekten en lockdown-scenario's. 2 weken basisvoorraad.", Category="Pandemie", Price=129.95m, ImageEmoji="😷", Includes=["FFP2-maskers (20×)","Handschoenen (50 paar)","Desinfectiemiddel (1L)","Noodrantsoenen (14 dagen)","Paracetamol & ibuprofen","Thermometer","Pulse-oximeter","EHBO-set"] },
        new() { Id=8, Name="Stroomuitval Pakket", Description="Alles voor als het licht uitvalt. Verlichting, communicatie en koude-bescherming voor 1 week.", Category="Stroom", Price=79.95m, ImageEmoji="🔦", Includes=["Powerbank 20.000mAh","Solarcharger","Kaarsen (10×) + lucifers","Camping gaslamp","Handradio","Warmtedeken","Noodrantsoenen (3 dagen)","Batterijen (AA/AAA set)"] },
    };

    public Product? GetById(int id) => Products.FirstOrDefault(p => p.Id == id);
    public IReadOnlyList<Product> GetFeatured() => Products.Where(p => p.IsFeatured).ToList();
    public IReadOnlyList<Product> GetByCategory(string category) =>
        Products.Where(p => p.Category.Equals(category, StringComparison.OrdinalIgnoreCase)).ToList();
    public IEnumerable<string> GetCategories() => Products.Select(p => p.Category).Distinct();
}
'@ | Set-Content "$root\Services\ProductCatalogService.cs" -Encoding UTF8

@'
using System.Text.Json;
using NoodPakketShop.Models;

namespace NoodPakketShop.Services;

public class BasketItem
{
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public string ImageEmoji { get; set; } = "🚨";
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
'@ | Set-Content "$root\Services\BasketService.cs" -Encoding UTF8
Write-Host "[OK] Services (ProductCatalogService, BasketService)" -ForegroundColor Green

# ── 8. Pages/Shared ────────────────────────────────────────────
@'
@namespace NoodPakketShop.Pages
@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
'@ | Set-Content "$root\Pages\Shared\_ViewImports.cshtml" -Encoding UTF8

@'
@{
    Layout = "_Layout";
}
'@ | Set-Content "$root\Pages\Shared\_ViewStart.cshtml" -Encoding UTF8

@'
<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@ViewData["Title"] — NoodPakket.nl</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;900&family=Bebas+Neue&display=swap" rel="stylesheet" />
    <link rel="stylesheet" href="~/css/site.css" asp-append-version="true" />
</head>
<body>
<header class="site-header">
    <div class="header-inner">
        <a href="/" class="logo"><span class="logo-icon">🚨</span><span class="logo-text">NOODPAKKET<span class="logo-accent">.NL</span></span></a>
        <nav class="nav-links">
            <a href="/" class="nav-link">Producten</a>
            <a href="/Orders" class="nav-link">Bestellingen</a>
            <a href="/Returns" class="nav-link">Retouren</a>
        </nav>
        <a href="/Basket" class="cart-btn">
            <span>🛒</span>
            <span>WINKELWAGEN</span>
            @if (ViewData["BasketCount"] is int count && count > 0)
            {
                <span class="cart-count">@count</span>
            }
        </a>
    </div>
</header>
<main class="main-content">@RenderBody()</main>
<footer class="site-footer">
    <div class="footer-inner">
        <div class="footer-logo">🚨 NOODPAKKET.NL</div>
        <p>Bereid u voor op het onverwachte.</p>
        <div class="footer-links">
            <a href="/Orders">Bestellingen</a>
            <a href="/Returns">Retouren</a>
        </div>
        <p class="footer-copy">© 2026 NoodPakket.nl</p>
    </div>
</footer>
<div id="toast" class="toast"></div>
<script src="~/js/site.js" asp-append-version="true"></script>
@await RenderSectionAsync("Scripts", required: false)
</body>
</html>
'@ | Set-Content "$root\Pages\Shared\_Layout.cshtml" -Encoding UTF8

@'
@model NoodPakketShop.Models.Product
<div class="product-card @(Model.IsFeatured ? "featured-card" : "")">
    @if (Model.IsFeatured) { <div class="product-badge">⭐ AANBEVOLEN</div> }
    <div class="product-visual">
        <div class="product-emoji">@Model.ImageEmoji</div>
        <div class="product-category-tag">@Model.Category</div>
    </div>
    <div class="product-info">
        <h3 class="product-name">@Model.Name</h3>
        <p class="product-desc">@Model.Description</p>
        <div class="product-includes">
            <strong>Inhoud:</strong>
            <ul>
                @foreach (var item in Model.Includes.Take(4)) { <li>✓ @item</li> }
                @if (Model.Includes.Length > 4) { <li class="more-items">+ @(Model.Includes.Length - 4) meer items</li> }
            </ul>
        </div>
        <div class="product-footer">
            <div class="product-price">€@Model.Price.ToString("F2")</div>
            <form method="post" asp-page-handler="AddToBasket">
                <input type="hidden" name="productId" value="@Model.Id" />
                <button type="submit" class="add-to-cart-btn">🛒 IN WINKELWAGEN</button>
            </form>
        </div>
    </div>
</div>
'@ | Set-Content "$root\Pages\Shared\_ProductCard.cshtml" -Encoding UTF8
Write-Host "[OK] Pages/Shared (_Layout, _ViewImports, _ViewStart, _ProductCard)" -ForegroundColor Green

# ── 9. Pages ───────────────────────────────────────────────────
@'
@page
@model IndexModel
@{ ViewData["Title"] = "Noodpakketten — Altijd Voorbereid"; }

<section class="hero">
    <div class="hero-bg"></div>
    <div class="hero-content">
        <div class="hero-badge">⚠️ OVERHEIDSAANBEVELING: 72 UUR PAKKET</div>
        <h1 class="hero-title">Bereid op<br /><em>het ergste.</em></h1>
        <p class="hero-desc">Professionele noodpakketten voor thuis, gezin en onderweg. Samengesteld door experts — aanbevolen door het Rode Kruis.</p>
        <a href="#products" class="hero-cta">BEKIJK PAKKETTEN</a>
        <div class="hero-stats">
            <div class="hero-stat"><span>72 uur</span><small>Aanbevolen voorraad</small></div>
            <div class="hero-stat"><span>8+</span><small>Scenario'"'"'s gedekt</small></div>
            <div class="hero-stat"><span>24h</span><small>Levertijd</small></div>
        </div>
    </div>
    <div class="hero-visual"><div class="hero-kit-icon">🎒</div></div>
</section>

<div class="urgency-bar">
    <span>⚡ GRATIS verzending vanaf €75</span>
    <span>🛡️ 30 dagen retourgarantie</span>
    <span>📦 Op voorraad — Morgen in huis</span>
    <span>✅ Aanbevolen door Rode Kruis</span>
</div>

<section class="categories-section">
    <div class="section-header"><h2>CATEGORIEËN</h2></div>
    <div class="categories-grid">
        @foreach (var cat in Model.Categories)
        {
            <a href="?category=@cat" class="category-pill @(Model.ActiveCategory == cat ? "active" : "")">@cat</a>
        }
        <a href="/" class="category-pill @(string.IsNullOrEmpty(Model.ActiveCategory) ? "active" : "")">Alle</a>
    </div>
</section>

@if (string.IsNullOrEmpty(Model.ActiveCategory) && Model.Featured.Any())
{
    <section class="featured-section">
        <div class="section-header"><h2>⭐ AANBEVOLEN</h2><p>Onze meest populaire noodpakketten</p></div>
        <div class="products-grid featured-grid">
            @foreach (var product in Model.Featured) { <partial name="_ProductCard" model="product" /> }
        </div>
    </section>
}

<section class="products-section" id="products">
    <div class="section-header">
        <h2>@(string.IsNullOrEmpty(Model.ActiveCategory) ? "ALLE PAKKETTEN" : Model.ActiveCategory.ToUpper())</h2>
        <p>@Model.Products.Count pakket(ten) gevonden</p>
    </div>
    <div class="products-grid">
        @foreach (var product in Model.Products) { <partial name="_ProductCard" model="product" /> }
    </div>
</section>

<section class="why-section">
    <h2>WAAROM NOODPAKKET.NL?</h2>
    <div class="why-grid">
        <div class="why-card"><div class="why-icon">🏆</div><h3>Expertsamenstelling</h3><p>Samengesteld met hulpverleners en het Rode Kruis voor maximale effectiviteit.</p></div>
        <div class="why-card"><div class="why-icon">⚡</div><h3>Snelle Levering</h3><p>Besteld voor 23:00, morgen in huis. Altijd gratis bij orders boven €75.</p></div>
        <div class="why-card"><div class="why-icon">🛡️</div><h3>Kwaliteitsgarantie</h3><p>Alle producten voldoen aan CE-normen. 30 dagen retour, geen vragen gesteld.</p></div>
        <div class="why-card"><div class="why-icon">🔄</div><h3>Vervangingsservice</h3><p>Wij herinneren u aan vervaldatums en bieden vervangingssets aan.</p></div>
    </div>
</section>
'@ | Set-Content "$root\Pages\Index.cshtml" -Encoding UTF8

@'
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
'@ | Set-Content "$root\Pages\Index.cshtml.cs" -Encoding UTF8
Write-Host "[OK] Pages/Index" -ForegroundColor Green

@'
@page
@model BasketModel
@{ ViewData["Title"] = "Winkelwagen"; }
<div class="page-container">
    <div class="page-header"><h1>🛒 WINKELWAGEN</h1><a href="/" class="btn-ghost">← Verder winkelen</a></div>
    @if (!Model.Items.Any())
    {
        <div class="empty-state">
            <div class="empty-icon">🛒</div><h2>Uw winkelwagen is leeg</h2>
            <p>Voeg noodpakketten toe om u voor te bereiden.</p>
            <a href="/" class="btn-primary">BEKIJK PAKKETTEN</a>
        </div>
    }
    else
    {
        <div class="basket-layout">
            <div class="basket-items">
                @foreach (var item in Model.Items)
                {
                    <div class="basket-item">
                        <div class="basket-item-emoji">@item.ImageEmoji</div>
                        <div class="basket-item-info"><h3>@item.ProductName</h3><p class="item-price">€@item.UnitPrice.ToString("F2") per stuk</p></div>
                        <div class="basket-item-controls">
                            <form method="post" asp-page-handler="UpdateQuantity" style="display:inline-flex;align-items:center;gap:.5rem;">
                                <input type="hidden" name="productId" value="@item.ProductId" />
                                <button type="submit" name="delta" value="-1" class="qty-btn">−</button>
                                <span class="qty-num">@item.Quantity</span>
                                <button type="submit" name="delta" value="1" class="qty-btn">+</button>
                            </form>
                            <form method="post" asp-page-handler="Remove" style="display:inline;">
                                <input type="hidden" name="productId" value="@item.ProductId" />
                                <button type="submit" class="remove-btn" title="Verwijder">✕</button>
                            </form>
                        </div>
                        <div class="basket-item-subtotal">€@item.Subtotal.ToString("F2")</div>
                    </div>
                }
            </div>
            <div class="basket-summary">
                <h2>OVERZICHT</h2>
                <div class="summary-row"><span>Subtotaal</span><span>€@Model.Total.ToString("F2")</span></div>
                <div class="summary-row"><span>Verzending</span><span>@(Model.Total >= 75 ? "GRATIS" : "€5,95")</span></div>
                @if (Model.Total >= 75) { <div class="free-shipping-badge">✅ Gratis verzending!</div> }
                else { <div class="shipping-progress">Nog €@((75 - Model.Total).ToString("F2")) voor gratis verzending</div> }
                <div class="summary-total"><span>TOTAAL</span><span>€@((Model.Total + (Model.Total >= 75 ? 0 : 5.95m)).ToString("F2"))</span></div>
                <a href="/Checkout" class="btn-primary btn-large">NAAR BETALEN →</a>
                <p class="secure-note">🔒 Veilig en versleuteld afrekenen</p>
            </div>
        </div>
    }
</div>
'@ | Set-Content "$root\Pages\Basket.cshtml" -Encoding UTF8

@'
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
'@ | Set-Content "$root\Pages\Basket.cshtml.cs" -Encoding UTF8
Write-Host "[OK] Pages/Basket" -ForegroundColor Green

@'
@page
@model CheckoutModel
@{ ViewData["Title"] = "Afrekenen"; }
<div class="page-container">
    <div class="page-header"><h1>💳 AFREKENEN</h1></div>
    <div class="checkout-layout">
        <form method="post" class="checkout-form">
            <div asp-validation-summary="ModelOnly" class="validation-summary"></div>
            <div class="form-section">
                <h2>👤 Persoonlijke gegevens</h2>
                <div class="form-row">
                    <div class="form-group"><label asp-for="Input.FirstName">Voornaam *</label><input asp-for="Input.FirstName" placeholder="Jan" /><span asp-validation-for="Input.FirstName" class="field-error"></span></div>
                    <div class="form-group"><label asp-for="Input.LastName">Achternaam *</label><input asp-for="Input.LastName" placeholder="de Vries" /><span asp-validation-for="Input.LastName" class="field-error"></span></div>
                </div>
                <div class="form-row">
                    <div class="form-group"><label asp-for="Input.Email">E-mailadres *</label><input asp-for="Input.Email" type="email" /><span asp-validation-for="Input.Email" class="field-error"></span></div>
                    <div class="form-group"><label asp-for="Input.Phone">Telefoon</label><input asp-for="Input.Phone" placeholder="+31 6 12345678" /></div>
                </div>
            </div>
            <div class="form-section">
                <h2>📦 Bezorgadres</h2>
                <div class="form-row">
                    <div class="form-group flex-3"><label asp-for="Input.Street">Straatnaam *</label><input asp-for="Input.Street" /><span asp-validation-for="Input.Street" class="field-error"></span></div>
                    <div class="form-group flex-1"><label asp-for="Input.HouseNumber">Huisnr *</label><input asp-for="Input.HouseNumber" /><span asp-validation-for="Input.HouseNumber" class="field-error"></span></div>
                </div>
                <div class="form-row">
                    <div class="form-group"><label asp-for="Input.PostalCode">Postcode *</label><input asp-for="Input.PostalCode" /><span asp-validation-for="Input.PostalCode" class="field-error"></span></div>
                    <div class="form-group"><label asp-for="Input.City">Stad *</label><input asp-for="Input.City" /><span asp-validation-for="Input.City" class="field-error"></span></div>
                </div>
                <div class="form-group"><label asp-for="Input.Country">Land</label><select asp-for="Input.Country"><option value="Netherlands">Nederland</option><option value="Belgium">België</option><option value="Germany">Duitsland</option></select></div>
                <div class="form-group"><label asp-for="Input.Notes">Opmerkingen</label><textarea asp-for="Input.Notes" rows="3"></textarea></div>
            </div>
            <div class="form-section payment-section">
                <h2>💳 Betaalmethode</h2>
                <div class="payment-methods">
                    <label class="payment-option selected"><input type="radio" name="paymentMethod" value="ideal" checked /> iDEAL</label>
                    <label class="payment-option"><input type="radio" name="paymentMethod" value="creditcard" /> Creditcard</label>
                    <label class="payment-option"><input type="radio" name="paymentMethod" value="paypal" /> PayPal</label>
                </div>
                <div class="payment-note">🔒 Demo-modus: betaling wordt automatisch goedgekeurd.</div>
            </div>
            <button type="submit" class="btn-primary btn-large btn-checkout">✅ BESTELLING PLAATSEN</button>
        </form>
        <aside class="order-summary">
            <h2>UW BESTELLING</h2>
            @foreach (var item in Model.BasketItems) { <div class="summary-item"><span>@item.ImageEmoji @item.ProductName × @item.Quantity</span><span>€@item.Subtotal.ToString("F2")</span></div> }
            <div class="summary-divider"></div>
            <div class="summary-row"><span>Subtotaal</span><span>€@Model.Subtotal.ToString("F2")</span></div>
            <div class="summary-row"><span>Verzending</span><span>@(Model.Subtotal >= 75 ? "GRATIS" : "€5,95")</span></div>
            <div class="summary-total"><span>TOTAAL</span><span>€@Model.Total.ToString("F2")</span></div>
        </aside>
    </div>
</div>
'@ | Set-Content "$root\Pages\Checkout.cshtml" -Encoding UTF8

@'
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
'@ | Set-Content "$root\Pages\Checkout.cshtml.cs" -Encoding UTF8
Write-Host "[OK] Pages/Checkout" -ForegroundColor Green

@'
@page "{orderId:int}"
@model OrderConfirmationModel
@{ ViewData["Title"] = "Bestelling bevestigd!"; }
<div class="page-container confirmation-page">
    <div class="confirmation-hero">
        <div class="confirmation-icon">✅</div>
        <h1>BESTELLING BEVESTIGD!</h1>
        <p>Bedankt voor uw bestelling, @Model.Order.Customer.FirstName!</p>
    </div>
    <div class="confirmation-layout">
        <div class="confirmation-card">
            <h2>📦 Bestelgegevens</h2>
            <div class="detail-row"><span>Bestelnummer</span><strong>#@Model.Order.Id.ToString("D6")</strong></div>
            <div class="detail-row"><span>Datum</span><strong>@Model.Order.OrderDate.ToLocalTime().ToString("dd-MM-yyyy HH:mm")</strong></div>
            <div class="detail-row"><span>Status</span><span class="status-badge status-@Model.Order.Status.ToString().ToLower()">@Model.Order.Status</span></div>
            <div class="detail-row"><span>Tracking</span><strong class="tracking-number">@Model.Order.TrackingNumber</strong></div>
            <div class="detail-row"><span>Adres</span><strong>@Model.Order.Customer.FullAddress</strong></div>
        </div>
        <div class="confirmation-card">
            <h2>🛒 Bestelde producten</h2>
            @foreach (var item in Model.Order.Items) { <div class="order-item-row"><span>@item.ProductName × @item.Quantity</span><strong>€@item.Subtotal.ToString("F2")</strong></div> }
            <div class="order-total-row"><span>TOTAAL BETAALD</span><strong>€@Model.Order.TotalAmount.ToString("F2")</strong></div>
        </div>
    </div>
    <div class="confirmation-actions">
        <a href="/Orders" class="btn-primary">📋 BEKIJK BESTELLINGEN</a>
        <a href="/" class="btn-ghost">← Verder winkelen</a>
    </div>
</div>
'@ | Set-Content "$root\Pages\OrderConfirmation.cshtml" -Encoding UTF8

@'
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
'@ | Set-Content "$root\Pages\OrderConfirmation.cshtml.cs" -Encoding UTF8
Write-Host "[OK] Pages/OrderConfirmation" -ForegroundColor Green

@'
@page
@model OrdersModel
@{ ViewData["Title"] = "Bestellingen"; }
<div class="page-container">
    <div class="page-header"><h1>📋 BESTELLINGEN</h1></div>
    @if (!Model.Orders.Any())
    {
        <div class="empty-state"><div class="empty-icon">📦</div><h2>Nog geen bestellingen</h2><a href="/" class="btn-primary">BEKIJK PAKKETTEN</a></div>
    }
    else
    {
        <div class="orders-list">
            @foreach (var order in Model.Orders)
            {
                <div class="order-card">
                    <div class="order-card-header">
                        <div><span class="order-number">Bestelling #@order.Id.ToString("D6")</span><span class="order-date">@order.OrderDate.ToLocalTime().ToString("dd-MM-yyyy")</span></div>
                        <span class="status-badge status-@order.Status.ToString().ToLower()">@order.Status</span>
                    </div>
                    <div class="order-card-body">
                        <div class="order-customer"><strong>@order.Customer.FullName</strong><span>@order.Customer.Email</span><span>@order.Customer.FullAddress</span></div>
                        <div class="order-items-list">@foreach (var item in order.Items) { <div class="order-item-mini"><span>@item.ProductName × @item.Quantity</span><span>€@item.Subtotal.ToString("F2")</span></div> }</div>
                        <div class="order-meta"><div><strong>Tracking:</strong> @order.TrackingNumber</div><div class="order-total-label">Totaal: <strong>€@order.TotalAmount.ToString("F2")</strong></div></div>
                    </div>
                    <div class="order-card-footer">
                        <a href="/OrderConfirmation/@order.Id" class="btn-ghost btn-small">Details</a>
                        @if (order.Status == NoodPakketShop.Models.OrderStatus.Delivered || order.Status == NoodPakketShop.Models.OrderStatus.Shipped) { <a href="/Returns?orderId=@order.Id" class="btn-warn btn-small">Retour aanvragen</a> }
                    </div>
                </div>
            }
        </div>
    }
</div>
'@ | Set-Content "$root\Pages\Orders.cshtml" -Encoding UTF8

@'
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
'@ | Set-Content "$root\Pages\Orders.cshtml.cs" -Encoding UTF8
Write-Host "[OK] Pages/Orders" -ForegroundColor Green

@'
@page
@model ReturnsModel
@{ ViewData["Title"] = "Retouren"; }
<div class="page-container">
    <div class="page-header"><h1>🔄 RETOUREN</h1></div>
    @if (Model.SuccessMessage != null) { <div class="alert-success">✅ @Model.SuccessMessage</div> }
    <div class="returns-layout">
        <div class="return-form-card">
            <h2>Retour aanvragen</h2>
            <form method="post">
                <div class="form-group">
                    <label>Bestelnummer *</label>
                    <select name="orderId" required>
                        <option value="">— Selecteer bestelling —</option>
                        @foreach (var order in Model.EligibleOrders) { <option value="@order.Id" selected="@(Model.SelectedOrderId == order.Id)">#@order.Id.ToString("D6") — @order.OrderDate.ToLocalTime().ToString("dd-MM-yyyy") — €@order.TotalAmount.ToString("F2")</option> }
                    </select>
                </div>
                <div class="form-group"><label>Reden *</label><textarea name="reason" rows="4" required>@Model.Reason</textarea></div>
                <button type="submit" class="btn-primary">RETOUR AANVRAGEN</button>
            </form>
        </div>
        <div class="returns-list-card">
            <h2>Mijn retouren</h2>
            @if (!Model.Returns.Any()) { <p class="no-returns">Geen retouren aangevraagd.</p> }
            else
            {
                @foreach (var ret in Model.Returns)
                {
                    <div class="return-item">
                        <div class="return-item-header"><span>Bestelling #@ret.Order.Id.ToString("D6")</span><span class="status-badge status-@ret.Status.ToString().ToLower()">@ret.Status</span></div>
                        <p class="return-reason">@ret.Reason</p>
                        <small>@ret.RequestedAt.ToLocalTime().ToString("dd-MM-yyyy HH:mm")</small>
                    </div>
                }
            }
        </div>
    </div>
</div>
'@ | Set-Content "$root\Pages\Returns.cshtml" -Encoding UTF8

@'
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
'@ | Set-Content "$root\Pages\Returns.cshtml.cs" -Encoding UTF8
Write-Host "[OK] Pages/Returns" -ForegroundColor Green

# ── 10. wwwroot/js/site.js (minimal) ──────────────────────────
@'
(function () {
    const toast = document.getElementById("toast");
    if (!toast) return;
    window.showToast = function (message) {
        toast.textContent = message;
        toast.classList.add("show");
        clearTimeout(window._toastTimer);
        window._toastTimer = setTimeout(() => toast.classList.remove("show"), 3000);
    };
})();

document.querySelectorAll(".payment-option").forEach(option => {
    option.addEventListener("click", () => {
        document.querySelectorAll(".payment-option").forEach(o => o.classList.remove("selected"));
        option.classList.add("selected");
    });
});
'@ | Set-Content "$root\wwwroot\js\site.js" -Encoding UTF8
Write-Host "[OK] wwwroot/js/site.js" -ForegroundColor Green

# ── 11. wwwroot/css/site.css (placeholder — replace with full CSS from Copilot) ──
if (-not (Test-Path "$root\wwwroot\css\site.css")) {
    "/* Paste full site.css here from Copilot output */" | Set-Content "$root\wwwroot\css\site.css" -Encoding UTF8
    Write-Host "[NOTICE] wwwroot/css/site.css created as placeholder — paste the full CSS from Copilot" -ForegroundColor Yellow
} else {
    Write-Host "[SKIP] wwwroot/css/site.css already exists" -ForegroundColor DarkYellow
}

# ── 12. Install NuGet packages & run migrations ────────────────
Write-Host "`nInstalling NuGet packages..." -ForegroundColor Cyan
Push-Location $root
dotnet add package Microsoft.EntityFrameworkCore.Sqlite --version 9.0.0
dotnet add package Microsoft.EntityFrameworkCore.Design --version 9.0.0

Write-Host "`nRestoring packages..." -ForegroundColor Cyan
dotnet restore

Write-Host "`nCreating EF Core migration..." -ForegroundColor Cyan
dotnet tool install --global dotnet-ef --version 9.0.0 2>$null
dotnet ef migrations add InitialCreate --output-dir Data/Migrations

Pop-Location

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " ALL DONE! To run the app:" -ForegroundColor Green
Write-Host "   cd NoodPakketShop\NoodPakketShop" -ForegroundColor White
Write-Host "   dotnet run" -ForegroundColor White
Write-Host "============================================`n" -ForegroundColor Cyan