using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Mvc;
using System.Web;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.Owin;
using Connect2Us.ViewModels;
using Connect2Us.Models;

namespace Connect2Us.Controllers
{
    [Authorize]
    public class ProfileController : Controller
    {
        private ApplicationDbContext db = new ApplicationDbContext();
        private ApplicationUserManager _userManager;

        public ProfileController()
        {
        }

        public ProfileController(ApplicationUserManager userManager)
        {
            UserManager = userManager;
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

        // GET: Profile
        public async Task<ActionResult> Index()
        {
            var userId = User.Identity.GetUserId();
            var user = await UserManager.FindByIdAsync(userId);
            
            if (user == null)
            {
                return HttpNotFound();
            }

            var model = new ProfileViewModel
            {
                Id = user.Id,
                Email = user.Email,
                FirstName = user.FirstName,
                LastName = user.LastName,
                PhoneNumber = user.PhoneNumber,
                DateOfBirth = user.DateOfBirth,
                Address = user.Address,
                City = user.City,
                State = user.State,
                PostalCode = user.PostalCode,
                Country = user.Country
            };

            // Load user type specific data
            if (User.IsInRole("Bookstore"))
            {
                var bookstore = await db.Bookstores.FirstOrDefaultAsync(b => b.UserId == userId);
                if (bookstore != null)
                {
                    model.BookstoreName = bookstore.Name;
                    model.BookstoreDescription = bookstore.Description;
                }
            }
            else if (User.IsInRole("DeliveryDriver"))
            {
                var driver = await db.DeliveryDrivers.FirstOrDefaultAsync(d => d.UserId == userId);
                if (driver != null)
                {
                }
            }

            return View(model);
        }

        // GET: Profile/Edit
        public async Task<ActionResult> Edit()
        {
            var userId = User.Identity.GetUserId();
            var user = await UserManager.FindByIdAsync(userId);
            
            if (user == null)
            {
                return HttpNotFound();
            }

            var model = new ProfileViewModel
            {
                Id = user.Id,
                Email = user.Email,
                FirstName = user.FirstName,
                LastName = user.LastName,
                PhoneNumber = user.PhoneNumber,
                DateOfBirth = user.DateOfBirth,
                Address = user.Address,
                City = user.City,
                State = user.State,
                PostalCode = user.PostalCode,
                Country = user.Country
            };

            // Load user type specific data
            if (User.IsInRole("Bookstore"))
            {
                var bookstore = await db.Bookstores.FirstOrDefaultAsync(b => b.UserId == userId);
                if (bookstore != null)
                {
                    model.BookstoreName = bookstore.Name;
                    model.BookstoreDescription = bookstore.Description;
                }
            }
            else if (User.IsInRole("DeliveryDriver"))
            {
                var driver = await db.DeliveryDrivers.FirstOrDefaultAsync(d => d.UserId == userId);
                if (driver != null)
                {
                }
            }

            return View(model);
        }

        // POST: Profile/Edit
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> Edit(ProfileViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var userId = User.Identity.GetUserId();
            var user = await UserManager.FindByIdAsync(userId);
            
            if (user == null)
            {
                return HttpNotFound();
            }

            // Update basic user information
            user.FirstName = model.FirstName;
            user.LastName = model.LastName;
            user.PhoneNumber = model.PhoneNumber;
            user.DateOfBirth = model.DateOfBirth;
            user.Address = model.Address;
            user.City = model.City;
            user.State = model.State;
            user.PostalCode = model.PostalCode;
            user.Country = model.Country;

            var result = await UserManager.UpdateAsync(user);

            if (result.Succeeded)
            {
                // Update user type specific data
                if (User.IsInRole("Bookstore"))
                {
                    var bookstore = await db.Bookstores.FirstOrDefaultAsync(b => b.UserId == userId);
                    if (bookstore != null)
                    {
                        bookstore.Name = model.BookstoreName;
                        bookstore.Description = model.BookstoreDescription;
                        db.Entry(bookstore).State = EntityState.Modified;
                    }
                }
                else if (User.IsInRole("DeliveryDriver"))
                {
                    var driver = await db.DeliveryDrivers.FirstOrDefaultAsync(d => d.UserId == userId);
                    if (driver != null)
                    {
                        db.Entry(driver).State = EntityState.Modified;
                    }
                }

                await db.SaveChangesAsync();
                TempData["success"] = "Profile updated successfully!";
                return RedirectToAction("Index");
            }

            foreach (var error in result.Errors)
            {
                ModelState.AddModelError("", error);
            }

            return View(model);
        }

        // GET: Profile/ChangePassword
        public ActionResult ChangePassword()
        {
            return View();
        }

        // POST: Profile/ChangePassword
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> ChangePassword(ChangePasswordViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var userId = User.Identity.GetUserId();
            var result = await UserManager.ChangePasswordAsync(userId, model.OldPassword, model.NewPassword);
            
            if (result.Succeeded)
            {
                var user = await UserManager.FindByIdAsync(userId);
                if (user != null)
                {
                    await SignInManager.SignInAsync(user, isPersistent: false, rememberBrowser: false);
                }
                TempData["success"] = "Password changed successfully!";
                return RedirectToAction("Index");
            }

            foreach (var error in result.Errors)
            {
                ModelState.AddModelError("", error);
            }
            
            return View(model);
        }

        private ApplicationSignInManager _signInManager;
        public ApplicationSignInManager SignInManager
        {
            get
            {
                return _signInManager ?? HttpContext.GetOwinContext().Get<ApplicationSignInManager>();
            }
            private set { _signInManager = value; }
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
                if (db != null)
                {
                    db.Dispose();
                    db = null;
                }
            }
            base.Dispose(disposing);
        }
    }
}