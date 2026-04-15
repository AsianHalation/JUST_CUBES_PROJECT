using NoodPakketShop.Models;

namespace NoodPakketShop.Services;

public class ProductCatalogService
{
    public IReadOnlyList<Product> Products { get; } = new List<Product>
    {
        new() { Id=1, Name="Basis Noodpakket", Description="Het essentiﾃｫle noodpakket voor 1 persoon. Voorziet u 3 dagen van alles wat nodig is bij een ramp of crisis.", Category="Basis", Price=49.95m, ImageEmoji="賜", IsFeatured=true, Includes=["3L drinkwater","Noodrantsoenen (3 dagen)","Ehbo-set","Zaklamp + batterijen","Fluitje","Aluminium deken"] },
        new() { Id=2, Name="Gezinspakket (4 personen)", Description="Compleet noodpakket voor een gezin van 4. Inclusief alles voor 72 uur overleven bij stroomuitval of evacuatie.", Category="Gezin", Price=149.95m, ImageEmoji="捉窶昨汨ｩ窶昨汨ｧ窶昨汨ｦ", IsFeatured=true, Includes=["12L drinkwater","Noodrantsoenen (4 ﾃ・3 dagen)","Uitgebreide EHBO-set","2ﾃ・Zaklamp","Handradio","4ﾃ・Alu deken","Hygiﾃｫnepakket","Speciaal kindervoedsel"] },
        new() { Id=3, Name="Brandpakket Pro", Description="Specifiek samengesteld voor brand-noodsituaties. Inclusief brandwerende handschoenen en rookmaskers.", Category="Brand", Price=89.95m, ImageEmoji="櫨", Includes=["Rookmaskers (P3 filter, 2ﾃ・","Brandwerende handschoenen","Ontsnappingsladder 2e verdieping","Zaklamp","Fluitje","Alu deken","EHBO-set"] },
        new() { Id=4, Name="Overstroming Pakket", Description="Bescherming en overleving bij overstromingen. Waterdichte opslag en reddingsmiddelen.", Category="Overstroming", Price=119.95m, ImageEmoji="穴", Includes=["Waterdichte opbergzak","Drijfvest (zelfopblazend)","Drinkwaterfilter","Waterproof zaklamp","Noodrantsoenen","Warmtedeken","Noodflares (3ﾃ・"] },
        new() { Id=5, Name="Auto Noodpakket", Description="Altijd klaar voor pech onderweg. Past in iedere kofferbak en bevat alles voor noodsituaties op de weg.", Category="Auto", Price=39.95m, ImageEmoji="囓", IsFeatured=true, Includes=["Gevarendriehoek","EHBO-set","Jumpstartkabels","Zaklamp","Alu deken","Noodratio 24h","Veiligheidsvestje","Glasbreker + gordelsnijder"] },
        new() { Id=6, Name="72-Uurs Professioneel Pakket", Description="Het meest complete pakket voor maximale voorbereiding. Aanbevolen door het Rode Kruis.", Category="Premium", Price=199.95m, ImageEmoji="箝・, IsFeatured=true, Includes=["10L drinkwater","Noodrantsoenen (6 dagen)","Professionele EHBO-set","Handradio","Zonnepaneel oplader","Slaapzak","Tent (2 pers.)","Multi-tool","Medicijndoos","Hygiﾃｫneset","Waterfilter"] },
        new() { Id=7, Name="Pandemie Noodpakket", Description="Speciaal samengesteld voor infectieziekten en lockdown-scenario's. 2 weken basisvoorraad.", Category="Pandemie", Price=129.95m, ImageEmoji="亶", Includes=["FFP2-maskers (20ﾃ・","Handschoenen (50 paar)","Desinfectiemiddel (1L)","Noodrantsoenen (14 dagen)","Paracetamol & ibuprofen","Thermometer","Pulse-oximeter","EHBO-set"] },
        new() { Id=8, Name="Stroomuitval Pakket", Description="Alles voor als het licht uitvalt. Verlichting, communicatie en koude-bescherming voor 1 week.", Category="Stroom", Price=79.95m, ImageEmoji="幡", Includes=["Powerbank 20.000mAh","Solarcharger","Kaarsen (10ﾃ・ + lucifers","Camping gaslamp","Handradio","Warmtedeken","Noodrantsoenen (3 dagen)","Batterijen (AA/AAA set)"] },
    };

    public Product? GetById(int id) => Products.FirstOrDefault(p => p.Id == id);
    public IReadOnlyList<Product> GetFeatured() => Products.Where(p => p.IsFeatured).ToList();
    public IReadOnlyList<Product> GetByCategory(string category) =>
        Products.Where(p => p.Category.Equals(category, StringComparison.OrdinalIgnoreCase)).ToList();
    public IEnumerable<string> GetCategories() => Products.Select(p => p.Category).Distinct();
}
