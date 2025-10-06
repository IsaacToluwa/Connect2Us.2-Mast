using System;
using System.Linq;
using System.Web.Mvc;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;
using Connect2Us.Models;
using System.Data.Entity;
using System.Threading.Tasks;

namespace Connect2Us.Controllers
{
    [Authorize(Roles = "Admin")]
    public class UserManagementController : Controller
    {
        private ApplicationDbContext db = new ApplicationDbContext();
        private UserManager<ApplicationUser> userManager;
        private RoleManager<IdentityRole> roleManager;

        public UserManagementController()
        {
            userManager = new UserManager<ApplicationUser>(new UserStore<ApplicationUser>(db));
            roleManager = new RoleManager<IdentityRole>(new RoleStore<IdentityRole>(db));
        }

        // GET: UserManagement
        public ActionResult Users(string searchTerm = null, string role = null)
        {
            var users = db.Users.Include(u => u.Roles).ToList();

            if (!string.IsNullOrEmpty(searchTerm))
            {
                users = users.Where(u => u.UserName.Contains(searchTerm) || u.Email.Contains(searchTerm)).ToList();
            }

            if (!string.IsNullOrEmpty(role))
            {
                users = users.Where(u => userManager.IsInRole(u.Id, role)).ToList();
            }

            var roles = roleManager.Roles.Select(r => r.Name).ToList();

            var viewModel = new UsersViewModel
            {
                Users = users,
                Roles = roles,
                SelectedRole = role,
                SearchTerm = searchTerm
            };

            return View(viewModel);
        }

        // GET: UserManagement/UserDetails/5
        public ActionResult UserDetails(string id)
        {
            var user = userManager.FindById(id);
            if (user == null)
            {
                return HttpNotFound();
            }

            var userRoles = userManager.GetRoles(user.Id);
            var allRoles = roleManager.Roles.ToList();

            // Pass user role names to view via ViewBag
            ViewBag.UserRoleNames = userRoles;

            // Pass roles to view via ViewBag since view expects ApplicationUser directly
            ViewBag.Roles = allRoles.Select(r => new SelectListItem
            {
                Value = r.Name,
                Text = r.Name,
                Selected = userRoles.Contains(r.Name)
            });

            return View(user);
        }

        // POST: UserManagement/UpdateUserRole
        [HttpPost]
        public async Task<ActionResult> UpdateUserRole(string userId, string role)
        {
            var user = await userManager.FindByIdAsync(userId);
            if (user == null)
            {
                return HttpNotFound();
            }

            var userRoles = await userManager.GetRolesAsync(userId);
            await userManager.RemoveFromRolesAsync(userId, userRoles.ToArray());
            await userManager.AddToRoleAsync(userId, role);

            TempData["success"] = "User role updated successfully!";
            return RedirectToAction("UserDetails", new { id = userId });
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

    public class UsersViewModel
    {
        public System.Collections.Generic.List<ApplicationUser> Users { get; set; }
        public System.Collections.Generic.List<string> Roles { get; set; }
        public string SelectedRole { get; set; }
        public string SearchTerm { get; set; }
    }

    public class UserDetailsViewModel
    {
        public ApplicationUser User { get; set; }
        public System.Collections.Generic.IEnumerable<SelectListItem> Roles { get; set; }
    }
}