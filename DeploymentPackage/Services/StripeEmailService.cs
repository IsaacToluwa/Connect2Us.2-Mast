using System.Net.Mail;
using System.Threading.Tasks;

namespace Connect2Us.Services
{
    public class StripeEmailService : IEmailService
    {
        public async Task SendEmailAsync(string email, string subject, string message)
        {
            // TODO: Replace with your actual SMTP server and credentials
            var client = new SmtpClient("smtp.example.com", 587)
            {
                Credentials = new System.Net.NetworkCredential("your-email@example.com", "your-password"),
                EnableSsl = true
            };

            var mailMessage = new MailMessage("your-email@example.com", email, subject, message);
            await client.SendMailAsync(mailMessage);
        }
    }
}