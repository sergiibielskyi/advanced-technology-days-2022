using Microsoft.AspNetCore.Mvc;
using Dapr.Client;

namespace operations.Controllers;

[ApiController]
public class OperationsController : ControllerBase
{
    private readonly ILogger<OperationsController> _logger;
    DaprClient daprClient;
    string storeName = "cosmosdbapp";

    public OperationsController(ILogger<OperationsController> logger)
    {
        _logger = logger;
        daprClient = new DaprClientBuilder().Build();
    }

    [HttpPost("/checkout")]
    public void getCheckout([FromBody] object order)
    {
        _logger.LogInformation("Order is comming - " + order.ToString());

        daprClient.SaveStateAsync(storeName, Guid.NewGuid().ToString(), order);
    }

}
