using Connect2Us.Models;
using Microsoft.AspNet.Identity;
using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Mvc;

namespace Connect2Us.Controllers
{
    [Authorize]
    public class ReservationsController : Controller
    {
        private readonly ApplicationDbContext _context = new ApplicationDbContext();

        // GET: Reservations
        public async Task<ActionResult> Index()
        {
            try
            {
                var userId = User.Identity.GetUserId();
                var reservations = await _context.Reservations
                    .Where(r => r.UserId == userId)
                    .Include(r => r.Product)
                    .ToListAsync();
                return View(reservations);
            }
            catch (Exception)
            {
                TempData["error"] = "An error occurred while loading your reservations. Please try again.";
                return View();
            }
        }

        // GET: Reservations/Create
        public async Task<ActionResult> Create(int? productId)
        {
            try
            {
                if (productId == null)
                {
                    TempData["error"] = "Product ID is required.";
                    return RedirectToAction("Index", "Home");
                }

                var product = await _context.Products.FindAsync(productId);
                if (product == null)
                {
                    TempData["error"] = "Product not found.";
                    return RedirectToAction("Index", "Home");
                }

                if (product.StockQuantity <= 0)
                {
                    TempData["error"] = "This product is currently out of stock and cannot be reserved.";
                    return RedirectToAction("Index", "Home");
                }

                var viewModel = new Reservation
                {
                    ProductId = product.Id,
                    Product = product
                };

                return View(viewModel);
            }
            catch (Exception)
            {
                TempData["error"] = "An error occurred while loading the reservation form. Please try again.";
                return RedirectToAction("Index", "Home");
            }
        }

        // POST: Reservations/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> Create(int productId, DateTime reservationDate)
        {
            try
            {
                var userId = User.Identity.GetUserId();
                var product = await _context.Products.FindAsync(productId);

                if (product == null || product.StockQuantity <= 0)
                {
                    TempData["error"] = "Product is not available for reservation.";
                    return RedirectToAction("Index", "Home");
                }

                // Validate reservation date
                if (reservationDate < DateTime.Today)
                {
                    TempData["error"] = "Reservation date cannot be in the past.";
                    return RedirectToAction("Create", new { productId = productId });
                }

                // Check if user already has a reservation for this product
                var existingReservation = await _context.Reservations
                    .FirstOrDefaultAsync(r => r.UserId == userId && r.ProductId == productId && r.Status == "Reserved");
                
                if (existingReservation != null)
                {
                    TempData["error"] = "You already have a reservation for this product.";
                    return RedirectToAction("Index");
                }

                var reservation = new Reservation
                {
                    UserId = userId,
                    ProductId = productId,
                    ReservationDate = reservationDate,
                    Status = "Reserved"
                };

                _context.Reservations.Add(reservation);
                product.StockQuantity--;

                await _context.SaveChangesAsync();

                TempData["success"] = product.Name + " reserved successfully for " + reservationDate.ToString("MMMM dd, yyyy") + "!";
                return RedirectToAction("Index");
            }
            catch (Exception)
            {
                TempData["error"] = "An error occurred while creating your reservation. Please try again.";
                return RedirectToAction("Create", new { productId = productId });
            }
        }

        // POST: Reservations/Cancel/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> Cancel(int id)
        {
            try
            {
                var reservation = await _context.Reservations.FindAsync(id);
                if (reservation == null)
                {
                    TempData["error"] = "Reservation not found.";
                    return RedirectToAction("Index");
                }

                var userId = User.Identity.GetUserId();
                if (reservation.UserId != userId)
                {
                    TempData["error"] = "You can only cancel your own reservations.";
                    return RedirectToAction("Index");
                }

                if (reservation.Status != "Reserved")
                {
                    TempData["error"] = "This reservation cannot be cancelled.";
                    return RedirectToAction("Index");
                }

                reservation.Status = "Cancelled";
                var product = await _context.Products.FindAsync(reservation.ProductId);
                if (product != null)
                {
                    product.StockQuantity++;
                }

                await _context.SaveChangesAsync();

                TempData["success"] = "Reservation cancelled successfully.";
                return RedirectToAction("Index");
            }
            catch (Exception)
            {
                TempData["error"] = "An error occurred while cancelling your reservation. Please try again.";
                return RedirectToAction("Index");
            }
        }

        // GET: Reservations/GetReservationCount
        [HttpGet]
        public async Task<JsonResult> GetReservationCount()
        {
            try
            {
                var userId = User.Identity.GetUserId();
                var count = await _context.Reservations
                    .Where(r => r.UserId == userId && r.Status == "Reserved")
                    .CountAsync();
                return Json(count, JsonRequestBehavior.AllowGet);
            }
            catch (Exception)
            {
                return Json(0, JsonRequestBehavior.AllowGet);
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                _context.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}