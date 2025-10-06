using System;
using System.IO;
using System.Linq;
using System.Web.Mvc;
using Microsoft.AspNet.Identity;
using Connect2Us.Models;
using System.Data.Entity;
using System.Threading.Tasks;
using System.Web;

namespace Connect2Us.Controllers
{
    [Authorize(Roles = "Bookstore")]
    public class BookstoreController : Controller
    {
        private ApplicationDbContext db = new ApplicationDbContext();

        // GET: Bookstore
        public ActionResult Index()
        {
            var userId = User.Identity.GetUserId();
            var bookstore = db.Bookstores
                .Include(b => b.Products)
                .Include(b => b.Orders)
                .FirstOrDefault(b => b.UserId == userId);

            if (bookstore == null)
            {
                return HttpNotFound();
            }

            var wallet = db.Wallets.FirstOrDefault(w => w.UserId == userId);

            var viewModel = new BookstoreDashboardViewModel
            {
                Bookstore = bookstore,
                TotalProducts = bookstore.Products.Count,
                TotalOrders = bookstore.Orders.Count,
                PendingOrders = bookstore.Orders.Count(o => o.Status == "Pending"),
                TotalRevenue = bookstore.Orders.Where(o => o.IsPaid).Sum(o => o.TotalAmount),
                RecentOrders = bookstore.Orders.OrderByDescending(o => o.OrderDate).Take(5).ToList(),
                WalletBalance = wallet?.Balance ?? 0
            };

            return View(viewModel);
        }

        public ActionResult Transactions()
        {
            var userId = User.Identity.GetUserId();
            var transactions = db.Transactions
                .Include(t => t.Order)
                .Where(t => t.Order.Bookstore.UserId == userId)
                .OrderByDescending(t => t.TransactionDate)
                .ToList();

            var viewModel = new TransactionViewModel
            {
                Transactions = transactions
            };

            return View(viewModel);
        }

        // GET: Bookstore/Products
        public ActionResult Products()
        {
            var userId = User.Identity.GetUserId();
            var bookstore = db.Bookstores.FirstOrDefault(b => b.UserId == userId);
            
            if (bookstore == null)
            {
                return HttpNotFound();
            }

            var products = db.Products
                .Include(p => p.Category)
                .Where(p => p.BookstoreId == bookstore.UserId)
                .OrderBy(p => p.Name)
                .ToList();

            return View(products);
        }

        // GET: Bookstore/CreateProduct
        public ActionResult CreateProduct()
        {
            ViewBag.CategoryId = new SelectList(db.Categories.Where(c => c.IsActive), "Id", "Name");
            return View();
        }

        // POST: Bookstore/CreateProduct
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> CreateProduct(Product product, HttpPostedFileBase imageFile)
        {
            if (ModelState.IsValid)
            {
                var userId = User.Identity.GetUserId();
                var bookstore = db.Bookstores.FirstOrDefault(b => b.UserId == userId);
                
                if (bookstore == null)
                {
                    return HttpNotFound();
                }

                product.BookstoreId = bookstore.UserId;
                product.CreatedAt = DateTime.Now;
                product.UpdatedAt = DateTime.Now;

                // Handle image upload
                if (imageFile != null && imageFile.ContentLength > 0)
                {
                    var fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                    var path = Path.Combine(Server.MapPath("~/Content/ProductImages"), fileName);
                    
                    // Create directory if it doesn't exist
                    Directory.CreateDirectory(Server.MapPath("~/Content/ProductImages"));
                    
                    imageFile.SaveAs(path);
                    product.ImageUrl = "/Content/ProductImages/" + fileName;
                }

                db.Products.Add(product);
                await db.SaveChangesAsync();

                TempData["SuccessMessage"] = "Product created successfully!";
                return RedirectToAction("Products");
            }

            ViewBag.CategoryId = new SelectList(db.Categories.Where(c => c.IsActive), "Id", "Name", product.CategoryId);
            return View(product);
        }

        // GET: Bookstore/EditProduct/5
        public ActionResult EditProduct(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            }

            var userId = User.Identity.GetUserId();
            var bookstore = db.Bookstores.FirstOrDefault(b => b.UserId == userId);
            
            if (bookstore == null)
            {
                return HttpNotFound();
            }

            var product = db.Products.FirstOrDefault(p => p.Id == id && p.BookstoreId == bookstore.UserId);
            if (product == null)
            {
                return HttpNotFound();
            }

            ViewBag.CategoryId = new SelectList(db.Categories.Where(c => c.IsActive), "Id", "Name", product.CategoryId);
            return View(product);
        }

