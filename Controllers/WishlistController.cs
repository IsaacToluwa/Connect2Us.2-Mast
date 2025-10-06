using System;
using Connect2Us.Models;
using Microsoft.AspNet.Identity;
using System.Linq;
using System.Web.Mvc;
using System.Data.Entity;

namespace Connect2Us.Controllers
{
    [Authorize(Roles = "Customer")]
    public class WishlistController : Controller
    {
        private readonly ApplicationDbContext _context;

        public WishlistController()
        {
            _context = new ApplicationDbContext();
        }

        // GET: Wishlist
        public ActionResult Index()
        {
            try
            {
                var userId = User.Identity.GetUserId();
                var wishlist = _context.Wishlists.Include("WishlistItems.Product").SingleOrDefault(w => w.UserId == userId);
                return View(wishlist);
            }
            catch (Exception)
            {
                TempData["error"] = "An error occurred while loading your wishlist. Please try again.";
                return View();
            }
        }

        // POST: Wishlist/AddToWishlist/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult AddToWishlist(int productId)
        {
            try
            {
                var userId = User.Identity.GetUserId();
                var wishlist = _context.Wishlists.SingleOrDefault(w => w.UserId == userId);

                if (wishlist == null)
                {
                    wishlist = new Wishlist { UserId = userId };
                    _context.Wishlists.Add(wishlist);
                    _context.SaveChanges(); // Save to get the wishlist ID
                }

                // Check if product exists
                var product = _context.Products.Find(productId);
                if (product == null)
                {
                    TempData["error"] = "Product not found.";
                    return RedirectToAction("Index", "Home");
                }

                var wishlistItemExists = _context.WishlistItems.Any(wi => wi.WishlistId == wishlist.Id && wi.ProductId == productId);

                if (!wishlistItemExists)
                {
                    var wishlistItem = new WishlistItem
                    {
                        WishlistId = wishlist.Id,
                        ProductId = productId
                    };

                    _context.WishlistItems.Add(wishlistItem);
                    _context.SaveChanges();
                    
                    TempData["success"] = product.Name + " added to wishlist successfully!";
                }
                else
                {
                    TempData["info"] = product.Name + " is already in your wishlist.";
                }

                return RedirectToAction("Index");
            }
            catch (Exception)
            {
                TempData["error"] = "An error occurred while adding the item to your wishlist. Please try again.";
                return RedirectToAction("Index", "Home");
            }
        }

        // POST: Wishlist/RemoveFromWishlist/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult RemoveFromWishlist(int productId)
        {
            try
            {
                var userId = User.Identity.GetUserId();
                var wishlist = _context.Wishlists.SingleOrDefault(w => w.UserId == userId);

                if (wishlist != null)
                {
                    var wishlistItem = _context.WishlistItems.SingleOrDefault(wi => wi.WishlistId == wishlist.Id && wi.ProductId == productId);

                    if (wishlistItem != null)
                    {
                        var product = _context.Products.Find(productId);
                        _context.WishlistItems.Remove(wishlistItem);
                        _context.SaveChanges();
                        
                        TempData["success"] = (product != null ? product.Name : "Item") + " removed from wishlist successfully!";
                    }
                    else
                    {
                        TempData["error"] = "Item not found in your wishlist.";
                    }
                }
                else
                {
                    TempData["error"] = "Your wishlist is empty.";
                }

                return RedirectToAction("Index");
            }
            catch (Exception)
            {
                TempData["error"] = "An error occurred while removing the item from your wishlist. Please try again.";
                return RedirectToAction("Index");
            }
        }

        // GET: Wishlist/GetWishlistItemCount
        [HttpGet]
        public JsonResult GetWishlistItemCount()
        {
            try
            {
                var userId = User.Identity.GetUserId();
                var wishlist = _context.Wishlists.Include("WishlistItems").SingleOrDefault(w => w.UserId == userId);
                var count = wishlist?.WishlistItems?.Count ?? 0;
                return Json(count, JsonRequestBehavior.AllowGet);
            }
            catch (Exception)
            {
                // Return 0 if there's an error
                return Json(0, JsonRequestBehavior.AllowGet);
            }
        }
    }
}