using Connect2Us.Models;
using System.Collections.Generic;

namespace Connect2Us.ViewModels
{
    public class OrderDetailsViewModel
    {
        public Order Order { get; set; }
        public IEnumerable<DeliveryDriver> DeliveryDrivers { get; set; }
        public Delivery ExistingDelivery { get; set; }
    }
}