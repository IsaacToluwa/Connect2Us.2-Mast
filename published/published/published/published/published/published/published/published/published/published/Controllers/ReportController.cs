using System.Web.Mvc;
using System;
using System.IO;
using iTextSharp.text;
using iTextSharp.text.pdf;
using Connect2Us.Models;
using System.Linq;
using System.Data.Entity;

namespace Connect2Us.Controllers
{
    [Authorize(Roles = "Admin")]
    public class ReportController : Controller
    {
        private ApplicationDbContext db = new ApplicationDbContext();

        // GET: Report
        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public ActionResult GenerateReport(string reportType, DateTime? startDate, DateTime? endDate)
        {
            using (MemoryStream ms = new MemoryStream())
            {
                Document document = new Document();
                PdfWriter writer = PdfWriter.GetInstance(document, ms);
                document.Open();

                document.Add(new Paragraph("Report Type: " + reportType));
                document.Add(new Paragraph("Start Date: " + (startDate.HasValue ? startDate.Value.ToShortDateString() : "N/A")));
                document.Add(new Paragraph("End Date: " + (endDate.HasValue ? endDate.Value.ToShortDateString() : "N/A")));
                document.Add(new Paragraph(" ")); // Add a blank line

                switch (reportType)
                {
                    case "Sales":
                        GenerateSalesReport(document, startDate, endDate);
                        break;
                    case "Users":
                        GenerateUsersReport(document);
                        break;
                    case "Bookstores":
                        GenerateBookstoresReport(document);
                        break;
                }

                document.Close();
                writer.Close();

                return File(ms.ToArray(), "application/pdf", reportType + "Report.pdf");
            }
        }

        private void GenerateSalesReport(Document document, DateTime? startDate, DateTime? endDate)
        {
            var orders = db.Orders.Include(o => o.Customer.User).Include(o => o.Bookstore).AsQueryable();

            if (startDate.HasValue)
            {
                orders = orders.Where(o => o.OrderDate >= startDate.Value);
            }

            if (endDate.HasValue)
            {
                orders = orders.Where(o => o.OrderDate <= endDate.Value);
            }

            var ordersList = orders.ToList();

            PdfPTable table = new PdfPTable(5);
            table.AddCell("Order Number");
            table.AddCell("Customer");
            table.AddCell("Bookstore");
            table.AddCell("Total");
            table.AddCell("Status");

            foreach (var order in ordersList)
            {
                table.AddCell(order.OrderNumber);
                table.AddCell(order.Customer.User.UserName);
                table.AddCell(order.Bookstore.Name);
                table.AddCell(order.TotalAmount.ToString("C"));
                table.AddCell(order.Status);
            }

            document.Add(table);
        }

        private void GenerateUsersReport(Document document)
        {
            var users = db.Users.Include(u => u.Roles).ToList();
            var roles = db.Roles.ToList();

            PdfPTable table = new PdfPTable(3);
            table.AddCell("Username");
            table.AddCell("Email");
            table.AddCell("Roles");

            foreach (var user in users)
            {
                table.AddCell(user.UserName);
                table.AddCell(user.Email);
                var userRoles = user.Roles.Select(r => roles.FirstOrDefault(role => role.Id == r.RoleId)?.Name);
                table.AddCell(string.Join(", ", userRoles));
            }

            document.Add(table);
        }

        private void GenerateBookstoresReport(Document document)
        {
            var bookstores = db.Bookstores.Include(b => b.User).ToList();

            PdfPTable table = new PdfPTable(2);
            table.AddCell("Name");
            table.AddCell("Owner");

            foreach (var bookstore in bookstores)
            {
                table.AddCell(bookstore.Name);
                table.AddCell(bookstore.User.UserName);
            }

            document.Add(table);
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