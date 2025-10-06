using System;
using System.Linq;
using Connect2Us.Models;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;

namespace Connect2Us.UpdateDrivers
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Updating delivery drivers to be available...");
            
            using (var db = new ApplicationDbContext())
            {
                var drivers = db.DeliveryDrivers.ToList();
                
                foreach (var driver in drivers)
                {
                    driver.IsAvailable = true;
                    Console.WriteLine($"Updated driver {driver.UserId} to available");
                }
                
                db.SaveChanges();
                Console.WriteLine($"Updated {drivers.Count} delivery drivers to be available.");
            }
            
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }
    }
}