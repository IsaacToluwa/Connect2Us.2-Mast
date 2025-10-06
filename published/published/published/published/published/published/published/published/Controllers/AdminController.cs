using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;

using System.Data.Entity;
using Connect2Us.Models;
using System.Threading.Tasks;

namespace Connect2Us.Controllers
{
    [Authorize(Roles = "Admin")]
    public class AdminController : Controller
    {
        private ApplicationDbContext db = new ApplicationDbContext();
        private UserManager<ApplicationUser> userManager;
        private RoleManager<IdentityRole> roleManager;

        public AdminController()
        {
            userManager = new UserManager<ApplicationUser>(new UserStore<ApplicationUser>(db));
            roleManager = new RoleManager<IdentityRole>(new RoleStore<IdentityRole>(db));
        }

        // GET: Admin
        public ActionResult Index()
        {
            var roles = roleManager.Roles.ToList();
            var customerRoleId = roles.FirstOrDefault(r => r.Name == "Customer").Id;
            var deliveryDriverRoleId = roles.FirstOrDefault(r => r.Name == "DeliveryDriver").Id;

            var users = db.Users.OrderByDescending(u => u.CreatedAt).Take(10).ToList();

            var viewModel = new AdminDashboardViewModel
            {
                TotalUsers = db.Users.Count(),
                TotalBookstores = db.Bookstores.Count(),
                TotalCustomers = db.Users.Count(u => u.Roles.Any(r => r.RoleId == customerRoleId)),
                TotalDeliveryDrivers = db.Users.Count(u => u.Roles.Any(r => r.RoleId == deliveryDriverRoleId)),
                TotalOrders = db.Orders.Count(),
                TotalRevenue = db.Orders.Where(o => o.IsPaid).Sum(o => (decimal?)o.TotalAmount) ?? 0,
                PendingOrders = db.Orders.Count(o => o.Status == "Pending"),
                RecentOrders = db.Orders.Include(o => o.Customer.User).OrderByDescending(o => o.OrderDate).Take(10).ToList(),
                RecentUsers = users.Select(u => new RecentUser
                {
                    FirstName = u.FirstName,
                    LastName = u.LastName,
                    Email = u.Email,
                    UserType = u.Roles.FirstOrDefault() != null ? 
                        roles.FirstOrDefault(r => r.Id == u.Roles.FirstOrDefault().RoleId)?.Name : "Unknown",
                    CreatedAt = u.CreatedAt
                }).ToList()
            };
            return View(viewModel);
        }

        // GET: Admin/Reports
        public ActionResult Reports()
        {
            var currentMonth = DateTime.Now.Month;
            var currentYear = DateTime.Now.Year;

            var viewModel = new AdminReportsViewModel
            {
                TotalUsers = db.Users.Count(),
                TotalBookstores = db.Bookstores.Count(),
                TotalOrders = db.Orders.Count(),
                TotalRevenue = db.Orders.Where(o => o.IsPaid).Sum(o => (decimal?)o.TotalAmount) ?? 0,
                MonthlyRevenue = db.Orders
                    .Where(o => o.IsPaid && o.OrderDate.Month == currentMonth && o.OrderDate.Year == currentYear)
                    .Sum(o => (decimal?)o.TotalAmount) ?? 0,
                MonthlyOrders = db.Orders
                    .Where(o => o.OrderDate.Month == currentMonth && o.OrderDate.Year == currentYear)
                    .Count(),
                TopBookstores = db.Orders
                    .Where(o => o.IsPaid)
                    .GroupBy(o => o.Bookstore)
                    .Select(g => new TopBookstore { Bookstore = g.Key, Revenue = g.Sum(o => (decimal?)o.TotalAmount) ?? 0, Orders = g.Count() })
                    .OrderByDescending(b => b.Revenue)
                    .Take(5)
                    .ToList(),
                MonthlyOrdersByStatus = db.Orders
                    .Where(o => o.OrderDate.Month == currentMonth && o.OrderDate.Year == currentYear)
                    .GroupBy(o => o.Status)
                    .Select(g => new OrdersByStatus { Status = g.Key, Count = g.Count() })
                    .ToList()
            };

            return View(viewModel);
        }

        // GET: Admin/Bookstores
        [Authorize(Roles = "Admin, Bookstore")]
        public ActionResult Bookstores()
        {
            var bookstores = db.Bookstores.Include(b => b.User).ToList();
            return View(bookstores);
        }

