using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.Owin;

using System.Data.Entity;
using System.Threading.Tasks;
using Connect2Us.Models;
using Connect2Us.ViewModels;

namespace Connect2Us.Controllers
{
    [Authorize(Roles = "Customer")]
    public class CustomerController : Controller
    {
        private ApplicationDbContext db = new ApplicationDbContext();

        // GET: Customer
        public ActionResult Index()
        {
            var userId = User.Identity.GetUserId();
            var customer = db.Customers.Include(c => c.User).FirstOrDefault(c => c.UserId == userId);
            var wallet = db.Wallets.FirstOrDefault(w => w.UserId == userId);

            if (customer == null)
            {
                return HttpNotFound();
            }
            
            ViewBag.WalletBalance = wallet?.Balance ?? 0;
            return View(customer);
        }

        // GET: Customer/Browse
        public ActionResult Browse()
        {
            var products = db.Products
                .Include(p => p.Bookstore)
                .Include(p => p.Category)
                .Where(p => p.IsAvailable && p.StockQuantity > 0)
                .ToList();
            
            ViewBag.Categories = db.Categories.Where(c => c.IsActive).ToList();
            return View(products);
        }

        // GET: Customer/BrowseByCategory/5
        public ActionResult BrowseByCategory(int id)
        {
            var products = db.Products
                .Include(p => p.Bookstore)
                .Include(p => p.Category)
                .Where(p => p.CategoryId == id && p.IsAvailable && p.StockQuantity > 0)
                .ToList();
            
            ViewBag.Categories = db.Categories.Where(c => c.IsActive).ToList();
            ViewBag.SelectedCategory = db.Categories.Find(id)?.Name;
            return View("Browse", products);
        }

        // GET: Customer/ProductDetails/5
        public ActionResult ProductDetails(int id)
        {
            var product = db.Products
                .Include(p => p.Bookstore)
                .Include(p => p.Category)
                .FirstOrDefault(p => p.Id == id);
            
            if (product == null)
            {
                return HttpNotFound();
            }
            
            return View(product);
        }

        // GET: Customer/Checkout
        public ActionResult Checkout()
        {
            var userId = User.Identity.GetUserId();
            var customer = db.Customers.FirstOrDefault(c => c.UserId == userId);
            var wallet = db.Wallets.FirstOrDefault(w => w.UserId == userId);
            
            // Use database cart instead of session cart
            var dbCart = db.Carts.Include(c => c.CartItems.Select(ci => ci.Product)).FirstOrDefault(c => c.UserId == userId);
            
            if (dbCart == null || !dbCart.CartItems.Any())
            {
                TempData["ErrorMessage"] = "Your cart is empty.";
                return RedirectToAction("Browse");
            }

            // Convert database cart items to CustomerCartItem format
            var cartItems = dbCart.CartItems.Select(item => new CustomerCartItem
            {
                ProductId = item.ProductId,
                ProductName = item.Product.Name,
                Price = item.Product.Price,
                Quantity = item.Quantity,
                IsRental = false, // Default to false, can be enhanced later
                BookstoreId = item.Product.BookstoreId
            }).ToList();

            var viewModel = new CheckoutViewModel
            {
                CartItems = cartItems,
                WalletBalance = wallet?.Balance ?? 0,
                TotalAmount = cartItems.Sum(item => item.Price * item.Quantity)
            };

            return View(viewModel);
        }

