using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Mvc;
using Connect2Us.Models;

namespace Connect2Us.Controllers
{
    [Authorize(Roles = "Admin")]
    public class CategoryManagementController : Controller
    {
        private readonly ApplicationDbContext db = new ApplicationDbContext();

        // GET: Admin/Categories
        public ActionResult Categories()
        {
            var categories = db.Categories.ToList();
            return View(categories);
        }

        // POST: Admin/AddCategory
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> AddCategory(string categoryName)
        {
            if (!string.IsNullOrWhiteSpace(categoryName))
            {
                var category = new Category { Name = categoryName };
                db.Categories.Add(category);
                await db.SaveChangesAsync();
                TempData["success"] = "Category added successfully.";
            }
            else
            {
                TempData["error"] = "Category name cannot be empty.";
            }

            return RedirectToAction("Categories");
        }

        // POST: Admin/DeleteCategory
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> DeleteCategory(int categoryId)
        {
            var category = await db.Categories.FindAsync(categoryId);
            if (category != null)
            {
                db.Categories.Remove(category);
                await db.SaveChangesAsync();
                TempData["success"] = "Category deleted successfully.";
            }
            else
            {
                TempData["error"] = "Category not found.";
            }

            return RedirectToAction("Categories");
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