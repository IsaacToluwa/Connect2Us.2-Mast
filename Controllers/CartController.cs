using System;
using Connect2Us.Models;
using Microsoft.AspNet.Identity;
using System.Linq;
using System.Web.Mvc;
using System.Data.Entity;

namespace Connect2Us.Controllers
{
    [Authorize]
    public class CartController : Controller
    {
        private readonly ApplicationDbContext _context;

        public CartController()
        {
            _context = new ApplicationDbContext();
        }

        // GET: Cart
        public ActionResult Index()
        {
            try
            {
                var userId = User.Identity.GetUserId();
                var cart = _context.Carts.Include("CartItems.Product").SingleOrDefault(c => c.UserId == userId);
                return View(cart);
            }
            catch (Exception ex)
            {
                TempData["error"] = "An error occurred while loading your cart. Please try again.";
                return View();
            }
        }

        // POST: Cart/AddToCart/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult AddToCart(int productId, int quantity = 1)
        {
            try
            {
                var userId = User.Identity.GetUserId();
                var cart = _context.Carts.SingleOrDefault(c => c.UserId == userId);

                if (cart == null)
                {
                    cart = new Cart { UserId = userId };
                    _context.Carts.Add(cart);
                    _context.SaveChanges(); // Save to get the cart ID
                }

                // Check if product exists and has stock
                var product = _context.Products.Find(productId);
                if (product == null)
                {
                    TempData["error"] = "Product not found.";
                    return RedirectToAction("Index", "Home");
                }

                if (product.StockQuantity < quantity)
                {
                    TempData["error"] = "Sorry, only " + product.StockQuantity + " items available in stock.";
                    return RedirectToAction("Index", "Home");
                }

                var cartItem = _context.CartItems.SingleOrDefault(ci => ci.CartId == cart.Id && ci.ProductId == productId);

                if (cartItem == null)
                {
                    cartItem = new CartItem
                    {
                        CartId = cart.Id,
                        ProductId = productId,
                        Quantity = quantity
                    };
                    _context.CartItems.Add(cartItem);
                }
                else
                {
                    // Check if adding more would exceed stock
                    if (product.StockQuantity < cartItem.Quantity + quantity)
                    {
                        TempData["error"] = "Sorry, only " + product.StockQuantity + " items available in stock. You already have " + cartItem.Quantity + " in your cart.";
                        return RedirectToAction("Index");
                    }
                    cartItem.Quantity += quantity;
                }

                _context.SaveChanges();
                TempData["success"] = product.Name + " added to cart successfully!";

                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["error"] = "An error occurred while adding the item to your cart. Please try again.";
                return RedirectToAction("Index", "Home");
            }
        }

        // POST: Cart/RemoveFromCart/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult RemoveFromCart(int productId)
        {
            try
            {
                var userId = User.Identity.GetUserId();
                var cart = _context.Carts.SingleOrDefault(c => c.UserId == userId);

                if (cart != null)
                {
                    var cartItem = _context.CartItems.SingleOrDefault(ci => ci.CartId == cart.Id && ci.ProductId == productId);

                    if (cartItem != null)
                    {
                        var product = _context.Products.Find(productId);
                        _context.CartItems.Remove(cartItem);
                        _context.SaveChanges();
                        
                        TempData["success"] = (product != null ? product.Name : "Item") + " removed from cart successfully!";
                    }
                    else
                    {
                        TempData["error"] = "Item not found in your cart.";
                    }
                }
                else
                {
                    TempData["error"] = "Your cart is empty.";
                }

                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["error"] = "An error occurred while removing the item from your cart. Please try again.";
                return RedirectToAction("Index");
            }
        }

        // GET: Cart/GetCartItemCount
        [HttpGet]
        public JsonResult GetCartItemCount()
        {
            try
            {
                var userId = User.Identity.GetUserId();
                var cart = _context.Carts.Include("CartItems").SingleOrDefault(c => c.UserId == userId);
                var count = cart?.CartItems?.Sum(ci => ci.Quantity) ?? 0;
                return Json(count, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                // Return 0 if there's an error
                return Json(0, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        [AllowAnonymous]
        public string Ping()
        {
            return "Pong";
        }
    }
}