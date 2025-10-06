using System;
using System.Linq;
using System.Web.Mvc;

using System.Data.Entity;
using System.Threading.Tasks;
using Connect2Us.Models;

namespace Connect2Us.Controllers
{
    [Authorize(Roles = "Admin")]
    public class BookstoreManagementController : Controller
    {
        private ApplicationDbContext db = new ApplicationDbContext();

        // GET: Admin/EditBookstore/5
        public ActionResult EditBookstore(string id)
        {
            var bookstore = db.Bookstores.Find(id);
            if (bookstore == null)
            {
                return HttpNotFound();
            }

            var viewModel = new BookstoreEditViewModel
            {
                UserId = bookstore.UserId,
                Name = bookstore.Name,
                Description = bookstore.Description,
                Address = bookstore.Address,
                ContactNumber = bookstore.ContactNumber
            };

            return View(viewModel);
        }

        // POST: Admin/EditBookstore/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> EditBookstore(BookstoreEditViewModel viewModel)
        {
            if (ModelState.IsValid)
            {
                var bookstore = await db.Bookstores.FindAsync(viewModel.UserId);
                if (bookstore == null)
                {
                    return HttpNotFound();
                }

                bookstore.Name = viewModel.Name;
                bookstore.Description = viewModel.Description;
                bookstore.Address = viewModel.Address;
                bookstore.ContactNumber = viewModel.ContactNumber;

                db.Entry(bookstore).State = EntityState.Modified;
                await db.SaveChangesAsync();
                return RedirectToAction("Bookstores", "Admin");
            }
            return View(viewModel);
        }

        // GET: Admin/DeleteBookstore/5
        public async Task<ActionResult> DeleteBookstore(string id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            }
            Bookstore bookstore = await db.Bookstores.FindAsync(id);
            if (bookstore == null)
            {
                return HttpNotFound();
            }
            return View(bookstore);
        }

        // POST: Admin/DeleteBookstore/5
        [HttpPost, ActionName("DeleteBookstore")]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> DeleteConfirmed(string id)
        {
            Bookstore bookstore = await db.Bookstores.FindAsync(id);
            db.Bookstores.Remove(bookstore);
            await db.SaveChangesAsync();
            return RedirectToAction("Bookstores", "Admin");
        }

        // GET: /BookstoreManagement/Bookstores
        public ActionResult Bookstores()
        {
            var bookstores = db.Bookstores.Include(b => b.User).ToList();
            return View("~/Views/Admin/Bookstores.cshtml", bookstores);
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