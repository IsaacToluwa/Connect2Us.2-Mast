using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.Owin;
using Microsoft.Owin.Security;
using Connect2Us.Models;
using System.Data.Entity;
using System.Net.Mail;
using System.Data.Entity.Validation;

namespace Connect2Us.Controllers
{
    [Authorize]
    public class AccountController : Controller
    {
        private ApplicationSignInManager _signInManager;
        private ApplicationUserManager _userManager;

        public AccountController()
        {
        }

        public AccountController(ApplicationUserManager userManager, ApplicationSignInManager signInManager)
        {
            UserManager = userManager;
            SignInManager = signInManager;
        }

        public ApplicationSignInManager SignInManager
        {
            get
            {
                return _signInManager ?? HttpContext.GetOwinContext().Get<ApplicationSignInManager>();
            }
            private set
            {
                _signInManager = value;
            }
        }

        public ApplicationUserManager UserManager
        {
            get
            {
                return _userManager ?? HttpContext.GetOwinContext().GetUserManager<ApplicationUserManager>();
            }
            private set
            {
                _userManager = value;
            }
        }

        // GET: /Account/Login
        [AllowAnonymous]
        public ActionResult Login(string returnUrl)
        {
            ViewBag.ReturnUrl = returnUrl;
            return View();
        }

        // POST: /Account/Login
        [HttpPost]
        [AllowAnonymous]
        //[ValidateAntiForgeryToken]
        public async Task<ActionResult> Login(LoginViewModel model, string returnUrl)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return View(model);
                }

