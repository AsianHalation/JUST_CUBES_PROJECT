using CubiqAgent.Models;
using CubiqAgent.Services;
using Microsoft.AspNetCore.Mvc;

namespace CubiqAgent.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AgentController(CubeAgentService agent, ILogger<AgentController> logger) : ControllerBase
{
    /// <summary>
    /// POST /api/agent/chat
    /// Body: { messages: [{role, content}] }
    /// Returns: { reply, recommendations? }
    /// </summary>
    [HttpPost("chat")]
    public async Task<IActionResult> Chat([FromBody] ChatRequest request)
    {
        if (request.Messages == null || request.Messages.Count == 0)
            return BadRequest(new { error = "messages array is required" });

        try
        {
            var response = await agent.ChatAsync(request.Messages);
            return Ok(response);
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("OpenAI API error"))
        {
            logger.LogError(ex, "OpenAI API error");
            return StatusCode(502, new { error = "AI service error. Check your API key in appsettings.json." });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unexpected error in chat");
            return StatusCode(500, new { error = "Internal server error" });
        }
    }

    /// <summary>
    /// GET /api/agent/catalog
    /// Returns all products — useful for the frontend to verify IDs match.
    /// </summary>
    [HttpGet("catalog")]
    public IActionResult Catalog([FromServices] CubeCatalogService catalog)
        => Ok(catalog.GetAll());
}
