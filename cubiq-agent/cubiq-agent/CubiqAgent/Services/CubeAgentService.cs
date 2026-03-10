using System.Text;
using System.Text.Json;
using CubiqAgent.Models;
using Microsoft.Extensions.Options;

namespace CubiqAgent.Services;

/// <summary>
/// Orchestrates the OpenAI chat-completions loop with tool calling.
/// Tools exposed to the model:
///   - search_cubes        : filter by material / color / size / price
///   - get_cube_details    : fetch a single product by ID
///   - list_materials      : explain available materials
///   - list_sizes          : explain available sizes
///   - list_colors         : explain available colors
/// </summary>
public class CubeAgentService(
    IOptions<OpenAiOptions> options,
    CubeCatalogService catalog,
    ILogger<CubeAgentService> logger)
{
    private readonly string _apiKey = options.Value.ApiKey;
    private readonly string _model  = options.Value.Model;

    private static readonly string SystemPrompt = """
        You are CUBIQ, an expert sales assistant for a premium geometric cube shop.
        Help customers find their perfect cube through friendly conversation.

        You have tools to search the catalog. ALWAYS use search_cubes before recommending.

        Guidelines:
        - Ask about use case, aesthetic preference, budget, and preferred size
        - Keep replies short and friendly (2-3 sentences)
        - After searching, recommend 1-3 specific products by ID

        IMPORTANT: When you have recommendations, you MUST format them like this at the end of your reply.
        Use exactly this format, no variations:

        RECOMMENDATIONS:
        [{"id": 1, "reason": "Great for minimalist desks"}, {"id": 5, "reason": "Bold and industrial"}]

        Do not put the RECOMMENDATIONS block inside code fences or backticks.
        Always put RECOMMENDATIONS: on its own line followed by the JSON array on the next line.
        """;

    // ── Tool definitions (JSON schema for OpenAI) ─────────────────────────────

    private static readonly object[] Tools = [
        new {
            type = "function",
            function = new {
                name = "search_cubes",
                description = "Search the cube catalog with optional filters. Returns matching products.",
                parameters = new {
                    type = "object",
                    properties = new {
                        material  = new { type = "string", description = "Filter by material: wood, metal, marble, glass, rubber, resin" },
                        color     = new { type = "string", description = "Filter by color: onyx, ivory, cobalt, crimson, gold, sage, slate, blush" },
                        size      = new { type = "string", description = "Filter by size: xs, s, m, l" },
                        max_price = new { type = "number", description = "Maximum price in EUR" },
                        min_price = new { type = "number", description = "Minimum price in EUR" }
                    },
                    required = Array.Empty<string>()
                }
            }
        },
        new {
            type = "function",
            function = new {
                name = "get_cube_details",
                description = "Get full details for a specific cube product by its ID.",
                parameters = new {
                    type = "object",
                    properties = new {
                        id = new { type = "integer", description = "The product ID" }
                    },
                    required = new[] { "id" }
                }
            }
        },
        new {
            type = "function",
            function = new {
                name = "list_materials",
                description = "Get descriptions of all available cube materials to help explain options to a customer.",
                parameters = new { type = "object", properties = new { }, required = Array.Empty<string>() }
            }
        },
        new {
            type = "function",
            function = new {
                name = "list_sizes",
                description = "Get descriptions of all available cube sizes.",
                parameters = new { type = "object", properties = new { }, required = Array.Empty<string>() }
            }
        },
        new {
            type = "function",
            function = new {
                name = "list_colors",
                description = "Get descriptions of all available cube colors.",
                parameters = new { type = "object", properties = new { }, required = Array.Empty<string>() }
            }
        }
    ];

    // ── Main chat method ──────────────────────────────────────────────────────

    public async Task<ChatResponse> ChatAsync(List<ChatMessage> history)
    {
        // Build message list for OpenAI
        var messages = new List<object>
        {
            new { role = "system", content = SystemPrompt }
        };
        foreach (var m in history)
            messages.Add(new { role = m.Role, content = m.Content });

        // Agentic loop: keep calling until model stops using tools
        const int maxIterations = 6;
        for (int iter = 0; iter < maxIterations; iter++)
        {
            var requestBody = new
            {
                model       = _model,
                messages    = messages,
                tools       = Tools,
                tool_choice = "auto",
                max_tokens  = 600
            };

            var json     = JsonSerializer.Serialize(requestBody);
            var response = await CallOpenAiAsync(json);
            var choice   = response.GetProperty("choices")[0];
            var message  = choice.GetProperty("message");
            var finishReason = choice.GetProperty("finish_reason").GetString();

            // Add assistant message to context
            messages.Add(JsonSerializer.Deserialize<object>(message.GetRawText())!);

            // No more tool calls — we have the final answer
            if (finishReason != "tool_calls")
            {
                var content = message.TryGetProperty("content", out var cv)
                    ? cv.GetString() ?? ""
                    : "";

                return ParseFinalResponse(content);
            }

            // Handle tool calls
            if (!message.TryGetProperty("tool_calls", out var toolCalls)) break;

            foreach (var toolCall in toolCalls.EnumerateArray())
            {
                var callId   = toolCall.GetProperty("id").GetString()!;
                var funcName = toolCall.GetProperty("function").GetProperty("name").GetString()!;
                var argsRaw  = toolCall.GetProperty("function").GetProperty("arguments").GetString()!;
                var args     = JsonSerializer.Deserialize<JsonElement>(argsRaw);

                var toolResult = ExecuteTool(funcName, args);
                logger.LogInformation("Tool {Tool} called, result length: {Len}", funcName, toolResult.Length);

                messages.Add(new
                {
                    role         = "tool",
                    tool_call_id = callId,
                    content      = toolResult
                });
            }
        }

        return new ChatResponse("I'm having trouble finding the right cube right now. Could you try again?");
    }

    // ── Tool executor ─────────────────────────────────────────────────────────

    private string ExecuteTool(string name, JsonElement args)
    {
        return name switch
        {
            "search_cubes" => ExecuteSearchCubes(args),
            "get_cube_details" => ExecuteGetCubeDetails(args),
            "list_materials" => JsonSerializer.Serialize(CubeCatalogService.MaterialDescriptions),
            "list_sizes"    => JsonSerializer.Serialize(CubeCatalogService.SizeDescriptions),
            "list_colors"   => JsonSerializer.Serialize(CubeCatalogService.ColorDescriptions),
            _ => """{"error": "Unknown tool"}"""
        };
    }

    private string ExecuteSearchCubes(JsonElement args)
    {
        string? GetStr(string key) =>
            args.TryGetProperty(key, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString() : null;
        decimal? GetNum(string key) =>
            args.TryGetProperty(key, out var v) && v.ValueKind == JsonValueKind.Number ? (decimal?)v.GetDecimal() : null;

        var results = catalog.Search(
            material:  GetStr("material"),
            color:     GetStr("color"),
            size:      GetStr("size"),
            maxPrice:  GetNum("max_price"),
            minPrice:  GetNum("min_price")
        );

        if (results.Count == 0)
            return """{"results": [], "message": "No cubes match these filters. Try relaxing some criteria."}""";

        // Return condensed result list
        var summary = results.Select(p => new
        {
            p.Id, p.Name, p.Material, p.Color, p.Size,
            p.Dimensions, p.Weight, price = $"€{p.Price}"
        });
        return JsonSerializer.Serialize(new { count = results.Count, results = summary });
    }

    private string ExecuteGetCubeDetails(JsonElement args)
    {
        if (!args.TryGetProperty("id", out var idEl)) return """{"error": "id required"}""";
        var product = catalog.GetById(idEl.GetInt32());
        if (product == null) return """{"error": "Product not found"}""";
        return JsonSerializer.Serialize(new
        {
            product.Id, product.Name, product.Material, product.Color,
            product.Size, product.Dimensions, product.Weight,
            price = $"€{product.Price}",
            materialDetail = CubeCatalogService.MaterialDescriptions.GetValueOrDefault(product.Material),
            sizeDetail     = CubeCatalogService.SizeDescriptions.GetValueOrDefault(product.Size),
            colorDetail    = CubeCatalogService.ColorDescriptions.GetValueOrDefault(product.Color),
        });
    }

    // ── Parse final reply, extract recommendations in any format ────────────────

    private ChatResponse ParseFinalResponse(string content)
    {
        if (string.IsNullOrWhiteSpace(content))
            return new ChatResponse("I couldn't find anything. Could you try rephrasing?");

        // Try each format the model might use
        var (replyText, jsonBlock) = TryExtractRecommendations(content);

        if (string.IsNullOrEmpty(jsonBlock))
            return new ChatResponse(content.Trim());

        try
        {
            var opts = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var recs = JsonSerializer.Deserialize<List<RecommendationRaw>>(jsonBlock, opts)!;
            var recommendations = recs
                .Select(r =>
                {
                    var p = catalog.GetById(r.Id);
                    return p == null ? null : new CubeRecommendation(
                        p.Id, p.Name, p.Material, p.Color, p.Size, p.Price,
                        r.Reason ?? r.reason ?? "A great match for you");
                })
                .Where(r => r != null)
                .Cast<CubeRecommendation>()
                .ToList();

            if (recommendations.Count == 0)
                return new ChatResponse(replyText.Trim());

            return new ChatResponse(replyText.Trim(), recommendations);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Could not parse recommendations JSON: {Json}", jsonBlock);
            // Return reply without the JSON noise
            return new ChatResponse(replyText.Trim());
        }
    }

    private static (string reply, string json) TryExtractRecommendations(string content)
    {
        // Format 1: "RECOMMENDATIONS:\n[...]"
        var idx = content.IndexOf("RECOMMENDATIONS:", StringComparison.OrdinalIgnoreCase);
        if (idx >= 0)
        {
            var reply    = content[..idx].Trim();
            var after    = content[(idx + "RECOMMENDATIONS:".Length)..].Trim();
            var jsonPart = ExtractJsonArray(after);
            if (jsonPart != null)
            {
                // If reply is empty the model skipped prose — use text after JSON as fallback, or a default
                if (string.IsNullOrWhiteSpace(reply))
                    reply = "Here are my top picks for you:";
                return (reply, jsonPart);
            }
        }

        // Format 2: ```recommendations ... ```
        const string fence = "```recommendations";
        var fenceIdx = content.IndexOf(fence, StringComparison.OrdinalIgnoreCase);
        if (fenceIdx >= 0)
        {
            var reply    = content[..fenceIdx].Trim();
            var afterTag = content[(fenceIdx + fence.Length)..];
            var end      = afterTag.IndexOf("```", StringComparison.Ordinal);
            if (end >= 0)
            {
                var jsonPart = ExtractJsonArray(afterTag[..end]);
                if (jsonPart != null)
                {
                    if (string.IsNullOrWhiteSpace(reply)) reply = "Here are my top picks for you:";
                    return (reply, jsonPart);
                }
            }
        }

        // Format 3: ```json ... ```
        const string jsonFence = "```json";
        var jfIdx = content.IndexOf(jsonFence, StringComparison.OrdinalIgnoreCase);
        if (jfIdx >= 0)
        {
            var reply    = content[..jfIdx].Trim();
            var afterTag = content[(jfIdx + jsonFence.Length)..];
            var end      = afterTag.IndexOf("```", StringComparison.Ordinal);
            if (end >= 0)
            {
                var jsonPart = ExtractJsonArray(afterTag[..end]);
                if (jsonPart != null)
                {
                    if (string.IsNullOrWhiteSpace(reply)) reply = "Here are my top picks for you:";
                    return (reply, jsonPart);
                }
            }
        }

        // Format 4: bare JSON array [...] — only if it looks like a recommendations array
        // Use FIRST occurrence of [ so we don't lose the prose before it
        var arrStart = content.IndexOf('[');
        var arrEnd   = content.LastIndexOf(']');
        if (arrStart >= 0 && arrEnd > arrStart)
        {
            var candidate = content[arrStart..(arrEnd + 1)];
            if (candidate.Contains("\"id\"", StringComparison.OrdinalIgnoreCase) &&
                candidate.Contains("\"reason\"", StringComparison.OrdinalIgnoreCase))
            {
                var reply = content[..arrStart].Trim();
                if (string.IsNullOrWhiteSpace(reply)) reply = "Here are my top picks for you:";
                return (reply, candidate);
            }
        }

        return (content, string.Empty);
    }

    private static string? ExtractJsonArray(string text)
    {
        text = text.Trim();
        var start = text.IndexOf('[');
        var end   = text.LastIndexOf(']');
        if (start >= 0 && end > start)
            return text[start..(end + 1)];
        return null;
    }

    private record RecommendationRaw(
        int Id, 
        string? Reason,
        // also accept lowercase variants Llama might emit
        [property: System.Text.Json.Serialization.JsonPropertyName("reason")]
        string? reason = null
    );

    // ── HTTP call to OpenAI ───────────────────────────────────────────────────

    private async Task<JsonElement> CallOpenAiAsync(string jsonBody)
    {
        using var http = new HttpClient();
        http.Timeout = TimeSpan.FromSeconds(30);
        http.DefaultRequestHeaders.Add("Authorization", $"Bearer {_apiKey}");
        var request = new StringContent(jsonBody, Encoding.UTF8, "application/json");
        var response = await http.PostAsync("https://api.groq.com/openai/v1/chat/completions", request);

        var raw = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
        {
            logger.LogError("Groq API error {Status}: {Body}", response.StatusCode, raw);
            throw new InvalidOperationException($"Groq API error {response.StatusCode}: {raw}");
        }
        return JsonSerializer.Deserialize<JsonElement>(raw);
    }
}
