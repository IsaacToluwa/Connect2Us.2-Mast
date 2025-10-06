using Connect2Us.Models;
using System.Collections.Generic;

namespace Connect2Us.Controllers
{
    public class BookstoreDashboardViewModel
    {
        public Bookstore Bookstore { get; set; }
        public int TotalProducts { get; set; }
        public int TotalOrders { get; set; }
        public int PendingOrders { get; set; }
        public decimal TotalRevenue { get; set; }
        public List<Order> RecentOrders { get; set; }
        public decimal WalletBalance { get; set; }
    }
}