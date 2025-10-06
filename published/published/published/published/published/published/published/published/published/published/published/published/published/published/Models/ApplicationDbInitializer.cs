using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;
using Connect2Us.Models;

namespace Connect2Us._2
{
    public class ApplicationDbInitializer : DropCreateDatabaseIfModelChanges<ApplicationDbContext>
    {
        protected override void Seed(ApplicationDbContext context)
        {
            try
            {
                // Seed categories
                var categories = new List<Category>
                {
                    new Category { Name = "Fiction" },
                    new Category { Name = "Non-Fiction" },
                    new Category { Name = "Textbooks" },
                    new Category { Name = "Art Supplies" },
                    new Category { Name = "Electronics" },
                    new Category { Name = "Science" },
                    new Category { Name = "History" },
                    new Category { Name = "Mathematics" }
                };

                foreach (var category in categories)
                {
                    if (!context.Categories.Any(c => c.Name == category.Name))
                    {
                        context.Categories.Add(category);
                    }
                }

                // Seed some sample products
                var fictionCategory = context.Categories.FirstOrDefault(c => c.Name == "Fiction");
                var textbookCategory = context.Categories.FirstOrDefault(c => c.Name == "Textbooks");
                var electronicsCategory = context.Categories.FirstOrDefault(c => c.Name == "Electronics");

                if (fictionCategory != null)
                {
                    var products = new List<Product>
                    {
                        new Product 
                        { 
                            Name = "The Great Gatsby", 
                            Description = "Classic American novel by F. Scott Fitzgerald", 
                            Price = 12.99m, 
                            Stock = 50, 
                            CategoryId = fictionCategory.Id,
                            Author = "F. Scott Fitzgerald",
                            ISBN = "978-0-7432-7356-5"
                        },
                        new Product 
                        { 
                            Name = "To Kill a Mockingbird", 
                            Description = "Classic novel by Harper Lee", 
                            Price = 14.99m, 
                            Stock = 30, 
                            CategoryId = fictionCategory.Id,
                            Author = "Harper Lee",
                            ISBN = "978-0-06-112008-4"
                        }
                    };

                    foreach (var product in products)
                    {
                        if (!context.Products.Any(p => p.Name == product.Name))
                        {
                            context.Products.Add(product);
                        }
                    }
                }

                context.SaveChanges();
                
                // Log success
                System.IO.File.AppendAllText(System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/startup_log.txt"), 
                    $"Database seeded successfully at {DateTime.Now}\n");
            }
            catch (Exception ex)
            {
                // Log error
                System.IO.File.AppendAllText(System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/startup_log.txt"), 
                    $"Error seeding database: {ex.Message} at {DateTime.Now}\n");
                throw;
            }
        }
    }
}