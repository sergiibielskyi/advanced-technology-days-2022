using Azure.Storage.Blobs;
using Azure.Storage.Queues;
using delivery.models;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;

namespace delivery.Controllers;

[ApiController]
[Route("api")]
public class DeliveryController : ControllerBase
{
    private readonly ILogger<DeliveryController> _logger;
    private readonly IConfiguration _config;
    private readonly string containerName = "advtechcontainerblob";
    private readonly string queueName = "orders";

    public DeliveryController(ILogger<DeliveryController> logger, IConfiguration config)
    {
        _logger = logger;
        _config = config;
    }

    [HttpGet]
    public IActionResult HealthCheck()
    {
        _logger.LogInformation("System is healthy");
        return Ok();
    }

    [HttpPost]
    [Route("upload/{filename}")]
    public async Task UploadImage([FromBody] string file, string filename)
    {
        BlobServiceClient blobServiceClient = new BlobServiceClient(_config["AzureBlobStorage:ConnectionString"]);
        BlobContainerClient containerClient = blobServiceClient.GetBlobContainerClient(containerName);
        BlobClient blobClient = containerClient.GetBlobClient(filename);
        var decodedImage = Convert.FromBase64String(file);
        using (var fileStream = new MemoryStream(decodedImage))
        {
            // upload image stream to blob
            var task = blobClient.UploadAsync(fileStream, true);
            task.Wait();

            if (task.IsCompletedSuccessfully)
            {
                QueueClient queueClient = new QueueClient(_config["AzureBlobStorage:ConnectionString"], queueName);
                OrderModel order = new OrderModel()
                {
                    id = Guid.NewGuid(),
                    date = DateTime.Now.ToString(),
                    invoiceId = Guid.NewGuid()
                };

                var plainTextBytes = System.Text.Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(order));
                queueClient.SendMessage(System.Convert.ToBase64String(plainTextBytes));
            }
        }
    }
}
