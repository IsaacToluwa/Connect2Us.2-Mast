using System;
using System.Linq;
using System.Web.Mvc;
using Connect2Us.Models;

namespace Connect2Us.Controllers
{
    public class DriverTestController : Controller
    {
        private readonly ApplicationDbContext db = new ApplicationDbContext();

        // GET: DriverTest/CheckDrivers
        public ActionResult CheckDrivers()
        {
            var allDrivers = db.DeliveryDrivers.ToList();
            var availableDrivers = db.DeliveryDrivers.Where(d => d.IsAvailable).ToList();
            
            ViewBag.TotalDrivers = allDrivers.Count;
            ViewBag.AvailableDrivers = availableDrivers.Count;
            ViewBag.AllDrivers = allDrivers;
            ViewBag.AvailableDriversList = availableDrivers;
            
            return View();
        }
        
        // GET: DriverTest/MakeAllAvailable
        public ActionResult MakeAllAvailable()
        {
            var drivers = db.DeliveryDrivers.ToList();
            foreach (var driver in drivers)
            {
                driver.IsAvailable = true;
            }
            db.SaveChanges();
            
            return RedirectToAction("CheckDrivers");
        }
    }
}