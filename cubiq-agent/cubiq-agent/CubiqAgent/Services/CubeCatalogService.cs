using CubiqAgent.Models;

namespace CubiqAgent.Services;

/// <summary>
/// In-memory catalog of all 24 cube products.
/// Provides structured search methods used as OpenAI tool calls.
/// </summary>
public class CubeCatalogService
{
    private readonly List<CubeProduct> _products;

    // Material descriptions for the agent's context
    public static readonly Dictionary<string, string> MaterialDescriptions = new()
    {
        ["wood"]   = "Sustainably sourced American black walnut, hand-sanded to 2000-grit and finished with natural oil. Warm, organic, tactile.",
        ["metal"]  = "316L stainless steel, CNC machined to ±0.01mm tolerance, brushed to a matte satin finish. Industrial, precise, cool to the touch.",
        ["marble"] = "Hand-cut from Italian Carrara marble blocks, each piece unique with natural veining patterns. Luxurious, heavy, timeless.",
        ["glass"]  = "Borosilicate optical glass, kiln-cast and cold-worked to optical clarity with zero bubbles. Translucent, light-refracting, sculptural.",
        ["rubber"] = "Premium natural rubber, hot-vulcanized for exceptional durability and a tactile matte surface. Soft-touch, resilient, minimalist.",
        ["resin"]  = "UV-stable epoxy resin with embedded botanicals, minerals, or pigments — each cast is one of a kind. Colourful, unique, playful.",
    };

    public static readonly Dictionary<string, string> SizeDescriptions = new()
    {
        ["xs"] = "XS — 2×2×2 cm, 12 g. Pocket-sized, ideal as a desk fidget or keychain companion.",
        ["s"]  = "S  — 5×5×5 cm, 85 g. Palm-sized, the most popular desk object size.",
        ["m"]  = "M  — 10×10×10 cm, 680 g. Statement piece, sits prominently on a shelf or desk.",
        ["l"]  = "L  — 20×20×20 cm, 5.4 kg. Architectural object, floor or plinth display.",
    };

    public static readonly Dictionary<string, string> ColorDescriptions = new()
    {
        ["onyx"]    = "Onyx — deep matte black, dramatic and timeless.",
        ["ivory"]   = "Ivory — warm off-white, clean and minimal.",
        ["cobalt"]  = "Cobalt — vivid deep blue, bold and confident.",
        ["crimson"] = "Crimson — rich red, passionate and striking.",
        ["gold"]    = "Gold — warm metallic yellow, luxurious and warm.",
        ["sage"]    = "Sage — muted earthy green, calm and natural.",
        ["slate"]   = "Slate — cool grey-blue, understated and refined.",
        ["blush"]   = "Blush — soft coral-pink, gentle and approachable.",
    };

    public CubeCatalogService()
    {
        _products = BuildCatalog();
    }

    // ── Public search methods (used as tool implementations) ─────────────────

    /// <summary>Returns all products, optionally filtered.</summary>
    public List<CubeProduct> Search(
        string? material = null,
        string? color    = null,
        string? size     = null,
        decimal? maxPrice = null,
        decimal? minPrice = null)
    {
        return _products.Where(p =>
            (material  == null || p.Material.Equals(material, StringComparison.OrdinalIgnoreCase)) &&
            (color     == null || p.Color.Equals(color,       StringComparison.OrdinalIgnoreCase)) &&
            (size      == null || p.Size.Equals(size,         StringComparison.OrdinalIgnoreCase)) &&
            (maxPrice  == null || p.Price <= maxPrice) &&
            (minPrice  == null || p.Price >= minPrice)
        ).ToList();
    }

    public CubeProduct? GetById(int id)
        => _products.FirstOrDefault(p => p.Id == id);

    public List<CubeProduct> GetAll() => _products;

    public List<CubeProduct> GetByIds(IEnumerable<int> ids)
        => _products.Where(p => ids.Contains(p.Id)).ToList();

    // ── Catalog builder ───────────────────────────────────────────────────────

    private static List<CubeProduct> BuildCatalog()
    {
        // Base prices per size
        var basePrices = new Dictionary<string, decimal>
        {
            ["xs"] = 29m, ["s"] = 59m, ["m"] = 129m, ["l"] = 289m
        };
        // Multipliers per material
        var multipliers = new Dictionary<string, decimal>
        {
            ["wood"] = 1.2m, ["metal"] = 1.8m, ["marble"] = 2.2m,
            ["glass"] = 2.6m, ["rubber"] = 0.9m, ["resin"] = 1.5m
        };
        var dimensions = new Dictionary<string, string>
        {
            ["xs"] = "2×2×2 cm", ["s"] = "5×5×5 cm",
            ["m"] = "10×10×10 cm", ["l"] = "20×20×20 cm"
        };
        var weights = new Dictionary<string, string>
        {
            ["xs"] = "12g", ["s"] = "85g", ["m"] = "680g", ["l"] = "5.4 kg"
        };

        var materialLabels = new Dictionary<string, string>
        {
            ["wood"] = "Walnut Wood", ["metal"] = "Brushed Steel",
            ["marble"] = "Carrara Marble", ["glass"] = "Optical Glass",
            ["rubber"] = "Vulcanized Rubber", ["resin"] = "Cast Resin"
        };
        var colorLabels = new Dictionary<string, string>
        {
            ["onyx"] = "Onyx", ["ivory"] = "Ivory", ["cobalt"] = "Cobalt",
            ["crimson"] = "Crimson", ["gold"] = "Gold", ["sage"] = "Sage",
            ["slate"] = "Slate", ["blush"] = "Blush"
        };

        // Same 24 combos as the frontend JS
        var combos = new (string m, string c, string s)[]
        {
            ("wood","onyx","m"),  ("wood","ivory","s"),  ("wood","sage","l"),   ("wood","cobalt","xs"),
            ("metal","slate","m"), ("metal","onyx","l"),  ("metal","cobalt","s"),("metal","ivory","xs"),
            ("marble","ivory","l"),("marble","crimson","m"),("marble","slate","s"),("marble","gold","xs"),
            ("glass","cobalt","m"),("glass","blush","s"), ("glass","sage","l"),  ("glass","ivory","xs"),
            ("rubber","onyx","m"),("rubber","crimson","s"),("rubber","cobalt","l"),("rubber","gold","xs"),
            ("resin","gold","m"), ("resin","blush","s"), ("resin","sage","l"),  ("resin","crimson","xs"),
        };

        var products = new List<CubeProduct>();
        for (int i = 0; i < combos.Length; i++)
        {
            var (m, c, s) = combos[i];
            var price = Math.Round(basePrices[s] * multipliers[m]);
            products.Add(new CubeProduct(
                Id:         i + 1,
                Material:   m,
                Color:      c,
                Size:       s,
                Name:       $"{colorLabels[c]} {materialLabels[m]}",
                Price:      price,
                Dimensions: dimensions[s],
                Weight:     weights[s]
            ));
        }
        return products;
    }
}
