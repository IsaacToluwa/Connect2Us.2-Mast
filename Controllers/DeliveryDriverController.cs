using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using Connect2Us.Models;
using Connect2Us.ViewModels;
using Microsoft.AspNet.Identity;

namespace Connect2Us.Controllers
{
    [Authorize(Roles = "DeliveryDriver")]
    public class DeliveryDriverController : Controller
    {
        private ApplicationDbContext db = new ApplicationDbContext();

        // GET: DeliveryDriver
        public ActionResult Index()
        {
            var userId = User.Identity.GetUserId();
            var driver = db.DeliveryDrivers.Include(d => d.User).FirstOrDefault(d => d.UserId == userId);

            if (driver == null)
            {
                return HttpNotFound();
            }

            var deliveries = db.Deliveries
                .Where(d => d.DeliveryDriverId == userId)
                .ToList();

            var wallet = db.Wallets.FirstOrDefault(w => w.UserId == userId);

            var viewModel = new DeliveryDriverDashboardViewModel
            {
                Driver = driver,
                TotalDeliveries = deliveries.Count(),
                CompletedDeliveries = deliveries.Count(d => d.Status == "Delivered"),
                PendingDeliveries = deliveries.Count(d => d.Status == "Assigned" || d.Status == "Picked Up" || d.Status == "In Transit"),
                AvailableDeliveries = db.Deliveries.Count(d => d.Status == "Available"),
                RecentDeliveries = deliveries.OrderByDescending(d => d.AssignedDate).Take(5).ToList(),
                WalletBalance = wallet?.Balance ?? 0
            };

            return View(viewModel);
        }

        // GET: DeliveryDriver/AvailableDeliveries
        public ActionResult AvailableDeliveries()
        {
            var availableDeliveries = db.Deliveries
                .Include(d => d.Order.Customer.User)
                .Include(d => d.Order.Bookstore)
                .Where(d => d.Status == "Available")
                .OrderBy(d => d.AssignedDate)
                .ToList();

            return View(availableDeliveries);
        }

        // POST: DeliveryDriver/AcceptDelivery
        [HttpPost]
        public async Task<ActionResult> AcceptDelivery(int deliveryId)
        {
            var userId = User.Identity.GetUserId();
            var driver = db.DeliveryDrivers.FirstOrDefault(d => d.UserId == userId);
            
            if (driver == null)
            {
                return Json(new { success = false, message = "Driver not found." });
            }

            var delivery = db.Deliveries.FirstOrDefault(d => d.Id == deliveryId && d.Status == "Available");
            if (delivery == null)
            {
                return Json(new { success = false, message = "Delivery not found or already assigned." });
            }

            try
            {
                delivery.DeliveryDriverId = driver.UserId;
                delivery.Status = "Assigned";
                delivery.AssignedDate = DateTime.Now;

                await db.SaveChangesAsync();

                // Create notification for customer
                var notification = new Notification
                {
                    UserId = delivery.Order.Customer.UserId,
                    Title = "Delivery Assigned",
                    Message = "Your order #" + delivery.Order.OrderNumber + " has been assigned to a delivery driver.",
                    Type = "Delivery",
                    IsRead = false,
                    CreatedAt = DateTime.Now
                };
                db.Notifications.Add(notification);
                await db.SaveChangesAsync();

                return Json(new { success = true, message = "Delivery accepted successfully!" });
            }
            catch (Exception)
            {
                return Json(new { success = false, message = "Error accepting delivery." });
            }
        }

        // GET: DeliveryDriver/MyDeliveries
        public ActionResult MyDeliveries()
        {
            var userId = User.Identity.GetUserId();
            var deliveries = db.Deliveries
                .Include(d => d.Order.Customer.User)
                .Include(d => d.Order.Bookstore)
                .Where(d => d.DeliveryDriverId == userId)
                .OrderByDescending(d => d.AssignedDate)
                .ToList();

            return View(deliveries);
        }

        // GET: DeliveryDriver/DeliveryDetails/5
        public ActionResult DeliveryDetails(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            }

            var delivery = db.Deliveries
                .Include(d => d.Order.Customer.User)
                .Include(d => d.Order.Bookstore)
                .Include(d => d.Order.OrderItems.Select(oi => oi.Product))
                .FirstOrDefault(d => d.Id == id);

            if (delivery == null)
            {
                return HttpNotFound();
            }

            return View(delivery);
        }

