using System;
using System.Data.Entity;
using System.Linq;
using Connect2Us.Models;
using Connect2Us.Migrations;

namespace MigrationRunner
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Starting database migration and seeding...");
            
            try
            {
                // Initialize database with migrations and preserve seeded data
                Database.SetInitializer(new Connect2Us.Infrastructure.PreserveSeedDataInitializer());
                
                // Force database initialization
                using (var context = new ApplicationDbContext())
                {
                    Console.WriteLine("Initializing database...");
                    context.Database.Initialize(true);
                    
                    Console.WriteLine("Database migration completed successfully!");
                    Console.WriteLine();
                    
                    // Display database contents
                    Console.WriteLine("Database Contents:");
                    Console.WriteLine($"Admins: {context.Admins.Count()}");
                    Console.WriteLine($"Delivery Drivers: {context.DeliveryDrivers.Count()}");
                    Console.WriteLine($"Bookstores: {context.Bookstores.Count()}");
                    Console.WriteLine($"Customers: {context.Customers.Count()}");
                    Console.WriteLine($"Products: {context.Products.Count()}");
                    Console.WriteLine($"Categories: {context.Categories.Count()}");
                    Console.WriteLine($"BankCards: {context.BankCards.Count()}");
                    Console.WriteLine($"Wallets: {context.Wallets.Count()}");
                    Console.WriteLine($"Transactions: {context.Transactions.Count()}");
                    
                    Console.WriteLine();
                    Console.WriteLine("Sample Users Created:");
                    
                    // Show admin
                    var admin = context.Admins.FirstOrDefault();
                    if (admin != null)
                    {
                        Console.WriteLine($"Admin: {admin.User.Email} ({admin.User.FirstName} {admin.User.LastName})");
                    }
                    
                    // Show delivery drivers
                    var drivers = context.DeliveryDrivers.Take(3).ToList();
                    Console.WriteLine("Delivery Drivers:");
                    foreach (var driver in drivers)
                    {
                        Console.WriteLine($"  - {driver.User.Email} ({driver.User.FirstName} {driver.User.LastName})");
                    }
                    
                    // Show bookstores
                    var bookstores = context.Bookstores.Take(3).ToList();
                    Console.WriteLine("Bookstores:");
                    foreach (var bookstore in bookstores)
                    {
                        Console.WriteLine($"  - {bookstore.User.Email} ({bookstore.Name})");
                    }
                    
                    // Show customers
                    var customers = context.Customers.Take(3).ToList();
                    Console.WriteLine("Customers:");
                    foreach (var customer in customers)
                    {
                        Console.WriteLine($"  - {customer.User.Email} ({customer.FirstName} {customer.LastName})");
                    }
                    
                    // Show sample products
                    var products = context.Products.Take(5).ToList();
                    Console.WriteLine("Sample Products:");
                    foreach (var product in products)
                    {
                        Console.WriteLine($"  - {product.Name} (${product.Price}) - {product.Category.Name}");
                    }
                }
                
                Console.WriteLine();
                Console.WriteLine("Migration and seeding completed successfully!");
                Console.WriteLine("Press any key to exit...");
                Console.ReadKey();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error during migration: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                Console.WriteLine("Press any key to exit...");
                Console.ReadKey();
            }
        }
    }
}
