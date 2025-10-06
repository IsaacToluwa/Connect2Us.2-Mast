using Connect2Us.Models;
using System.Collections.Generic;

namespace Connect2Us.ViewModels
{
    public class DeliveryDriverDashboardViewModel
    {
        public DeliveryDriver Driver { get; set; }
        public int TotalDeliveries { get; set; }
        public int CompletedDeliveries { get; set; }
        public int PendingDeliveries { get; set; }
        public int AvailableDeliveries { get; set; }
        public IEnumerable<Delivery> RecentDeliveries { get; set; }
        public decimal WalletBalance { get; set; }
    }
}