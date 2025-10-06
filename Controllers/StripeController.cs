using Connect2Us.Models;
using Microsoft.AspNet.Identity;
using Stripe;
using Stripe.Checkout;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;

namespace Connect2Us.Controllers
{
    [Authorize]
    public class StripeController : Controller
    {
        private readonly ApplicationDbContext _context = new ApplicationDbContext();

        public ActionResult Index()
        {
            return View();
        }

        public ActionResult CreateCheckoutSession()
        {
            try
            {
                var userId = User.Identity.GetUserId();
                var cart = _context.Carts.Include("CartItems.Product").SingleOrDefault(c => c.UserId == userId);

                if (cart == null || !cart.CartItems.Any())
                {
                    TempData["error"] = "Your cart is empty.";
                    return RedirectToAction("Index", "Cart");
                }

                // Validate cart items
                foreach (var item in cart.CartItems)
                {
                    if (item.Product == null)
                    {
                        TempData["error"] = "Invalid product in cart. Please remove it and try again.";
                        return RedirectToAction("Index", "Cart");
                    }
                    
                    if (item.Quantity <= 0)
                    {
                        TempData["error"] = "Invalid quantity in cart. Please update your cart.";
                        return RedirectToAction("Index", "Cart");
                    }
                }

                var lineItems = new List<SessionLineItemOptions>();
                foreach (var item in cart.CartItems)
                {
                    lineItems.Add(new SessionLineItemOptions
                    {
                        PriceData = new SessionLineItemPriceDataOptions
                        {
                            UnitAmount = (long)(item.Product.Price * 100), // Amount in cents
                            Currency = "usd",
                            ProductData = new SessionLineItemPriceDataProductDataOptions
                            {
                                Name = item.Product.Name,
                            },
                        },
                        Quantity = item.Quantity,
                    });
                }

                var options = new SessionCreateOptions
                {
                    PaymentMethodTypes = new List<string>
                    {
                        "card",
                    },
                    LineItems = lineItems,
                    Mode = "payment",
                    SuccessUrl = Url.Action("Success", "Stripe", null, Request.Url.Scheme) + "?session_id={CHECKOUT_SESSION_ID}",
                    CancelUrl = Url.Action("Error", "Stripe", null, Request.Url.Scheme),
                };

                var service = new SessionService();
                Session session = service.Create(options);

                return Redirect(session.Url);
            }
            catch (StripeException ex)
            {
                TempData["error"] = "Payment service error: " + ex.Message;
                return RedirectToAction("Index", "Cart");
            }
            catch (Exception)
            {
                TempData["error"] = "An error occurred while creating the checkout session. Please try again.";
                return RedirectToAction("Index", "Cart");
            }
        }

        public ActionResult Success(string session_id)
        {
            try
            {
                if (string.IsNullOrEmpty(session_id))
                {
                    TempData["error"] = "Invalid payment session.";
                    return RedirectToAction("Error", "Stripe");
                }

                var sessionService = new SessionService();
                Session session = sessionService.Get(session_id);

                if (session == null)
                {
                    TempData["error"] = "Payment session not found.";
                    return RedirectToAction("Error", "Stripe");
                }

                if (session.PaymentStatus != "paid")
                {
                    TempData["error"] = "Payment was not successful.";
                    return RedirectToAction("Error", "Stripe");
                }

                var userId = User.Identity.GetUserId();
                var cart = _context.Carts.Include("CartItems.Product").SingleOrDefault(c => c.UserId == userId);

                if (cart != null && cart.CartItems.Any())
                {
                    var order = new Order
                    {
                        UserId = userId,
                        OrderDate = DateTime.Now,
                        TotalAmount = (decimal)session.AmountTotal / 100,
                        Status = "Paid",
                        IsPaid = true,
                        OrderItems = cart.CartItems.Select(ci => new OrderItem
                        {
                            ProductId = ci.ProductId,
                            Quantity = ci.Quantity,
                            Price = ci.Product.Price
                        }).ToList()
                    };

                    _context.Orders.Add(order);
                    _context.CartItems.RemoveRange(cart.CartItems);
                    _context.SaveChanges();

                    TempData["success"] = "Payment successful! Your order has been placed.";
                }
                else
                {
                    TempData["info"] = "Payment successful, but no items were found in your cart.";
                }

                return View();
            }
            catch (StripeException ex)
            {
                TempData["error"] = "Payment verification error: " + ex.Message;
                return RedirectToAction("Error", "Stripe");
            }
            catch (Exception)
            {
                TempData["error"] = "An error occurred while processing your payment. Please contact support if you were charged.";
                return RedirectToAction("Error", "Stripe");
            }
        }

        public ActionResult Error()
        {
            try
            {
                // Only set error message if one isn't already set
                if (TempData["error"] == null)
                {
                    TempData["error"] = "Payment failed. Please try again.";
                }
                return View();
            }
            catch (Exception)
            {
                // If there's an error even displaying the error page, log it and show a generic message
                TempData["error"] = "An unexpected error occurred. Please try again later.";
                return View();
            }
        }
    }
}