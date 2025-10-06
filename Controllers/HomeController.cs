using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Connect2Us.Models;

namespace Connect2Us.Controllers
{
    public class HomeController : Controller
    {
        private ApplicationDbContext db = new ApplicationDbContext();

        public ActionResult Index(string search, int? categoryId, int? page)
        {
            try
            {
                // Debug logging
                System.IO.File.AppendAllText(System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/startup_log.txt"), 
                    "Index action called at " + DateTime.Now + "\n");

                // Test database connection first
                List<Category> categories;
                try
                {
                    var canConnect = db.Database.Exists();
                    System.IO.File.AppendAllText(System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/startup_log.txt"), 
                        "Database exists: " + canConnect + " at " + DateTime.Now + "\n");
                    
                    if (canConnect)
                    {
                        var dbCategories = db.Categories.ToList();
                        if (dbCategories != null && dbCategories.Any())
                        {
                            categories = dbCategories;
                            System.IO.File.AppendAllText(System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/startup_log.txt"), 
                                "Loaded " + dbCategories.Count + " categories from database at " + DateTime.Now + "\n");
                        }
                        else
                        {
                            categories = GetHardcodedCategories();
                            System.IO.File.AppendAllText(System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/startup_log.txt"), 
                                "Database exists but no categories found at " + DateTime.Now + "\n");
                        }
                    }
                    else
                    {
                        categories = GetHardcodedCategories();
                        System.IO.File.AppendAllText(System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/startup_log.txt"), 
                            "Database does not exist, using hardcoded categories at " + DateTime.Now + "\n");
                    }
                }
                catch (Exception dbEx)
                {
                    System.IO.File.AppendAllText(System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/startup_log.txt"), 
                        "Database connection error: " + dbEx.Message + " at " + DateTime.Now + "\n");
                    categories = GetHardcodedCategories();
                }

                ViewBag.Categories = categories;
                ViewBag.CategoryId = categoryId;
                ViewBag.SearchTerm = search;

                int pageSize = 9;
                int pageNumber = page ?? 1;

                // Try to get products from database, but fallback to empty list if fails
                List<Product> products;
                try
                {
                    products = db.Products.ToList();
                }
                catch (Exception dbEx)
                {
                    System.IO.File.AppendAllText(System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/startup_log.txt"), 
                        "Database error loading products: " + dbEx.Message + " at " + DateTime.Now + "\n");
                    products = new List<Product>();
                }

                // Apply search filter
                if (!string.IsNullOrEmpty(search))
                {
                    products = products.Where(p => p.Name.Contains(search) || p.Description.Contains(search)).ToList();
                }

                // Apply category filter
                if (categoryId.HasValue)
                {
                    products = products.Where(p => p.CategoryId == categoryId.Value).ToList();
                }

                // Simple pagination without PagedList
                var paginatedProducts = products.OrderBy(p => p.Name)
                    .Skip((pageNumber - 1) * pageSize)
                    .Take(pageSize)
                    .ToList();
                
                ViewBag.CurrentPage = pageNumber;
                ViewBag.PageSize = pageSize;
                ViewBag.TotalCount = products.Count;
                ViewBag.TotalPages = (int)Math.Ceiling((double)products.Count / pageSize);
                
                return View(paginatedProducts);
            }
            catch (Exception)
            {
                System.IO.File.AppendAllText(System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/startup_log.txt"), 
                    "Index action error occurred at " + DateTime.Now + "\n");
                
                ViewBag.Categories = GetHardcodedCategories();
                
                // Simple pagination without PagedList
                ViewBag.CurrentPage = 1;
                ViewBag.PageSize = 9;
                ViewBag.TotalCount = 0;
                ViewBag.TotalPages = 0;
                
                return View(new List<Product>());
            }
        }

        private List<Category> GetHardcodedCategories()
        {
            return new List<Category>
            {
                new Category { Id = 1, Name = "Fiction" },
                new Category { Id = 2, Name = "Non-Fiction" },
                new Category { Id = 3, Name = "Textbooks" },
                new Category { Id = 4, Name = "Art Supplies" },
                new Category { Id = 5, Name = "Electronics" }
            };
        }

        public ActionResult About()
        {
            ViewBag.Message = "Your application description page.";

            return View();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }
    }
}