using Microsoft.AspNetCore.Mvc;

namespace operations.Controllers;

[ApiController]
public class OperationsController : ControllerBase
{
    private readonly ILogger<OperationsController> _logger;
    
    public OperationsController(ILogger<OperationsController> logger)
    {
        _logger = logger;
    }
}
