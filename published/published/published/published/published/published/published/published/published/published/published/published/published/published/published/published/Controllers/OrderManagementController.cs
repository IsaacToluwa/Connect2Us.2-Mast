using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Mvc;
using Connect2Us.Models;
using Connect2Us.ViewModels;

namespace Connect2Us.Controllers
{
    [Authorize(Roles = "Admin")]
    public class OrderManagementController : Controller
    {
        private readonly ApplicationDbContext db = new ApplicationDbContext();

        // GET: Admin/Orders
        public ActionResult Orders()
        {
            var orders = db.Orders
                .Include(o => o.Customer.User)
                .Include(o => o.OrderItems)
                .OrderByDescending(o => o.OrderDate)
                .ToList();

            return View(orders);
        }

        // GET: Admin/OrderDetails/5
        public ActionResult OrderDetails(int? id)
        {
            if (!id.HasValue)
            {
                return RedirectToAction("Orders");
            }

            var order = db.Orders
                .Include(o => o.Customer.User)
                .Include(o => o.OrderItems.Select(i => i.Product))
                .FirstOrDefault(o => o.Id == id.Value);

            if (order == null)
            {
                return HttpNotFound();
            }

            // Get all available delivery drivers for assignment
            var deliveryDrivers = db.DeliveryDrivers
                .Include(d => d.User)
                .Where(d => d.IsAvailable)
                .ToList();

            // Check if order already has a delivery
            var existingDelivery = db.Deliveries
                .FirstOrDefault(d => d.OrderId == id);

            var viewModel = new OrderDetailsViewModel
            {
                Order = order,
                DeliveryDrivers = deliveryDrivers,
                ExistingDelivery = existingDelivery
            };

            return View(viewModel);
        }

        // POST: Admin/UpdateOrderStatus
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> UpdateOrderStatus(int orderId, string status)
        {
            var order = await db.Orders.FindAsync(orderId);
            if (order != null)
            {
                order.Status = status;
                await db.SaveChangesAsync();
                TempData["success"] = "Order status updated successfully.";
            }
            else
            {
                TempData["error"] = "Order not found.";
            }

            return RedirectToAction("OrderDetails", new { id = orderId });
        }
        
        // GET: Admin/MakeAllDriversAvailable (temporary action for testing)
        public ActionResult MakeAllDriversAvailable()
        {
            var drivers = db.DeliveryDrivers.ToList();
            System.IO.File.AppendAllText(Server.MapPath("~/App_Data/driver_update_log.txt"), 
                $"[{DateTime.Now}] MakeAllDriversAvailable called. Found {drivers.Count} drivers.\n");
            
            foreach (var driver in drivers)
            {
                driver.IsAvailable = true;
            }
            db.SaveChanges();
            
            System.IO.File.AppendAllText(Server.MapPath("~/App_Data/driver_update_log.txt"), 
                $"[{DateTime.Now}] Updated {drivers.Count} drivers to available.\n");
            
            TempData["success"] = $"Updated {drivers.Count} drivers to be available.";
            return RedirectToAction("Orders");
        }

        // POST: Admin/AssignDeliveryDriver
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> AssignDeliveryDriver(int orderId, string driverId)
        {
            var order = await db.Orders.FindAsync(orderId);
            if (order == null)
            {
                TempData["error"] = "Order not found.";
                return RedirectToAction("Orders");
            }

            // Check if delivery already exists for this order
            var existingDelivery = db.Deliveries.FirstOrDefault(d => d.OrderId == orderId);
            
            if (existingDelivery != null)
            {
                // Update existing delivery
                existingDelivery.DeliveryDriverId = driverId;
                existingDelivery.Status = "Assigned";
                existingDelivery.AssignedDate = DateTime.Now;
            }
            else
            {
                // Create new delivery
                var delivery = new Delivery
                {
                    OrderId = orderId,
                    DeliveryDriverId = driverId,
                    Status = "Assigned",
                    AssignedDate = DateTime.Now,
                    TrackingNumber = "TRK" + DateTime.Now.ToString("yyyyMMddHHmmss"),
                    DeliveryFee = 50.00m
                };
                
                db.Deliveries.Add(delivery);
            }
            
            // Update order status
            order.Status = "Processing";
            
            await db.SaveChangesAsync();
            
            // Create notification for driver
            var notification = new Notification
            {
                UserId = driverId,
                Title = "New Delivery Assignment",
                Message = "You have been assigned to deliver order #" + order.OrderNumber + ".",
                Type = "Delivery",
                IsRead = false,
                CreatedAt = DateTime.Now
            };
            db.Notifications.Add(notification);
            
            await db.SaveChangesAsync();
            
            TempData["success"] = "Delivery driver assigned successfully.";
            return RedirectToAction("OrderDetails", new { id = orderId });
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}