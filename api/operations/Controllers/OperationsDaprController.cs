using Microsoft.AspNetCore.Mvc;
using Dapr.Client;

namespace operations.Controllers;

[ApiController]
public class OperationsDaprController : ControllerBase
{
    private readonly ILogger<OperationsDaprController> _logger;
    DaprClient daprClient;
     private readonly IConfiguration Configuration;


    public OperationsDaprController(ILogger<OperationsDaprController> logger, IConfiguration configuration)
    {
        _logger = logger;
        Configuration = configuration;
        daprClient = new DaprClientBuilder().Build();
        _logger.LogInformation("Store name is - " + Configuration["storeName"]);
    }

    [HttpPost("/checkout")]
    public void getCheckout([FromBody] object order)
    {
     
        _logger.LogInformation("Order is comming - " + order.ToString());

        daprClient.SaveStateAsync(Configuration["storeName"], Guid.NewGuid().ToString(), order);
    }

}
