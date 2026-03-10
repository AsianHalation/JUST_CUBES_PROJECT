namespace CubiqAgent.Models;

// ── Request / Response ────────────────────────────────────────────────────

public record ChatRequest(
    List<ChatMessage> Messages,
    string? SessionId = null
);

public record ChatMessage(
    string Role,       // "user" | "assistant"
    string Content
);

public record ChatResponse(
    string Reply,
    List<CubeRecommendation>? Recommendations = null
);

public record CubeRecommendation(
    int     Id,
    string  Name,
    string  Material,
    string  Color,
    string  Size,
    decimal Price,
    string  Reason
);

// ── Cube domain models ────────────────────────────────────────────────────

public record CubeProduct(
    int     Id,
    string  Material,   // wood | metal | marble | glass | rubber | resin
    string  Color,      // onyx | ivory | cobalt | crimson | gold | sage | slate | blush
    string  Size,       // xs | s | m | l
    string  Name,
    decimal Price,
    string  Dimensions, // e.g. "5×5×5 cm"
    string  Weight
);

public enum CubeMaterial { Wood, Metal, Marble, Glass, Rubber, Resin }
public enum CubeColor    { Onyx, Ivory, Cobalt, Crimson, Gold, Sage, Slate, Blush }
public enum CubeSize     { XS, S, M, L }