        // POST: DeliveryDriver/UpdateDeliveryStatus
        [HttpPost]
        public async Task<ActionResult> UpdateDeliveryStatus(int deliveryId, string status)
        {
            var userId = User.Identity.GetUserId();
            var delivery = db.Deliveries.Include(d => d.Order).FirstOrDefault(d => d.Id == deliveryId);
            if (delivery == null)
            {
                return Json(new { success = false, message = "Delivery not found." });
            }

            try
            {
                delivery.Status = status;
                
                if (status == "Picked Up")
                {
                    delivery.PickupDate = DateTime.Now;
                }
                else if (status == "In Transit")
                {
                    // Generate tracking number if not exists
                    if (string.IsNullOrEmpty(delivery.TrackingNumber))
                    {
                        delivery.TrackingNumber = "TRK" + DateTime.Now.ToString("yyyyMMdd") + delivery.Id.ToString("D6");
                    }
                }
                else if (status == "Delivered")
                {
                    delivery.DeliveryDate = DateTime.Now;
                    
                    // Update order status
                    var order = db.Orders.FirstOrDefault(o => o.Id == delivery.OrderId);
                    if (order != null)
                    {
                        order.Status = "Delivered";
                        order.DeliveryDate = DateTime.Now;
                    }
                }

                await db.SaveChangesAsync();

                // Create notification for customer
                var notification = new Notification
                {
                    UserId = delivery.Order.Customer.UserId,
                    Title = "Delivery Status Updated",
                    Message = "Your order #" + delivery.Order.OrderNumber + " delivery status has been updated to " + status + ".",
                    Type = "Delivery",
                    IsRead = false,
                    CreatedAt = DateTime.Now
                };
                db.Notifications.Add(notification);
                await db.SaveChangesAsync();

                return Json(new { success = true, message = "Delivery status updated successfully!" });
            }
            catch (Exception)
            {
                return Json(new { success = false, message = "Error updating delivery status." });
            }
        }

        // POST: DeliveryDriver/AddDeliveryNote
        [HttpPost]
        public async Task<ActionResult> AddDeliveryNote(int deliveryId, string note)
        {
            var userId = User.Identity.GetUserId();
            var driver = db.DeliveryDrivers.FirstOrDefault(d => d.UserId == userId);
            
            if (driver == null)
            {
                return Json(new { success = false, message = "Driver not found." });
            }

            var delivery = db.Deliveries.FirstOrDefault(d => d.Id == deliveryId);
            if (delivery == null)
            {
                return Json(new { success = false, message = "Delivery not found." });
            }

            try
            {
                delivery.Notes = note;
                await db.SaveChangesAsync();

                return Json(new { success = true, message = "Note added successfully!" });
            }
            catch (Exception)
            {
                return Json(new { success = false, message = "Error adding note." });
            }
        }

        // GET: DeliveryDriver/Earnings
        public ActionResult Earnings()
        {
            var userId = User.Identity.GetUserId();
            var driver = db.DeliveryDrivers.FirstOrDefault(d => d.UserId == userId);
            
            if (driver == null)
            {
                return HttpNotFound();
            }

            var currentMonth = DateTime.Now.Month;
            var currentYear = DateTime.Now.Year;

            var viewModel = new DriverEarningsViewModel
            {
                Driver = driver,
                TotalEarnings = driver.Deliveries.Where(d => d.Status == "Delivered").Sum(d => d.DeliveryFee),
                MonthlyEarnings = driver.Deliveries
                    .Where(d => d.Status == "Delivered" && d.DeliveryDate.HasValue && d.DeliveryDate.Value.Month == currentMonth && d.DeliveryDate.Value.Year == currentYear)
                    .Sum(d => d.DeliveryFee),
                WeeklyEarnings = driver.Deliveries
                    .Where(d => d.Status == "Delivered" && d.DeliveryDate.HasValue && d.DeliveryDate.Value >= DateTime.Now.AddDays(-7))
                    .Sum(d => d.DeliveryFee),
                CompletedDeliveries = driver.Deliveries.Count(d => d.Status == "Delivered"),
                RecentEarnings = driver.Deliveries
                    .Where(d => d.Status == "Delivered")
                    .OrderByDescending(d => d.DeliveryDate)
                    .Take(10)
                    .ToList()
            };

            return View(viewModel);
        }

        // GET: DeliveryDriver/Profile
        public ActionResult Profile()
        {
            return RedirectToAction("DriverProfile");
        }

        // GET: DeliveryDriver/DriverProfile
        public ActionResult DriverProfile()
        {
            var userId = User.Identity.GetUserId();
            var driver = db.DeliveryDrivers
                .Include(d => d.User)
                .FirstOrDefault(d => d.UserId == userId);

            if (driver == null)
            {
                return HttpNotFound();
            }

            return View(driver);
        }