                var result = await SignInManager.PasswordSignInAsync(model.Email, model.Password, model.RememberMe, shouldLockout: false);
                switch (result)
                {
                    case SignInStatus.Success:
                        var user = await UserManager.FindByEmailAsync(model.Email);
                        if (user != null)
                        {
                            TempData["success"] = "Login successful! Welcome back.";
                            
                            // Redirect based on user type
                            switch (user.UserType)
                            {
                                case "Admin":
                                    return RedirectToAction("Index", "Admin");
                                case "Bookstore":
                                    return RedirectToAction("Index", "Bookstore");
                                case "Customer":
                                    return RedirectToAction("Index", "Customer");
                                case "DeliveryDriver":
                                    return RedirectToAction("Index", "DeliveryDriver");
                                default:
                                    return RedirectToLocal(returnUrl);
                            }
                        }
                        return RedirectToLocal(returnUrl);
                    case SignInStatus.LockedOut:
                        TempData["error"] = "Your account has been locked out. Please contact support.";
                        return View("Lockout");
                    case SignInStatus.RequiresVerification:
                        return RedirectToAction("SendCode", new { ReturnUrl = returnUrl, RememberMe = model.RememberMe });
                    case SignInStatus.Failure:
                    default:
                        TempData["error"] = "Invalid email or password. Please try again.";
                        ModelState.AddModelError("", "Invalid login attempt.");
                        return View(model);
                }
            }
            catch (Exception ex)
            {
                TempData["error"] = "An error occurred during login. Please try again.";
                return View(model);
            }
        }

        // GET: /Account/Register
        [AllowAnonymous]
        public ActionResult Register()
        {
            ViewBag.UserType = new SelectList(new[]
            {
                new { Value = "Customer", Text = "Customer" },
                new { Value = "Bookstore", Text = "Bookstore" },
                new { Value = "DeliveryDriver", Text = "Delivery Driver" }
            }, "Value", "Text");
            return View();
        }

        // POST: /Account/Register
        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> Register(RegisterViewModel model)
        {
            if (ModelState.IsValid)
            {
                var user = new ApplicationUser
                {
                    UserName = model.Email,
                    Email = model.Email,
                    FirstName = model.FirstName,
                    LastName = model.LastName,
                    Phone = model.Phone,
                    UserType = model.UserType,
                    CreatedAt = DateTime.Now,
                    IsActive = true
                };

                var result = await UserManager.CreateAsync(user, model.Password);

                if (result.Succeeded)
                {
                    await UserManager.AddToRoleAsync(user.Id, model.UserType);

                    using (var db = new ApplicationDbContext())
                    {
                        switch (model.UserType)
                        {
                            case "Bookstore":
                                var bookstore = new Bookstore
                                {
                                    UserId = user.Id,
                                    Name = model.BusinessName,
                                    Description = model.Description,
                                    Address = model.Address,
                                    ContactNumber = model.Phone
                                };
                                db.Bookstores.Add(bookstore);
                                break;
                            case "DeliveryDriver":
                                var driver = new DeliveryDriver
                                {
                                    UserId = user.Id,
                                    LicenseNumber = model.LicenseNumber,
                                    VehicleType = model.VehicleType,
                                    VehicleRegistration = model.VehicleRegistration
                                };
                                db.DeliveryDrivers.Add(driver);
                                break;
                            default: // Customer
                                var customer = new Customer
                                {
                                    UserId = user.Id,
                                    FirstName = model.FirstName,
                                    LastName = model.LastName,
                                    Address = model.Address,
                                    CreatedAt = DateTime.Now
                                };
                                db.Customers.Add(customer);
                                break;
                        }

                        var wallet = new Wallet
                        {
                            UserId = user.Id,
                            Balance = 0,
                        };
                        db.Wallets.Add(wallet);

                        await db.SaveChangesAsync();
                    }

                    await SignInManager.SignInAsync(user, isPersistent: false, rememberBrowser: false);

                    return RedirectToAction("Index", "Home");
                }
                AddErrors(result);
            }

            // If we got this far, something failed, redisplay form
            ViewBag.UserType = new SelectList(new[]
            {
                new { Value = "Customer", Text = "Customer" },
                new { Value = "Bookstore", Text = "Bookstore" },
                new { Value = "DeliveryDriver", Text = "Delivery Driver" }
            }, "Value", "Text", model.UserType);
            return View(model);
        }

        // GET: /Account/ForgotPassword
        [AllowAnonymous]
        public ActionResult ForgotPassword()
        {
            return View();
        }

        // POST: /Account/ForgotPassword
        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> ForgotPassword(ForgotPasswordViewModel model)
        {
            if (ModelState.IsValid)
            {
                var user = await UserManager.FindByEmailAsync(model.Email);
                if (user != null && (await UserManager.IsEmailConfirmedAsync(user.Id)))
                {
                    string code = await UserManager.GeneratePasswordResetTokenAsync(user.Id);
                    var callbackUrl = Url.Action("ResetPassword", "Account", new { userId = user.Id, code = code }, protocol: Request.Url.Scheme);
                    await SendEmailAsync(user.Email, "Reset Password", 
                        "Please reset your password by clicking <a href='" + callbackUrl + "'>here</a>.");
                }
                return View("ForgotPasswordConfirmation");
            }

            return View(model);
        }

        // GET: /Account/ForgotPasswordConfirmation
        [AllowAnonymous]
        public ActionResult ForgotPasswordConfirmation()
        {
            return View();
        }

        // GET: /Account/ResetPassword
        [AllowAnonymous]
        public ActionResult ResetPassword(string code)
        {
            return code == null ? View("Error") : View();
        }

        // POST: /Account/ResetPassword
        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> ResetPassword(ResetPasswordViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }
            var user = await UserManager.FindByEmailAsync(model.Email);
            if (user == null)
            {
                // Don't reveal that the user does not exist
                return RedirectToAction("ResetPasswordConfirmation", "Account");
            }
            var result = await UserManager.ResetPasswordAsync(user.Id, model.Code, model.Password);
            if (result.Succeeded)
            {
                return RedirectToAction("ResetPasswordConfirmation", "Account");
            }
            AddErrors(result);
            return View();
        }

        // GET: /Account/ResetPasswordConfirmation
        [AllowAnonymous]
        public ActionResult ResetPasswordConfirmation()
        {
            return View();
        }

        // POST: /Account/LogOff
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult LogOff()
        {
            AuthenticationManager.SignOut(DefaultAuthenticationTypes.ApplicationCookie);
            TempData["success"] = "You have been logged out successfully.";
            return RedirectToAction("Index", "Home");
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                if (_userManager != null)
                {
                    _userManager.Dispose();
                    _userManager = null;
                }

                if (_signInManager != null)
                {
                    _signInManager.Dispose();
                    _signInManager = null;
                }
            }

            base.Dispose(disposing);
        }

        #region Helpers
        private IAuthenticationManager AuthenticationManager
        {
            get
            {
                return HttpContext.GetOwinContext().Authentication;
            }
        }

        private void AddErrors(IdentityResult result)
        {
            foreach (var error in result.Errors)
            {
                System.Diagnostics.Trace.WriteLine("IdentityError: " + error);
                ModelState.AddModelError("", error);
            }
        }

        private ActionResult RedirectToLocal(string returnUrl)
        {
            if (Url.IsLocalUrl(returnUrl))
            {
                return Redirect(returnUrl);
            }
            return RedirectToAction("Index", "Home");
        }

        private async Task SendEmailAsync(string email, string subject, string message)
        {
            try
            {
                var mailMessage = new MailMessage
                {
                    Subject = subject,
                    Body = message,
                    IsBodyHtml = true
                };
                mailMessage.To.Add(email);

                using (var smtpClient = new SmtpClient())
                {
                    await smtpClient.SendMailAsync(mailMessage);
                }
            }
            catch (Exception ex)
            {
                // Log the exception (you might want to add proper logging here)
                System.Diagnostics.Debug.WriteLine("Email sending failed: " + ex.Message);
                TempData["error"] = "Failed to send email. Please try again later.";
            }
        }
        #endregion
    }
}