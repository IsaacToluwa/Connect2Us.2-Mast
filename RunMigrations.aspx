<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="Connect2Us.Models" %>
<%@ Import Namespace="Connect2Us.Migrations" %>

<!DOCTYPE html>
<html>
<head>
    <title>Database Migration Runner</title>
</head>
<body>
    <h1>Running Database Migrations...</h1>
    <%
        try
        {
            // Initialize database with migrations and preserve seeded data
            Database.SetInitializer(new Connect2Us.Infrastructure.PreserveSeedDataInitializer());
            
            // Force database initialization
            using (var context = new ApplicationDbContext())
            {
                context.Database.Initialize(true);
                Response.Write("<p style='color: green;'>✓ Database migrations completed successfully!</p>");
                
                // Verify seed data
                Response.Write("<h2>Database Contents:</h2>");
                Response.Write("<ul>");
                Response.Write($"<li>Admins: {context.Admins.Count()}</li>");
                Response.Write($"<li>Delivery Drivers: {context.DeliveryDrivers.Count()}</li>");
                Response.Write($"<li>Bookstores: {context.Bookstores.Count()}</li>");
                Response.Write($"<li>Customers: {context.Customers.Count()}</li>");
                Response.Write($"<li>Products: {context.Products.Count()}</li>");
                Response.Write($"<li>Categories: {context.Categories.Count()}</li>");
                Response.Write($"<li>BankCards: {context.BankCards.Count()}</li>");
                Response.Write($"<li>Wallets: {context.Wallets.Count()}</li>");
                Response.Write("</ul>");
            }
        }
        catch (Exception ex)
        {
            Response.Write($"<p style='color: red;'>✗ Error: {ex.Message}</p>");
            Response.Write($"<pre>{ex.StackTrace}</pre>");
        }
    %>
    
    <h2>Test Login Credentials:</h2>
    <table border="1" cellpadding="5">
        <tr><th>Role</th><th>Email</th><th>Password</th></tr>
        <tr><td>Admin</td><td>olatunjitoluwanimi90@yahoo.com</td><td>Admin@123</td></tr>
        <tr><td>Delivery Driver</td><td>22137151@dut4life.ac.za</td><td>Driver@123</td></tr>
        <tr><td>Bookstore</td><td>22435296@dut4life.ac.za</td><td>Bookstore@123</td></tr>
        <tr><td>Customer</td><td>olatunjitoluwanimi90@gmail.com</td><td>Customer@123</td></tr>
    </table>
</body>
</html>