        // POST: Bookstore/EditProduct/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> EditProduct(Product product, HttpPostedFileBase imageFile)
        {
            if (ModelState.IsValid)
            {
                var userId = User.Identity.GetUserId();
                var bookstore = db.Bookstores.FirstOrDefault(b => b.UserId == userId);
                
                if (bookstore == null)
                {
                    return HttpNotFound();
                }

                var existingProduct = db.Products.FirstOrDefault(p => p.Id == product.Id && p.BookstoreId == bookstore.UserId);
                if (existingProduct == null)
                {
                    return HttpNotFound();
                }

                // Update product properties
                existingProduct.Name = product.Name;
                existingProduct.Description = product.Description;
                existingProduct.Price = product.Price;
                existingProduct.StockQuantity = product.StockQuantity;
                existingProduct.ISBN = product.ISBN;
                existingProduct.Author = product.Author;
                existingProduct.Publisher = product.Publisher;
                existingProduct.ProductType = product.ProductType;
                existingProduct.IsForRent = product.IsForRent;
                existingProduct.RentalPrice = product.RentalPrice;
                existingProduct.IsAvailable = product.IsAvailable;
                existingProduct.CategoryId = product.CategoryId;
                existingProduct.UpdatedAt = DateTime.Now;

                // Handle image upload
                if (imageFile != null && imageFile.ContentLength > 0)
                {
                    // Delete old image if exists
                    if (!string.IsNullOrEmpty(existingProduct.ImageUrl))
                    {
                        var oldImagePath = Server.MapPath(existingProduct.ImageUrl);
                        if (System.IO.File.Exists(oldImagePath))
                        {
                            System.IO.File.Delete(oldImagePath);
                        }
                    }

                    var fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                    var path = Path.Combine(Server.MapPath("~/Content/ProductImages"), fileName);
                    
                    Directory.CreateDirectory(Server.MapPath("~/Content/ProductImages"));
                    imageFile.SaveAs(path);
                    existingProduct.ImageUrl = "/Content/ProductImages/" + fileName;
                }

                await db.SaveChangesAsync();
                TempData["SuccessMessage"] = "Product updated successfully!";
                return RedirectToAction("Products");
            }

            ViewBag.CategoryId = new SelectList(db.Categories.Where(c => c.IsActive), "Id", "Name", product.CategoryId);
            return View(product);
        }

        // POST: Bookstore/DeleteProduct/5
        [HttpPost]
        public async Task<ActionResult> DeleteProduct(int id)
        {
            var userId = User.Identity.GetUserId();
            var bookstore = db.Bookstores.FirstOrDefault(b => b.UserId == userId);
            
            if (bookstore == null)
            {
                return Json(new { success = false, message = "Bookstore not found." });
            }

            var product = db.Products.FirstOrDefault(p => p.Id == id && p.BookstoreId == bookstore.UserId);
            if (product == null)
            {
                return Json(new { success = false, message = "Product not found." });
            }

            try
            {
                // Delete product image if exists
                if (!string.IsNullOrEmpty(product.ImageUrl))
                {
                    var imagePath = Server.MapPath(product.ImageUrl);
                    if (System.IO.File.Exists(imagePath))
                    {
                        System.IO.File.Delete(imagePath);
                    }
                }

                db.Products.Remove(product);
                await db.SaveChangesAsync();

                return Json(new { success = true, message = "Product deleted successfully!" });
            }
            catch (Exception)
            {
                return Json(new { success = false, message = "Error deleting product." });
            }
        }

        // GET: Bookstore/Orders
        public ActionResult Orders()
        {
            var userId = User.Identity.GetUserId();
            var bookstore = db.Bookstores.FirstOrDefault(b => b.UserId == userId);
            
            if (bookstore == null)
            {
                return HttpNotFound();
            }

            var orders = db.Orders
                .Include(o => o.Customer.User)
                .Include(o => o.OrderItems.Select(oi => oi.Product))
                .Where(o => o.BookstoreId == bookstore.UserId)
                .OrderByDescending(o => o.OrderDate)
                .ToList();

            return View(orders);
        }

        // GET: Bookstore/OrderDetails/5
        public ActionResult OrderDetails(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            }

            var userId = User.Identity.GetUserId();
            var bookstore = db.Bookstores.FirstOrDefault(b => b.UserId == userId);
            
            if (bookstore == null)
            {
                return HttpNotFound();
            }

            var order = db.Orders
                .Include(o => o.Customer.User)
                .Include(o => o.OrderItems.Select(oi => oi.Product))
                .Include(o => o.Deliveries)
                .FirstOrDefault(o => o.Id == id && o.BookstoreId == bookstore.UserId);

            if (order == null)
            {
                return HttpNotFound();
            }

