# CUBIQ — AI Cube Agent

An ASP.NET Core 8 backend that powers an OpenAI tool-calling agent to help
customers find their perfect cube. The frontend shop is served statically from
`wwwroot/`.

---

## Quick Start

### 1. Prerequisites
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- An OpenAI API key (GPT-4o-mini is used by default)

### 2. Set your API key

Open `appsettings.json` and replace the placeholder:

```json
{
  "OpenAI": {
    "ApiKey": "sk-YOUR_KEY_HERE",
    "Model": "gpt-4o-mini"
  }
}
```

Or use an environment variable (recommended for production):

```bash
export OpenAI__ApiKey="sk-YOUR_KEY_HERE"
```

### 3. Run

```bash
cd CubiqAgent
dotnet restore
dotnet run
```

The app starts on `http://localhost:5000` (or the port shown in the console).
Open that URL in your browser — the shop + AI agent loads automatically.

---

## Architecture

```
CubiqAgent/
├── Program.cs                  # Minimal API host, DI setup, CORS
├── appsettings.json            # Config (API key, model)
├── Controllers/
│   └── AgentController.cs      # POST /api/agent/chat
│                               # GET  /api/agent/catalog
├── Models/
│   └── ChatModels.cs           # Request/Response/Product records
├── Services/
│   ├── CubeCatalogService.cs   # In-memory product catalog + search
│   └── CubeAgentService.cs     # OpenAI tool-calling agentic loop
└── wwwroot/                    # Static frontend (served by ASP.NET)
    ├── index.html
    ├── style.css
    ├── script.js               # Shop logic (filters, cart, 3D cubes)
    ├── agent.css               # Chat widget styles
    └── agent.js                # Chat widget JS, calls /api/agent/chat
```

---

## API Reference

### POST `/api/agent/chat`

Send the full conversation history; receive the AI reply and optional
product recommendations.

**Request body:**
```json
{
  "messages": [
    { "role": "user", "content": "I want a minimalist desk object under €100" }
  ]
}
```

**Response:**
```json
{
  "reply": "For a minimalist desk piece under €100 I'd recommend the Ivory Walnut Wood cube in size S — warm, tactile and beautifully simple.",
  "recommendations": [
    {
      "id": 2,
      "name": "Ivory Walnut Wood",
      "material": "wood",
      "color": "ivory",
      "size": "s",
      "price": 71,
      "reason": "Warm walnut with a clean ivory finish — perfect minimalist desk companion"
    }
  ]
}
```

For multi-turn conversation, keep appending messages:
```json
{
  "messages": [
    { "role": "user",      "content": "I want something under €100" },
    { "role": "assistant", "content": "..." },
    { "role": "user",      "content": "I prefer glass actually" }
  ]
}
```

### GET `/api/agent/catalog`

Returns all 24 products as JSON — useful for debugging or building
a custom frontend.

---

## AI Tools

The agent has 5 tools it can invoke automatically:

| Tool | Description |
|------|-------------|
| `search_cubes` | Filter catalog by material, color, size, min/max price |
| `get_cube_details` | Get full details for a product ID |
| `list_materials` | Descriptions of all 6 materials |
| `list_sizes` | Descriptions of all 4 sizes |
| `list_colors` | Descriptions of all 8 color options |

The loop runs up to 6 iterations to allow chaining tool calls before
returning the final answer.

---

## Frontend Integration

The chat widget (`agent.js`) is a drop-in that works alongside the existing
shop. It:

- Shows a floating **CUBE AGENT** button
- Maintains conversation history client-side
- Displays typing indicator while the backend calls OpenAI
- Renders recommendation cards in a modal overlay when the agent finds matches
- Bridges into the existing `addToCart()` function so customers can add
  recommended cubes directly

To use the frontend **standalone** against a remote backend, change
`AGENT_API` at the top of `agent.js`:

```js
const AGENT_API = 'https://your-backend.com/api/agent/chat';
```

---

## Production Notes

- Store the API key in an environment variable or secrets manager, not `appsettings.json`
- Add rate limiting (`Microsoft.AspNetCore.RateLimiting`) to protect the `/api/agent/chat` endpoint
- Consider persisting conversation sessions server-side if you need analytics
- The `AllowAnyOrigin` CORS policy is intentionally permissive for development; restrict it in production