        // GET: Admin/BookstoreDetails/5
        [Authorize(Roles = "Admin, Bookstore")]
        public ActionResult BookstoreDetails(string id)
        {
            var bookstore = db.Bookstores
                .Include(b => b.User)
                .Include(b => b.Products)
                .Include(b => b.Orders)
                .SingleOrDefault(b => b.UserId == id);

            if (bookstore == null)
            {
                return HttpNotFound();
            }

            var viewModel = new BookstoreDetailsViewModel
            {
                Bookstore = bookstore,
                TotalProducts = bookstore.Products.Count(),
                TotalOrders = bookstore.Orders.Count(),
                TotalRevenue = bookstore.Orders.Where(o => o.IsPaid).Sum(o => (decimal?)o.TotalAmount) ?? 0
            };

            return View(viewModel);
        }

        [HttpGet]
        public async Task<ActionResult> EditUser(string id)
        {
            var user = await userManager.FindByIdAsync(id);
            if (user == null)
            {
                return HttpNotFound();
            }

            var userRoles = await userManager.GetRolesAsync(id);

            var model = new UserEditViewModel
            {
                Id = user.Id,
                Email = user.Email,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Roles = userRoles
            };

            ViewBag.RolesList = new SelectList(roleManager.Roles.Select(r => r.Name).ToList());
            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> EditUser(UserEditViewModel model)
        {
            if (ModelState.IsValid)
            {
                var user = await userManager.FindByIdAsync(model.Id);
                if (user == null)
                {
                    return HttpNotFound();
                }

                user.Email = model.Email;
                user.FirstName = model.FirstName;
                user.LastName = model.LastName;

                var result = await userManager.UpdateAsync(user);

                if (result.Succeeded)
                {
                    var userRoles = await userManager.GetRolesAsync(user.Id);
                    if (model.NewRole != null && !userRoles.Contains(model.NewRole))
                    {
                        await userManager.AddToRoleAsync(user.Id, model.NewRole);
                    }
                    return RedirectToAction("Users");
                }
                AddErrors(result);
            }
            ViewBag.RolesList = new SelectList(roleManager.Roles.Select(r => r.Name).ToList());
            return View(model);
        }

        [HttpGet]
        public ActionResult CreateUser()
        {
            ViewBag.UserRole = new SelectList(roleManager.Roles.Select(r => r.Name).ToList());
            return View(new UserCreateViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> CreateUser(UserCreateViewModel model)
        {
            if (ModelState.IsValid)
            {
                var user = new ApplicationUser { UserName = model.Email, Email = model.Email };
                var result = await userManager.CreateAsync(user, model.Password);
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(user.Id, model.UserRole);
                    return RedirectToAction("Users");
                }
                AddErrors(result);
            }

            ViewBag.UserRole = new SelectList(roleManager.Roles.Select(r => r.Name).ToList());
            return View(model);
        }

        private void AddErrors(IdentityResult result)
        {
            foreach (var error in result.Errors)
            {
                ModelState.AddModelError("", error);
            }
        }

        public ActionResult Users()
        {
            var users = db.Users.ToList();
            var viewModel = new UserListViewModel
            {
                Users = users
            };
            return View(viewModel);
        }

        // GET: Admin/Orders
        public ActionResult Orders(string status, string search)
        {
            var ordersQuery = db.Orders
                .Include(o => o.Customer.User)
                .Include(o => o.Bookstore)
                .AsQueryable();

            // Apply status filter if provided
            if (!string.IsNullOrEmpty(status) && status != "All Statuses")
            {
                ordersQuery = ordersQuery.Where(o => o.Status == status);
            }

            // Apply search filter if provided
            if (!string.IsNullOrEmpty(search))
            {
                ordersQuery = ordersQuery.Where(o => 
                    o.Customer.User.UserName.Contains(search) ||
                    o.Bookstore.Name.Contains(search) ||
                    o.Id.ToString().Contains(search));
            }

            var orders = ordersQuery.OrderByDescending(o => o.OrderDate).ToList();

            var viewModel = new OrdersViewModel
            {
                Orders = orders,
                SelectedStatus = status,
                SearchTerm = search
            };

            return View(viewModel);
        }

        // GET: Admin/Categories
        public ActionResult Categories()
        {
            var categories = db.Categories.Include(c => c.Products).ToList();
            return View(categories);
        }

        // GET: Admin/EditCategory/5
        public ActionResult EditCategory(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            }

            Category category = db.Categories.Find(id);
            if (category == null)
            {
                return HttpNotFound();
            }

            return View(category);
        }

        // POST: Admin/EditCategory/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult EditCategory([Bind(Include = "Id,Name")] Category category)
        {
            if (ModelState.IsValid)
            {
                db.Entry(category).State = EntityState.Modified;
                db.SaveChanges();
                return RedirectToAction("Categories");
            }
            return View(category);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
                if (userManager != null)
                {
                    userManager.Dispose();
                }
                if (roleManager != null)
                {
                    roleManager.Dispose();
                }
            }
            base.Dispose(disposing);
        }
    }
}