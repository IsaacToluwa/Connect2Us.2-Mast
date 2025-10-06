namespace Connect2Us.Migrations
{
    using System;
    using System.Data.Entity;
    using System.Data.Entity.Migrations;
    using System.Linq;
    using Microsoft.AspNet.Identity;
    using Microsoft.AspNet.Identity.EntityFramework;
    using Connect2Us.Models;

    public sealed class Configuration : DbMigrationsConfiguration<Connect2Us.Models.ApplicationDbContext>
    {
        private class ProductSeedData
        {
            public string Name { get; set; }
            public string Category { get; set; }
            public decimal Price { get; set; }
            public string Type { get; set; }
            public string Author { get; set; }
            public string ISBN { get; set; }
        }

        public Configuration()
        {
            AutomaticMigrationsEnabled = true;
            ContextKey = "Connect2Us.Models.ApplicationDbContext";
        }

        protected override void Seed(Connect2Us.Models.ApplicationDbContext context)
        {
            string logPath = System.Web.Hosting.HostingEnvironment.IsHosted
                ? System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/seed_log.txt")
                : System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "seed_log.txt");
            
            System.IO.File.AppendAllText(logPath, $"=== Seed operation started at {DateTime.Now} ===\n");
            
            try
            {
                System.IO.File.AppendAllText(logPath, "Seeding roles...\n");
                SeedRoles(context);
                System.IO.File.AppendAllText(logPath, "Roles seeded.\n");

                System.IO.File.AppendAllText(logPath, "Seeding admin...\n");
                SeedAdmin(context);
                System.IO.File.AppendAllText(logPath, "Admin seeded.\n");

                System.IO.File.AppendAllText(logPath, "Seeding bookstores...\n");
                SeedBookstores(context);
                System.IO.File.AppendAllText(logPath, "Bookstores seeded.\n");

                System.IO.File.AppendAllText(logPath, "Seeding delivery drivers...\n");
                SeedDeliveryDrivers(context);
                System.IO.File.AppendAllText(logPath, "Delivery drivers seeded.\n");

                System.IO.File.AppendAllText(logPath, "Seeding customers...\n");
                SeedCustomers(context);
                System.IO.File.AppendAllText(logPath, "Customers seeded.\n");

                System.IO.File.AppendAllText(logPath, "Seeding categories...\n");
                SeedCategories(context);
                System.IO.File.AppendAllText(logPath, "Categories seeded.\n");

                System.IO.File.AppendAllText(logPath, "Seeding products...\n");
                SeedProducts(context);
                System.IO.File.AppendAllText(logPath, "Products seeded.\n");
                
                System.IO.File.AppendAllText(logPath, "Updating bookstore roles...\n");
                UpdateBookstoreRoles(context);
                System.IO.File.AppendAllText(logPath, "Bookstore roles updated.\n");
                
                System.IO.File.AppendAllText(logPath, "Protecting critical data...\n");
                ProtectCriticalData(context);
                System.IO.File.AppendAllText(logPath, "Critical data protected.\n");
                
                System.IO.File.AppendAllText(logPath, $"=== Seed operation completed successfully at {DateTime.Now} ===\n");
            }
            catch (Exception ex)
            {
                System.IO.File.AppendAllText(logPath, $"ERROR during seeding: {ex.Message}\n{ex.StackTrace}\n");
                throw;
            }
        }

        private void SeedRoles(ApplicationDbContext context)
        {
            var roleManager = new RoleManager<IdentityRole>(new RoleStore<IdentityRole>(context));
            
            string[] roles = { "Admin", "Bookstore", "Customer", "DeliveryDriver" };
            
            foreach (var role in roles)
            {
                if (!roleManager.RoleExists(role))
                {
                    roleManager.Create(new IdentityRole(role));
                }
            }
            
            // Remove old BookstoreOwner role if it exists
            if (roleManager.RoleExists("BookstoreOwner"))
            {
                var oldRole = roleManager.FindByName("BookstoreOwner");
                roleManager.Delete(oldRole);
            }
        }

        private void SeedAdmin(ApplicationDbContext context)
        {
            var userManager = new UserManager<ApplicationUser>(new UserStore<ApplicationUser>(context));
            var roleManager = new RoleManager<IdentityRole>(new RoleStore<IdentityRole>(context));
            
            var adminEmail = "olatunjitoluwanimi90@yahoo.com";
            var adminUser = userManager.FindByEmail(adminEmail);
            
            if (adminUser == null)
            {
                adminUser = new ApplicationUser
                {
                    UserName = adminEmail,
                    Email = adminEmail,
                    FirstName = "Admin",
                    LastName = "User",
                    CreatedAt = DateTime.Now,
                    IsActive = true,
                    UserType = "Admin"
                };
                
                var result = userManager.Create(adminUser, "Admin@123");
                
                if (result.Succeeded)
                {
                    userManager.AddToRole(adminUser.Id, "Admin");
                    context.SaveChanges(); // Save user and role assignment

                    var admin = new Admin
                    {
                        UserId = adminUser.Id,
                    };
                    
                    context.Admins.Add(admin);
                    context.SaveChanges(); // Save the admin-specific record
                }
            }
        }

        private void SeedBookstores(ApplicationDbContext context)
        {
            var userManager = new UserManager<ApplicationUser>(new UserStore<ApplicationUser>(context));
            var bookstoreEmails = new[]
            {
                "22435296@dut4life.ac.za",
                "22452586@dut4life.ac.za",
                "22415493@dut4life.ac.za",
                "22461594@dut4life.ac.za",
                "22379592@dut4life.ac.za"
            };
            
            string[] bookstoreNames = {
                "The Book Nook",
                "Page Turners",
                "Literary Haven",
                "Reading Rainbow",
                "Bookworm's Paradise"
            };
            
            for (int i = 0; i < bookstoreEmails.Length; i++)
            {
                var email = bookstoreEmails[i];
                var existingUser = userManager.FindByEmail(email);
                
                if (existingUser == null)
                {
                    var user = new ApplicationUser
                    {
                        UserName = email,
                        Email = email,
                        FirstName = bookstoreNames[i].Split(' ')[0],
                        LastName = bookstoreNames[i].Split(' ').Length > 1 ? bookstoreNames[i].Split(' ')[1] : "Store",
                        CreatedAt = DateTime.Now,
                        IsActive = true,
                        UserType = "Bookstore"
                    };
                    
                    var result = userManager.Create(user, "Bookstore@123");
                    
                    if (result.Succeeded)
                    {
                        userManager.AddToRole(user.Id, "Bookstore");
                        
                        var bookstore = new Bookstore
                        {
                            UserId = user.Id,
                            Name = bookstoreNames[i],
                            Description = "Welcome to " + bookstoreNames[i] + ", your local bookstore with a wide selection of books and stationery.",
                        };
                        
                        context.Bookstores.Add(bookstore);
                    }
                }
            }
            
            context.SaveChanges();
        }

        private void SeedDeliveryDrivers(ApplicationDbContext context)
        {
            var userManager = new UserManager<ApplicationUser>(new UserStore<ApplicationUser>(context));
            var driverEmails = new[]
            {
                "22137151@dut4life.ac.za",
                "22494121@dut4life.ac.za",
                "22100018@dut4life.ac.za",
                "22149813@dut4life.ac.za",
                "22335096@dut4life.ac.za"
            };
            
            string[] firstNames = { "John", "Sarah", "Mike", "Lisa", "David" };
            string[] lastNames = { "Smith", "Johnson", "Brown", "Davis", "Wilson" };
            
            for (int i = 0; i < driverEmails.Length; i++)
            {
                var email = driverEmails[i];
                var existingUser = userManager.FindByEmail(email);
                
                if (existingUser == null)
                {
                    var user = new ApplicationUser
                    {
                        UserName = email,
                        Email = email,
                        FirstName = firstNames[i],
                        LastName = lastNames[i],
                        CreatedAt = DateTime.Now,
                        IsActive = true,
                        UserType = "DeliveryDriver"
                    };
                    
                    var result = userManager.Create(user, "Driver@123");
                    
                    if (result.Succeeded)
                    {
                        userManager.AddToRole(user.Id, "DeliveryDriver");
                        
                        var driver = new DeliveryDriver
                        {
                            UserId = user.Id,
                            IsAvailable = true
                        };
                        
                        context.DeliveryDrivers.Add(driver);
                    }
                }
            }
            
            context.SaveChanges();
        }

        private void SeedCustomers(ApplicationDbContext context)
        {
            var userManager = new UserManager<ApplicationUser>(new UserStore<ApplicationUser>(context));
            var customerEmails = new[]
            {
                "olatunjitoluwanimi90@gmail.com",
                "Owethutyran.20@gmail.com",
                "adammohamed70000@gmail.com",
                "zamaliyema13@gmail.com",
                "lwandiled181@gmail.com",
                "alolwami08@gmail.com",
                "dikokofrost@gmail.com"
            };
            
            string[] firstNames = { "Olatunji", "Owethu", "Adam", "Zama", "Lwandile", "Alolwami", "Diko" };
            string[] lastNames = { "Toluwanimi", "Tyran", "Mohamed", "Liyema", "Dlamini", "Mthethwa", "Frost" };
            
            for (int i = 0; i < customerEmails.Length; i++)
            {
                var email = customerEmails[i];
                var existingUser = userManager.FindByEmail(email);
                
                if (existingUser == null)
                {
                    var user = new ApplicationUser
                    {
                        UserName = email,
                        Email = email,
                        FirstName = firstNames[i],
                        LastName = lastNames[i],
                        CreatedAt = DateTime.Now,
                        IsActive = true,
                        UserType = "Customer"
                    };
                    
                    var result = userManager.Create(user, "Customer@123");
                    
                    if (result.Succeeded)
                    {
                        userManager.AddToRole(user.Id, "Customer");
                        
                        var customer = new Customer
                        {
                            UserId = user.Id,
                            FirstName = firstNames[i],
                            LastName = lastNames[i],
                            Phone = "031-" + (i + 1).ToString() + "00-9876",
                            CreatedAt = DateTime.Now
                        };
                        
                        context.Customers.Add(customer);
                        
                        var wallet = new Wallet
                        {
                            UserId = user.Id,
                            Balance = 1000.00m
                        };
                        
                        context.Wallets.Add(wallet);
                    }
                }
            }
            
            context.SaveChanges();
        }

        private void SeedCategories(ApplicationDbContext context)
        {
            var categories = new[]
            {
                new Category { Name = "Fiction", Description = "Novels and fictional stories", IsActive = true, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow },
                new Category { Name = "Non-Fiction", Description = "Educational and informational books", IsActive = true, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow },
                new Category { Name = "Textbooks", Description = "Academic and educational textbooks", IsActive = true, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow },
                new Category { Name = "Children's Books", Description = "Books for children and young readers", IsActive = true, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow },
                new Category { Name = "Stationery", Description = "Pens, pencils, paper and office supplies", IsActive = true, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow },
                new Category { Name = "Art Supplies", Description = "Art materials and creative supplies", IsActive = true, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow },
                new Category { Name = "Technology", Description = "Tech books and programming resources", IsActive = true, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow },
                new Category { Name = "Business", Description = "Business and entrepreneurship books", IsActive = true, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow }
            };
            
            foreach (var category in categories)
            {
                if (!context.Categories.Any(c => c.Name == category.Name))
                {
                    context.Categories.Add(category);
                }
            }
            
            context.SaveChanges();
        }

        private void ProtectCriticalData(ApplicationDbContext context)
        {
            // Ensure critical system roles always exist
            var criticalRoles = new[] { "Admin", "Bookstore", "Customer", "DeliveryDriver" };
            foreach (var roleName in criticalRoles)
            {
                if (!context.Roles.Any(r => r.Name == roleName))
                {
                    context.Roles.Add(new IdentityRole(roleName));
                }
            }
            
            // Ensure admin user always exists
            if (!context.Users.Any(u => u.Email == "admin@example.com"))
            {
                var adminUser = new ApplicationUser
                {
                    UserName = "admin@example.com",
                    Email = "admin@example.com",
                    EmailConfirmed = true,
                    FirstName = "System",
                    LastName = "Administrator"
                };
                
                var userStore = new UserStore<ApplicationUser>(context);
                var userManager = new UserManager<ApplicationUser>(userStore);
                userManager.Create(adminUser, "Admin@123");
                userManager.AddToRole(adminUser.Id, "Admin");
            }
            
            // Ensure critical categories always exist
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

        private void SeedProducts(ApplicationDbContext context)
        {
            var bookstores = context.Bookstores.ToList();
            var categories = context.Categories.ToList();
            
            var products = new ProductSeedData[]
            {
                new ProductSeedData { Name = "The Great Gatsby", Category = "Fiction", Price = 120.00m, Type = "Book", Author = "F. Scott Fitzgerald", ISBN = "978-0-7432-7356-5" },
                new ProductSeedData { Name = "To Kill a Mockingbird", Category = "Fiction", Price = 150.00m, Type = "Book", Author = "Harper Lee", ISBN = "978-0-06-112008-4" },
                new ProductSeedData { Name = "1984", Category = "Fiction", Price = 130.00m, Type = "Book", Author = "George Orwell", ISBN = "978-0-452-28423-4" },
                new ProductSeedData { Name = "Pride and Prejudice", Category = "Fiction", Price = 110.00m, Type = "Book", Author = "Jane Austen", ISBN = "978-0-14-143951-8" },
                new ProductSeedData { Name = "The Catcher in the Rye", Category = "Fiction", Price = 140.00m, Type = "Book", Author = "J.D. Salinger", ISBN = "978-0-316-76948-0" },
                new ProductSeedData { Name = "Sapiens", Category = "Non-Fiction", Price = 200.00m, Type = "Book", Author = "Yuval Noah Harari", ISBN = "978-0-06-231609-7" },
                new ProductSeedData { Name = "Educated", Category = "Non-Fiction", Price = 180.00m, Type = "Book", Author = "Tara Westover", ISBN = "978-0-399-59050-4" },
                new ProductSeedData { Name = "Becoming", Category = "Non-Fiction", Price = 220.00m, Type = "Book", Author = "Michelle Obama", ISBN = "978-1-5247-6313-8" },
                new ProductSeedData { Name = "Calculus Textbook", Category = "Textbooks", Price = 450.00m, Type = "Book", Author = "James Stewart", ISBN = "978-1-285-74062-1" },
                new ProductSeedData { Name = "Physics Principles", Category = "Textbooks", Price = 380.00m, Type = "Book", Author = "Paul A. Tipler", ISBN = "978-1-4641-4078-8" },
                new ProductSeedData { Name = "Harry Potter and the Sorcerer's Stone", Category = "Children's Books", Price = 160.00m, Type = "Book", Author = "J.K. Rowling", ISBN = "978-0-439-70818-8" },
                new ProductSeedData { Name = "The Very Hungry Caterpillar", Category = "Children's Books", Price = 80.00m, Type = "Book", Author = "Eric Carle", ISBN = "978-0-399-22690-8" },
                new ProductSeedData { Name = "Where the Wild Things Are", Category = "Children's Books", Price = 90.00m, Type = "Book", Author = "Maurice Sendak", ISBN = "978-0-06-025492-6" },
                new ProductSeedData { Name = "Parker Pen Set", Category = "Stationery", Price = 85.00m, Type = "Stationery" },
                new ProductSeedData { Name = "A4 Paper Ream", Category = "Stationery", Price = 45.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Stapler", Category = "Stationery", Price = 35.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Notebooks (3 pack)", Category = "Stationery", Price = 60.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Highlighters (set of 5)", Category = "Stationery", Price = 25.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Canvas Paper", Category = "Art Supplies", Price = 75.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Acrylic Paint Set", Category = "Art Supplies", Price = 150.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Paint Brushes", Category = "Art Supplies", Price = 40.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Clean Code", Category = "Technology", Price = 350.00m, Type = "Book", Author = "Robert C. Martin", ISBN = "978-0-13-235088-4" },
                new ProductSeedData { Name = "JavaScript: The Good Parts", Category = "Technology", Price = 280.00m, Type = "Book", Author = "Douglas Crockford", ISBN = "978-0-596-51774-8" },
                new ProductSeedData { Name = "Introduction to Algorithms", Category = "Technology", Price = 500.00m, Type = "Book", Author = "Thomas H. Cormen", ISBN = "978-0-262-03384-8" },
                new ProductSeedData { Name = "The Lean Startup", Category = "Business", Price = 240.00m, Type = "Book", Author = "Eric Ries", ISBN = "978-0-307-88789-4" },
                new ProductSeedData { Name = "Rich Dad Poor Dad", Category = "Business", Price = 190.00m, Type = "Book", Author = "Robert Kiyosaki", ISBN = "978-1-61268-001-9" },
                new ProductSeedData { Name = "Think and Grow Rich", Category = "Business", Price = 170.00m, Type = "Book", Author = "Napoleon Hill", ISBN = "978-1-78844-008-2" },
                new ProductSeedData { Name = "The 7 Habits of Highly Effective People", Category = "Business", Price = 210.00m, Type = "Book", Author = "Stephen R. Covey", ISBN = "978-1-9821-3723-1" },
                new ProductSeedData { Name = "Filing Cabinet", Category = "Stationery", Price = 200.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Desk Organizer", Category = "Stationery", Price = 95.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Printer Paper", Category = "Stationery", Price = 55.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Glue Stick (pack of 3)", Category = "Stationery", Price = 20.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Scissors", Category = "Stationery", Price = 30.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Ruler Set", Category = "Stationery", Price = 15.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Pencil Sharpener", Category = "Stationery", Price = 10.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Eraser (pack of 5)", Category = "Stationery", Price = 12.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Marker Set", Category = "Art Supplies", Price = 65.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Sketch Book", Category = "Art Supplies", Price = 55.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Watercolor Set", Category = "Art Supplies", Price = 120.00m, Type = "Stationery" },
                new ProductSeedData { Name = "Charcoal Pencils", Category = "Art Supplies", Price = 35.00m, Type = "Stationery" },
                new ProductSeedData { Name = "The Art of War", Category = "Business", Price = 85.00m, Type = "Book", Author = "Sun Tzu", ISBN = "978-0-19-501476-1" },
                new ProductSeedData { Name = "Good to Great", Category = "Business", Price = 230.00m, Type = "Book", Author = "Jim Collins", ISBN = "978-0-06-662099-2" },
                new ProductSeedData { Name = "Atomic Habits", Category = "Non-Fiction", Price = 160.00m, Type = "Book", Author = "James Clear", ISBN = "978-0-735-21129-2" },
                new ProductSeedData { Name = "The Alchemist", Category = "Fiction", Price = 125.00m, Type = "Book", Author = "Paulo Coelho", ISBN = "978-0-06-231500-7" },
                new ProductSeedData { Name = "The Hobbit", Category = "Fiction", Price = 145.00m, Type = "Book", Author = "J.R.R. Tolkien", ISBN = "978-0-618-00221-4" },
                new ProductSeedData { Name = "The Lord of the Rings", Category = "Fiction", Price = 350.00m, Type = "Book", Author = "J.R.R. Tolkien", ISBN = "978-0-618-64015-7" },
                new ProductSeedData { Name = "The Chronicles of Narnia", Category = "Children's Books", Price = 250.00m, Type = "Book", Author = "C.S. Lewis", ISBN = "978-0-06-447119-0" },
                new ProductSeedData { Name = "The Hunger Games", Category = "Fiction", Price = 135.00m, Type = "Book", Author = "Suzanne Collins", ISBN = "978-0-439-02352-8" },
                new ProductSeedData { Name = "The Da Vinci Code", Category = "Fiction", Price = 155.00m, Type = "Book", Author = "Dan Brown", ISBN = "978-0-385-50420-1" },
                new ProductSeedData { Name = "The Girl with the Dragon Tattoo", Category = "Fiction", Price = 165.00m, Type = "Book", Author = "Stieg Larsson", ISBN = "978-0-307-26975-1" }
            };
            
            var random = new Random();
            int productIndex = 0;
            
            foreach (var bookstore in bookstores)
            {
                int productsPerStore = 10;
                for (int i = 0; i < productsPerStore && productIndex < products.Length; i++)
                {
                    var productData = products[productIndex];
                    var category = categories.FirstOrDefault(c => c.Name == productData.Category);
                    
                    if (category != null)
                    {
                        var product = new Product
                        {
                            BookstoreId = bookstore.UserId,
                            CategoryId = category.Id,
                            Name = productData.Name,
                            Description = "High quality " + productData.Type.ToLower() + " from " + bookstore.Name + ".",
                            Price = productData.Price,
                            StockQuantity = random.Next(10, 100),
                            ISBN = productData.ISBN,
                            Author = productData.Author,
                            Publisher = "Various Publishers",
                            ProductType = productData.Type,
                            IsForRent = false,
                            IsAvailable = true,
                            ImageUrl = "/Content/Images/" + productData.Name.Replace(" ", "_") + ".jpg",
                            CreatedAt = DateTime.Now,
                            UpdatedAt = DateTime.Now
                        };
                        
                        context.Products.Add(product);
                        productIndex++;
                    }
                }
            }
            
            context.SaveChanges();
        }
        
        private void UpdateBookstoreRoles(ApplicationDbContext context)
        {
            var userManager = new UserManager<ApplicationUser>(new UserStore<ApplicationUser>(context));
            var roleManager = new RoleManager<IdentityRole>(new RoleStore<IdentityRole>(context));
            
            // Find all users with BookstoreOwner role and update them to Bookstore role
            var bookstoreOwnerRole = roleManager.FindByName("BookstoreOwner");
            if (bookstoreOwnerRole != null)
            {
                var usersInOldRole = context.Users.Where(u => u.Roles.Any(r => r.RoleId == bookstoreOwnerRole.Id)).ToList();
                foreach (var user in usersInOldRole)
                {
                    // Remove from old role
                    userManager.RemoveFromRole(user.Id, "BookstoreOwner");
                    // Add to new role
                    userManager.AddToRole(user.Id, "Bookstore");
                }
                
                // Delete the old role
                roleManager.Delete(bookstoreOwnerRole);
            }
            
            // Ensure all bookstore users have the correct Bookstore role
            var bookstoreUsers = context.Bookstores.Select(b => b.User).ToList();
            foreach (var user in bookstoreUsers)
            {
                if (!userManager.IsInRole(user.Id, "Bookstore"))
                {
                    userManager.AddToRole(user.Id, "Bookstore");
                }
            }
        }
    }
}