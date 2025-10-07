using System.Threading.Tasks;

namespace Connect2Us.Services
{
    public interface IEmailService
    {
        Task SendEmailAsync(string email, string subject, string message);
    }
}