            return View(order);
        }

        // POST: Bookstore/UpdateOrderStatus
        [HttpPost]
        public async Task<ActionResult> UpdateOrderStatus(int orderId, string status)
        {
            var userId = User.Identity.GetUserId();
            var bookstore = db.Bookstores.FirstOrDefault(b => b.UserId == userId);
            
            if (bookstore == null)
            {
                return Json(new { success = false, message = "Bookstore not found." });
            }

            var order = db.Orders.FirstOrDefault(o => o.Id == orderId && o.BookstoreId == bookstore.UserId);
            if (order == null)
            {
                return Json(new { success = false, message = "Order not found." });
            }

            try
            {
                order.Status = status;
                
                if (status == "Shipped" || status == "Out for Delivery")
                {
                    order.DeliveryDate = DateTime.Now.AddDays(1); // Estimated delivery
                }

                await db.SaveChangesAsync();

                // Create notification for customer
                var notification = new Notification
                {
                    UserId = order.Customer.UserId,
                    Title = "Order Status Updated",
                    Message = "Your order #" + order.OrderNumber + " status has been updated to " + status + ".",
                    Type = "Order",
                    IsRead = false,
                    CreatedAt = DateTime.Now
                };
                db.Notifications.Add(notification);
                await db.SaveChangesAsync();

                return Json(new { success = true, message = "Order status updated successfully!" });
            }
            catch (Exception)
            {
                return Json(new { success = false, message = "Error updating order status." });
            }
        }

        // GET: Bookstore/Reports
        public ActionResult Reports()
        {
            var userId = User.Identity.GetUserId();
            var bookstore = db.Bookstores.FirstOrDefault(b => b.UserId == userId);
            
            if (bookstore == null)
            {
                return HttpNotFound();
            }

            var viewModel = new BookstoreReportsViewModel
            {
                TotalRevenue = bookstore.Orders.Where(o => o.IsPaid).Sum(o => o.TotalAmount),
                TotalOrders = bookstore.Orders.Count,
                TotalProducts = bookstore.Products.Count,
                LowStockProducts = bookstore.Products.Where(p => p.StockQuantity < 10).ToList(),
                MonthlyRevenue = bookstore.Orders
                    .Where(o => o.IsPaid && o.OrderDate.Year == DateTime.Now.Year)
                    .GroupBy(o => o.OrderDate.Month)
                    .Select(g => new MonthlyRevenue { Month = g.Key, Revenue = g.Sum(o => o.TotalAmount) })
                    .ToList()
            };

            return View(viewModel);
        }

        // GET: Bookstore/Wallet
        public ActionResult Wallet()
        {
            var userId = User.Identity.GetUserId();
            var wallet = db.Wallets
                .Include(w => w.Transactions)
                .FirstOrDefault(w => w.UserId == userId);

            return View(wallet);
        }

        // POST: Bookstore/AddToWallet
        [HttpPost]
        public async Task<ActionResult> AddToWallet(decimal amount)
        {
            if (amount <= 0)
            {
                TempData["ErrorMessage"] = "Invalid amount.";
                return RedirectToAction("Wallet");
            }

            var userId = User.Identity.GetUserId();
            var wallet = db.Wallets.FirstOrDefault(w => w.UserId == userId);
            
            if (wallet == null)
            {
                TempData["ErrorMessage"] = "Wallet not found.";
                return RedirectToAction("Wallet");
            }

            try
            {
                var oldBalance = wallet.Balance;
                wallet.Balance += amount;

                var transaction = new Transaction
                {
                    UserId = userId,
                    WalletId = wallet.UserId,
                    TransactionType = "Deposit",
                    Amount = amount,
                    BalanceBefore = oldBalance,
                    BalanceAfter = wallet.Balance,
                    Description = "Wallet deposit",
                    TransactionDate = DateTime.Now
                };

                db.Transactions.Add(transaction);
                await db.SaveChangesAsync();

                TempData["SuccessMessage"] = "Successfully added $" + amount.ToString("F2") + " to your wallet.";
            }
            catch (Exception)
            {
                TempData["ErrorMessage"] = "An error occurred while processing your request.";
            }

            return RedirectToAction("Wallet");
        }

        // POST: Bookstore/WithdrawFromWallet
        [HttpPost]
        public async Task<ActionResult> WithdrawFromWallet(decimal amount)
        {
            if (amount <= 0)
            {
                TempData["ErrorMessage"] = "Invalid amount.";
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
                TempData["ErrorMessage"] = "Insufficient wallet balance.";
                return RedirectToAction("Wallet");
            }

            try
            {
                var oldBalance = wallet.Balance;
                wallet.Balance -= amount;

                var transaction = new Transaction
                {
                    UserId = userId,
                    WalletId = wallet.UserId,
                    TransactionType = "Withdrawal",
                    Amount = -amount,
                    BalanceBefore = oldBalance,
                    BalanceAfter = wallet.Balance,
                    Description = "Wallet withdrawal",
                    TransactionDate = DateTime.Now
                };

                db.Transactions.Add(transaction);
                await db.SaveChangesAsync();

                TempData["SuccessMessage"] = "Successfully withdrew $" + amount.ToString("F2") + " from your wallet.";
            }
            catch (Exception)
            {
                TempData["ErrorMessage"] = "An error occurred while processing your request.";
            }

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