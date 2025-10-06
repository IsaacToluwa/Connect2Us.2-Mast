using System;
using System.Net;
using System.Collections.Specialized;

public class RegistrationTester
{
    public static void Main(string[] args)
    {
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
        ServicePointManager.ServerCertificateValidationCallback = (sender, certificate, chain, sslPolicyErrors) => true;
        Register();
    }

    public static void Register()
    {
        using (var client = new WebClient())
        {
            var values = new NameValueCollection
            {
                { "FirstName", "Test" },
                { "LastName", "User" },
                { "Email", "testuser@example.com" },
                { "Phone", "1234567890" },
                { "Address", "123 Test St" },
                { "Password", "Password123!" },
                { "ConfirmPassword", "Password123!" },
                { "UserType", "Customer" }
            };

            var response = client.UploadValues("http://localhost:8088/Account/Register", values);

            var responseString = System.Text.Encoding.Default.GetString(response);

            Console.WriteLine(responseString);
        }
    }
}