        // GET: DeliveryDriver/UpdateProfile
        public ActionResult UpdateProfile()
        {
            var userId = User.Identity.GetUserId();
            var driver = db.DeliveryDrivers
                .Include(d => d.User)
                .FirstOrDefault(d => d.UserId == userId);

            if (driver == null)
            {
                return HttpNotFound();
            }

            return View(driver);
        }

        // POST: DeliveryDriver/UpdateProfile
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> UpdateProfile(DeliveryDriver model)
        {
            if (ModelState.IsValid)
            {
                var userId = User.Identity.GetUserId();
                var driver = db.DeliveryDrivers
                    .Include(d => d.User)
                    .FirstOrDefault(d => d.UserId == userId);
                
                if (driver == null)
                {
                    return HttpNotFound();
                }

                // Update driver properties
                driver.VehicleType = model.VehicleType;
                driver.VehicleNumber = model.VehicleNumber;
                driver.LicenseNumber = model.LicenseNumber;
                driver.VehicleRegistration = model.VehicleRegistration;
                driver.IsAvailable = model.IsAvailable;

                // Update user phone number if provided
                if (driver.User != null && !string.IsNullOrEmpty(model.User.PhoneNumber))
                {
                    driver.User.PhoneNumber = model.User.PhoneNumber;
                }

                await db.SaveChangesAsync();

                TempData["SuccessMessage"] = "Profile updated successfully!";
                return RedirectToAction("DriverProfile");
            }

            return View(model);
        }

        // GET: DeliveryDriver/Wallet
        public ActionResult Wallet()
        {
            var userId = User.Identity.GetUserId();
            var wallet = db.Wallets.Include(w => w.Transactions).FirstOrDefault(w => w.UserId == userId);

            if (wallet == null)
            {
                wallet = new Wallet
                {
                    UserId = userId,
                    Balance = 0,
                    Transactions = new List<Transaction>()
                };
                db.Wallets.Add(wallet);
                db.SaveChanges();
            }

            var viewModel = new WalletViewModel
            {
                Wallet = wallet,
                Transactions = wallet.Transactions.OrderByDescending(t => t.TransactionDate).ToList()
            };

            return View(viewModel);
        }

        // POST: DeliveryDriver/AddToWallet
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> AddToWallet(decimal amount)
        {
            if (amount <= 0)
            {
                TempData["ErrorMessage"] = "Amount must be greater than zero.";
                return RedirectToAction("Wallet");
            }

            var userId = User.Identity.GetUserId();
            var wallet = db.Wallets.FirstOrDefault(w => w.UserId == userId);

            if (wallet == null)
            {
                wallet = new Wallet
                {
                    UserId = userId,
                    Balance = 0
                };
                db.Wallets.Add(wallet);
            }

            var balanceBefore = wallet.Balance;
            wallet.Balance += amount;

            var transaction = new Transaction
            {
                UserId = userId,
                WalletId = wallet.UserId,
                TransactionType = "Deposit",
                Amount = amount,
                BalanceBefore = balanceBefore,
                BalanceAfter = wallet.Balance,
                Description = "Wallet deposit",
                TransactionDate = DateTime.Now
            };

            db.Transactions.Add(transaction);
            await db.SaveChangesAsync();

            TempData["SuccessMessage"] = "Successfully added " + amount.ToString("C") + " to your wallet.";
            return RedirectToAction("Wallet");
        }

        // POST: DeliveryDriver/WithdrawFromWallet
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> WithdrawFromWallet(decimal amount)
        {
            if (amount <= 0)
            {
                TempData["ErrorMessage"] = "Amount must be greater than zero.";
                return RedirectToAction("Wallet");
            }

            var userId = User.Identity.GetUserId();
            var wallet = db.Wallets.FirstOrDefault(w => w.UserId == userId);

            if (wallet == null)
            {
                TempData["ErrorMessage"] = "Wallet not found.";
                return RedirectToAction("Wallet");
            }

            if (wallet.Balance < amount)
            {
                TempData["ErrorMessage"] = "Insufficient balance.";
                return RedirectToAction("Wallet");
            }

            var balanceBefore = wallet.Balance;
            wallet.Balance -= amount;

            var transaction = new Transaction
            {
                UserId = userId,
                WalletId = wallet.UserId,
                TransactionType = "Withdrawal",
                Amount = -amount,
                BalanceBefore = balanceBefore,
                BalanceAfter = wallet.Balance,
                Description = "Wallet withdrawal",
                TransactionDate = DateTime.Now
            };

            db.Transactions.Add(transaction);
            await db.SaveChangesAsync();

            TempData["SuccessMessage"] = "Successfully withdrawn " + amount.ToString("C") + " from your wallet.";
            return RedirectToAction("Wallet");
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