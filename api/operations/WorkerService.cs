using System.Text;
using Azure.Storage.Queues;
using Azure.Storage.Queues.Models;
using Microsoft.Azure.Cosmos;
using Newtonsoft.Json;

namespace operations;

public class WorkerService : BackgroundService
{
    private readonly ILogger<WorkerService> _logger;
    private const int generalDelay = 1 * 5 * 1000; // 5 seconds
    private readonly string queueName = "orders";
    private readonly string dbName = "advtechDB";
    private readonly string containerId = "advtechContainer";
    private readonly IConfiguration _config;
    CosmosClient clientDB;

    public WorkerService (ILogger<WorkerService> logger, IConfiguration config)
    {
        _logger = logger;
        _config = config;
        clientDB = new(
            accountEndpoint: _config["CosmosDB:Endpoint"]!,
            authKeyOrResourceToken: _config["CosmosDB:Token"]!
        );
    }
        
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(generalDelay, stoppingToken);
            await CheckNewInvocesAsync();
        }
    }

    public Task CheckNewInvocesAsync()
    {
        _logger.LogInformation("Executing background task");
        
        // Instantiate a QueueClient which will be used to manipulate the queue
        QueueClient queueClient = new QueueClient(_config["AzureBlobStorage:ConnectionString"], queueName);

        if (queueClient.Exists())
        { 
            // Receive at the next message
            QueueMessage[] retrievedMessage = queueClient.ReceiveMessages();

            if (retrievedMessage.Count() != 0)
            {
                var base64EncodedBytes = System.Convert.FromBase64String(Encoding.UTF8.GetString(retrievedMessage[0].Body));
                string invoce = System.Text.Encoding.UTF8.GetString(base64EncodedBytes);
                var order = JsonConvert.DeserializeObject<dynamic>(invoce);

                // Display the message
                _logger.LogInformation($"Order message: '{order}'");

                //Create new order
                Container container = clientDB.GetContainer(dbName, containerId);
                var createdItem = container.CreateItemAsync<dynamic>(
                    item: order
                ).Result;

                // Delete the message
                queueClient.DeleteMessage(retrievedMessage[0].MessageId, retrievedMessage[0].PopReceipt);
  
            }
            else
                _logger.LogInformation("No new invoces");
            
        }

        return Task.FromResult("Done");
    }
}