        // POST: Customer/PlaceOrder
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> PlaceOrder(CheckoutViewModel model)
        {
            var userId = User.Identity.GetUserId();
            var customer = db.Customers.FirstOrDefault(c => c.UserId == userId);
            var wallet = db.Wallets.FirstOrDefault(w => w.UserId == userId);
            
            // Use database cart instead of session cart
            var dbCart = db.Carts.Include(c => c.CartItems.Select(ci => ci.Product)).FirstOrDefault(c => c.UserId == userId);
            
            if (dbCart == null || !dbCart.CartItems.Any())
            {
                TempData["ErrorMessage"] = "Your cart is empty.";
                return RedirectToAction("Browse");
            }

            // Convert database cart items to CustomerCartItem format
            var cartItems = dbCart.CartItems.Select(item => new CustomerCartItem
            {
                ProductId = item.ProductId,
                ProductName = item.Product.Name,
                Price = item.Product.Price,
                Quantity = item.Quantity,
                IsRental = false, // Default to false, can be enhanced later
                BookstoreId = item.Product.BookstoreId
            }).ToList();

            if (model.TotalAmount > (wallet?.Balance ?? 0))
            {
                ModelState.AddModelError("", "Insufficient wallet balance.");
                return View("Checkout", model);
            }

            try
            {
                // Group cart items by bookstore
                var ordersByBookstore = cartItems.GroupBy(item => item.BookstoreId);
                
                foreach (var bookstoreGroup in ordersByBookstore)
                {
                    var order = new Order
                    {
                        CustomerId = customer.UserId,
                        BookstoreId = bookstoreGroup.Key,
                        OrderNumber = "ORD" + DateTime.Now.ToString("yyyyMMddHHmmss") + new Random().Next(1000, 9999).ToString(),
                        TotalAmount = bookstoreGroup.Sum(item => item.Price * item.Quantity),
                        Status = "Pending",
                        OrderDate = DateTime.Now,
                        DeliveryAddress = model.DeliveryAddress,
                        Notes = model.Notes,
                        IsPaid = false
                    };

                    db.Orders.Add(order);
                    await db.SaveChangesAsync();

                    // Add order items
                    foreach (var item in bookstoreGroup)
                    {
                        var orderItem = new OrderItem
                        {
                            OrderId = order.Id,
                            ProductId = item.ProductId,
                            Quantity = item.Quantity,
                            UnitPrice = item.Price,
                            TotalPrice = item.Price * item.Quantity,
                            IsRental = item.IsRental
                        };

                        if (item.IsRental)
                        {
                            orderItem.RentalStartDate = DateTime.Now;
                            orderItem.RentalEndDate = DateTime.Now.AddDays(30); // 30-day rental period
                        }

                        db.OrderItems.Add(orderItem);

                        // Update product stock
                        var product = db.Products.Find(item.ProductId);
                        if (product != null)
                        {
                            product.StockQuantity -= item.Quantity;
                        }
                    }

                    // Create payment record
                    var payment = new Payment
                    {
                        OrderId = order.Id,
                        Amount = order.TotalAmount,
                        PaymentMethod = "Wallet",
                        Status = "Completed",
                        PaymentDate = DateTime.Now
                    };
                    db.Payments.Add(payment);

                    // Update order as paid
                    order.IsPaid = true;
                    order.PaymentDate = DateTime.Now;

                    // Deduct from wallet
                    wallet.Balance -= order.TotalAmount;

                    // Create transaction record
                    var transaction = new Transaction
                    {
                        UserId = userId,
                        WalletId = wallet.UserId,
                        OrderId = order.Id,
                        TransactionType = "Purchase",
                        Amount = -order.TotalAmount,
                        BalanceBefore = wallet.Balance + order.TotalAmount,
                        BalanceAfter = wallet.Balance,
                        Description = "Order " + order.OrderNumber + " payment",
                        TransactionDate = DateTime.Now
                    };
                    db.Transactions.Add(transaction);

                    // Create notification for bookstore
                    var notification = new Notification
                    {
                        UserId = db.Bookstores.Find(bookstoreGroup.Key).UserId,
                        Title = "New Order",
                        Message = "New order #" + order.OrderNumber + " has been placed.",
                        Type = "Order",
                        IsRead = false,
                        CreatedAt = DateTime.Now
                    };
                    db.Notifications.Add(notification);
                }

                await db.SaveChangesAsync();

                // Clear database cart - reload cart to ensure proper tracking
                var cartToClear = db.Carts.Include(c => c.CartItems).FirstOrDefault(c => c.UserId == userId);
                if (cartToClear != null && cartToClear.CartItems.Any())
                {
                    db.CartItems.RemoveRange(cartToClear.CartItems);
                    await db.SaveChangesAsync();
                }

                TempData["SuccessMessage"] = "Order placed successfully!";
                return RedirectToAction("Index", "Home");
            }
            catch (Exception ex)
            {
                // Log the actual error for debugging
                System.Diagnostics.Debug.WriteLine($"Order placement error: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");
                
                // Provide more specific error messages based on common issues
                if (ex.Message.Contains("wallet") || ex.Message.Contains("balance"))
                {
                    ModelState.AddModelError("", "Insufficient wallet balance. Please add funds to your wallet before placing the order.");
                }
                else if (ex.Message.Contains("stock") || ex.Message.Contains("quantity"))
                {
                    ModelState.AddModelError("", "Some items in your cart are no longer available or have insufficient stock.");
                }
                else
                {
                    ModelState.AddModelError("", "An error occurred while placing your order. Please try again. If the problem persists, contact support.");
                }
                
                return View("Checkout", model);
            }
        }

