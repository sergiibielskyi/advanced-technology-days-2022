using Microsoft.AspNetCore.Mvc;
using Dapr.Client;

namespace operations.Controllers;

[ApiController]
public class OperationsDaprController : ControllerBase
{
    private readonly ILogger<OperationsDaprController> _logger;
    DaprClient daprClient;
    string storeName = "postgresqlapp";

    public OperationsDaprController(ILogger<OperationsDaprController> logger)
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
