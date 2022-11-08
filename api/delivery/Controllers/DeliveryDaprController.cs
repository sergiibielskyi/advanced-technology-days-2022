/*using Dapr.Client;
using delivery.models;
using Microsoft.AspNetCore.Mvc;

namespace delivery.Controllers;

[ApiController]
[Route("api")]
public class DeliveryDaprController : ControllerBase
{
    private readonly ILogger<DeliveryDaprController> _logger;
    private DaprClient daprClient;
    string pubsub = "process-order";
    private const string storeName = "uploadblobapp";

    public DeliveryDaprController(ILogger<DeliveryDaprController> logger)
    {
        _logger = logger;
        daprClient = new DaprClientBuilder().Build();
    }

    [HttpGet]
    public IActionResult HealthCheck()
    {
        _logger.LogInformation("System is healthy with Dapr");
        return Ok();
    }

    [HttpPost]
    [Route("upload/{filename}")]
    public async Task UploadImage([FromBody] string file, string filename)
    {
        //Upload file
        var task = daprClient.SaveStateAsync(storeName, filename, file);
        task.Wait();
        if (task.IsCompletedSuccessfully)
        {
            _logger.LogInformation("File is uploaded - " + filename);

            //Using Dapr SDK to publish a message
            OrderModel order = new OrderModel()
            {
                id = Guid.NewGuid(),
                date = DateTime.Now.ToString(),
                invoiceId = Guid.NewGuid()
            };
            
            await daprClient.InvokeBindingAsync(pubsub, "create", order);
        }
    }
}*/
