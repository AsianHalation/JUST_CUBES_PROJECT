using CubiqAgent.Services;

var builder = WebApplication.CreateBuilder(args);

// ── Services ────────────────────────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddSingleton<CubeCatalogService>();
builder.Services.AddScoped<CubeAgentService>();

// CORS — allow the frontend (adjust origins in production)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader());
});

builder.Services.AddEndpointsApiExplorer();

// Bind OpenAI key from appsettings / env
builder.Services.Configure<OpenAiOptions>(
    builder.Configuration.GetSection("OpenAI"));

var app = builder.Build();

// ── Middleware ──────────────────────────────────────────────────────────────
app.UseCors("AllowFrontend");
app.UseDefaultFiles();           // serves wwwroot/index.html
app.UseStaticFiles();            // serves wwwroot/ (put frontend here)
app.UseAuthorization();
app.MapControllers();

app.Run();

// ── Options record ──────────────────────────────────────────────────────────
public class OpenAiOptions
{
    public string ApiKey { get; set; } = string.Empty;
    public string Model   { get; set; } = "gpt-4o-mini";
}
