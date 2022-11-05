namespace delivery.models;
public class OrderModel
{
    public Guid id { get; set; }
    public string date { get; set; }
    public Guid invoiceId { get; set; }
}