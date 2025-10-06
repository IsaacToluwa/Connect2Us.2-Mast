using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;
using Connect2Us.Models;
using Connect2Us.Migrations;
using System.Data.Entity.Migrations;

namespace Connect2Us._2
{
    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            string logPath = HttpContext.Current.Server.MapPath("~/App_Data/startup_log.txt");
            
            // Ensure App_Data directory exists
            string logDirectory = System.IO.Path.GetDirectoryName(logPath);
            if (!System.IO.Directory.Exists(logDirectory))
            {
                System.IO.Directory.CreateDirectory(logDirectory);
            }
            
            System.IO.File.AppendAllText(logPath, "Application_Start entered at " + DateTime.Now + "\n");
            
            try
            {
                // Configure database to use migrations and preserve seeded data
                System.IO.File.AppendAllText(logPath, "Configuring database initialization...\n");
                Database.SetInitializer(new Connect2Us.Infrastructure.PreserveSeedDataInitializer());
                
                System.IO.File.AppendAllText(logPath, "Registering Areas...\n");
                AreaRegistration.RegisterAllAreas();
                
                System.IO.File.AppendAllText(logPath, "Registering Global Filters...\n");
                FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
                
                System.IO.File.AppendAllText(logPath, "Registering Routes...\n");
                RouteConfig.RegisterRoutes(RouteTable.Routes);
                
                System.IO.File.AppendAllText(logPath, "Registering Bundles...\n");
                BundleConfig.RegisterBundles(BundleTable.Bundles);
                
                System.IO.File.AppendAllText(logPath, "Application_Start completed successfully\n");
            }
            catch (Exception ex)
            {
                System.IO.File.AppendAllText(logPath, "Application_Start error: " + ex.Message + "\n" + ex.StackTrace + "\n");
                throw;
            }
        }
    }
}