        // GET: Customer/MyOrders
        public ActionResult MyOrders(bool? success)
        {
            if (success == true && TempData["SuccessMessage"] == null)
            {
                TempData["SuccessMessage"] = "Order placed successfully!";
            }
            var userId = User.Identity.GetUserId();
            var customer = db.Customers.FirstOrDefault(c => c.UserId == userId);
            
            var orders = db.Orders
                .Include(o => o.Bookstore)
                .Include(o => o.OrderItems)
                .Where(o => o.CustomerId == customer.UserId)
                .OrderByDescending(o => o.OrderDate)
                .ToList();

            return View(orders);
        }

        // GET: Customer/OrderDetails/5
        public ActionResult OrderDetails(int id)
        {
            var userId = User.Identity.GetUserId();
            var customer = db.Customers.FirstOrDefault(c => c.UserId == userId);
            
            var order = db.Orders
                .Include(o => o.Bookstore)
                .Include(o => o.OrderItems.Select(oi => oi.Product))
                .Include(o => o.Deliveries)
                .FirstOrDefault(o => o.Id == id && o.CustomerId == customer.UserId);

            if (order == null)
            {
                return HttpNotFound();
            }

            return View(order);
        }

        // GET: Customer/Wallet
        public ActionResult Wallet()
        {
            var userId = User.Identity.GetUserId();
            var wallet = db.Wallets
                .Include(w => w.Transactions)
                .Include(w => w.BankCards)
                .FirstOrDefault(w => w.UserId == userId);

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

            return View(wallet);
        }

        // GET: Customer/ManageCards
        public ActionResult ManageCards()
        {
            var userId = User.Identity.GetUserId();
            var cards = db.BankCards.Where(c => c.UserId == userId).ToList();
            
            return View(cards);
        }

        // GET: Customer/AddCard
        public ActionResult AddCard()
        {
            return View(new BankCardViewModel());
        }

        // POST: Customer/AddCard
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> AddCard(BankCardViewModel model)
        {
            if (ModelState.IsValid)
            {
                var userId = User.Identity.GetUserId();
                
                // Check if card already exists
                var existingCard = db.BankCards.FirstOrDefault(c => c.CardNumber == model.CardNumber && c.UserId == userId);
                if (existingCard != null)
                {
                    ModelState.AddModelError("", "This card is already added to your wallet.");
                    return View(model);
                }

                var bankCard = new BankCard
                {
                    UserId = userId,
                    CardNumber = model.CardNumber,
                    CardholderName = model.CardholderName,
                    ExpiryDate = model.ExpiryDate,
                    CVV = model.CVV,
                    CardType = BankCardViewModel.DetectCardType(model.CardNumber),
                    IsActive = true,
                    AddedDate = DateTime.Now
                };

                db.BankCards.Add(bankCard);
                await db.SaveChangesAsync();

                TempData["SuccessMessage"] = "Card added successfully!";
                return RedirectToAction("ManageCards");
            }

            return View(model);
        }

        // POST: Customer/RemoveCard/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> RemoveCard(int id)
        {
            var userId = User.Identity.GetUserId();
            var card = db.BankCards.FirstOrDefault(c => c.Id == id && c.UserId == userId);
            
            if (card == null)
            {
                TempData["ErrorMessage"] = "Card not found.";
                return RedirectToAction("ManageCards");
            }

            db.BankCards.Remove(card);
            await db.SaveChangesAsync();

            TempData["SuccessMessage"] = "Card removed successfully!";
            return RedirectToAction("ManageCards");
        }

        // POST: Customer/ToggleCardStatus/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> ToggleCardStatus(int id)
        {
            var userId = User.Identity.GetUserId();
            var card = db.BankCards.FirstOrDefault(c => c.Id == id && c.UserId == userId);
            
            if (card == null)
            {
                TempData["ErrorMessage"] = "Card not found.";
                return RedirectToAction("ManageCards");
            }

            card.IsActive = !card.IsActive;
            await db.SaveChangesAsync();

            TempData["SuccessMessage"] = card.IsActive ? "Card activated!" : "Card deactivated!";
            return RedirectToAction("ManageCards");
        }

        // POST: Customer/AddToWallet
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