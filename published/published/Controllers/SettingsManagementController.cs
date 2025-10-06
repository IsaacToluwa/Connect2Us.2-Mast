using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Mvc;
using Connect2Us.Models;

namespace Connect2Us.Controllers
{
    [Authorize(Roles = "Admin")]
    public class SettingsManagementController : Controller
    {
        private readonly ApplicationDbContext db = new ApplicationDbContext();

        // GET: Admin/Settings
        public ActionResult Settings()
        {
            var settings = db.SystemSettings.FirstOrDefault();
            if (settings == null)
            {
                settings = new SystemSettings();
            }
            return View(settings);
        }

        // POST: Admin/Settings
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> Settings(SystemSettings model)
        {
            if (ModelState.IsValid)
            {
                var settings = await db.SystemSettings.FirstOrDefaultAsync();
                if (settings == null)
                {
                    db.SystemSettings.Add(model);
                }
                else
                {
                    settings.SiteName = model.SiteName;
                    settings.SiteLogo = model.SiteLogo;
                    settings.ContactEmail = model.ContactEmail;
                    db.Entry(settings).State = EntityState.Modified;
                }
                await db.SaveChangesAsync();
                TempData["success"] = "Settings updated successfully.";
                return RedirectToAction("Settings");
            }
            TempData["error"] = "Failed to update settings.";
            return View(model);
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