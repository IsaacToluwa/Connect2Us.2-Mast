using System;
using System.Data.Entity;
using System.Data.Entity.Migrations;
using System.Linq;
using Connect2Us.Models;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;

namespace Connect2Us.Infrastructure
{
    /// <summary>
    /// Custom database initializer that preserves seeded data while allowing schema changes.
    /// This ensures that critical seeded data (roles, admin, categories) is never lost.
    /// </summary>
    public class PreserveSeedDataInitializer : MigrateDatabaseToLatestVersion<ApplicationDbContext, Connect2Us.Migrations.Configuration>
    {
        public override void InitializeDatabase(ApplicationDbContext context)
        {
            // First, run the migrations to update schema
            base.InitializeDatabase(context);
            
            // Then ensure critical data is preserved
            EnsureCriticalData(context);
        }
        
        private void EnsureCriticalData(ApplicationDbContext context)
        {
            // Ensure critical roles exist
            EnsureCriticalRoles(context);
            
            // Ensure admin user exists
            EnsureAdminUser(context);
            
            // Ensure critical categories exist
            EnsureCriticalCategories(context);
            
            // Ensure at least some sample data exists
            EnsureMinimumSampleData(context);
        }
        
        private void EnsureCriticalRoles(ApplicationDbContext context)
        {
            var criticalRoles = new[] { "Admin", "Bookstore", "Customer", "DeliveryDriver" };
            var roleStore = new RoleStore<IdentityRole>(context);
            var roleManager = new RoleManager<IdentityRole>(roleStore);
            
            foreach (var roleName in criticalRoles)
            {
                if (!roleManager.RoleExists(roleName))
                {
                    roleManager.Create(new IdentityRole(roleName));
                }
            }
        }
        
        private void EnsureAdminUser(ApplicationDbContext context)
        {
            if (!context.Users.Any(u => u.Email == "admin@example.com"))
            {
                var adminUser = new ApplicationUser
                {
                    UserName = "admin@example.com",
                    Email = "admin@example.com",
                    EmailConfirmed = true,
                    FirstName = "System",
                    LastName = "Administrator",
                    PhoneNumber = "1234567890",
                    PhoneNumberConfirmed = true
                };
                
                var userStore = new UserStore<ApplicationUser>(context);
                var userManager = new UserManager<ApplicationUser>(userStore);
                var result = userManager.Create(adminUser, "Admin@123");
                
                if (result.Succeeded)
                {
                    userManager.AddToRole(adminUser.Id, "Admin");
                }
            }
        }
        
        private void EnsureCriticalCategories(ApplicationDbContext context)
        {
            var criticalCategories = new[] { "Fiction", "Non-Fiction", "Textbooks", "Stationery" };
            
            foreach (var categoryName in criticalCategories)
            {
                if (!context.Categories.Any(c => c.Name == categoryName))
                {
                    context.Categories.Add(new Category { Name = categoryName });
                }
            }
            
            context.SaveChanges();
        }
        
        private void EnsureMinimumSampleData(ApplicationDbContext context)
        {
            // Ensure at least one bookstore exists
            if (!context.Bookstores.Any())
            {
                var bookstoreUser = new ApplicationUser
                {
                    UserName = "samplebookstore@example.com",
                    Email = "samplebookstore@example.com",
                    EmailConfirmed = true,
                    FirstName = "Sample",
                    LastName = "Bookstore"
                };
                
                var userStore = new UserStore<ApplicationUser>(context);
                var userManager = new UserManager<ApplicationUser>(userStore);
                var result = userManager.Create(bookstoreUser, "Bookstore@123");
                
                if (result.Succeeded)
                {
                    userManager.AddToRole(bookstoreUser.Id, "Bookstore");
                    
                    var bookstore = new Bookstore
                    {
                        UserId = bookstoreUser.Id,
                        Name = "Sample Bookstore",
                        Address = "123 Sample Street",
                        ContactNumber = "1234567890",
                        Description = "Sample bookstore for demonstration"
                    };
                    
                    context.Bookstores.Add(bookstore);
                    context.SaveChanges();
                }
            }
            
            // Ensure at least one customer exists
            if (!context.Customers.Any())
            {
                var customerUser = new ApplicationUser
                {
                    UserName = "samplecustomer@example.com",
                    Email = "samplecustomer@example.com",
                    EmailConfirmed = true,
                    FirstName = "Sample",
                    LastName = "Customer"
                };
                
                var userStore = new UserStore<ApplicationUser>(context);
                var userManager = new UserManager<ApplicationUser>(userStore);
                var result = userManager.Create(customerUser, "Customer@123");
                
                if (result.Succeeded)
                {
                    userManager.AddToRole(customerUser.Id, "Customer");
                    
                    var customer = new Customer
                    {
                        UserId = customerUser.Id,
                        FirstName = "Sample",
                        LastName = "Customer",
                        Phone = "0987654321",
                        Address = "456 Sample Avenue",
                        CreatedAt = DateTime.Now
                    };
                    
                    context.Customers.Add(customer);
                    
                    // Create wallet for customer
                    var wallet = new Wallet
                    {
                        UserId = customerUser.Id,
                        Balance = 1000.00m
                    };
                    
                    context.Wallets.Add(wallet);
                    context.SaveChanges();
                }
            }
            
            // Ensure at least one product exists if we have categories and bookstores
            if (!context.Products.Any() && context.Categories.Any() && context.Bookstores.Any())
            {
                var firstCategory = context.Categories.FirstOrDefault();
                var firstBookstore = context.Bookstores.FirstOrDefault();
                
                if (firstCategory != null && firstBookstore != null)
                {
                    var sampleProduct = new Product
                    {
                        Name = "Sample Book",
                        CategoryId = firstCategory.Id,
                        Price = 19.99m,
                        StockQuantity = 10,
                        BookstoreId = firstBookstore.UserId,
                        ISBN = "978-1234567890",
                        Author = "Sample Author",
                        Publisher = "Sample Publisher",
                        ProductType = "Book",
                        ImageUrl = "https://via.placeholder.com/150"
                    };
                    
                    context.Products.Add(sampleProduct);
                    context.SaveChanges();
                }
            }
        }
    }
}