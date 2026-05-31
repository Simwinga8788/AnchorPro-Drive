using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace CarRental.Api.Services;

public class LencoService
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;

    public LencoService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _apiKey = configuration["Lenco:ApiKey"] ?? "TEST_KEY";
        _httpClient.BaseAddress = new Uri(configuration["Lenco:BaseUrl"] ?? "https://api.lenco.co/");
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);
    }

    public async Task<string?> InitiateMobileMoneyCollectionAsync(string phoneNumber, decimal amount, string provider, string reference)
    {
        var payload = new
        {
            amount = amount,
            mobileNumber = phoneNumber,
            mobileMoneyProvider = provider, // "mtn", "airtel", "zamtel"
            reference = reference,
        };

        var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

        if (_apiKey == "TEST_KEY")
        {
            Console.WriteLine($"[MOCK] Lenco Mobile Money payment initiated for {amount} {provider} to {phoneNumber}. Ref: {reference}");
            // Simulate a delay
            await Task.Delay(1000);
            return reference;
        }

        try
        {
            var response = await _httpClient.PostAsync("access/v2/collections/mobile-money", content);
            
            if (response.IsSuccessStatusCode)
            {
                var responseString = await response.Content.ReadAsStringAsync();
                var jsonDocument = JsonDocument.Parse(responseString);
                // Extract Lenco's internal transaction reference if needed, 
                // but usually the client reference we provided is sufficient for the webhook.
                return reference;
            }
            
            var error = await response.Content.ReadAsStringAsync();
            Console.WriteLine($"Lenco API Error: {error}");
            return null;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Lenco Exception: {ex.Message}");
            return null;
        }
    }
}
