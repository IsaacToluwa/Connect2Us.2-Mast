using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System;

namespace Connect2Us.Models
{
    public class LoginViewModel
    {
        [Required]
        [Display(Name = "Email")]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        [DataType(DataType.Password)]
        [Display(Name = "Password")]
        public string Password { get; set; }

        [Display(Name = "Remember me?")]
        public bool RememberMe { get; set; }
    }

    public class RegisterViewModel
    {
        [Required]
        [Display(Name = "First Name")]
        public string FirstName { get; set; }

        [Required]
        [Display(Name = "Last Name")]
        public string LastName { get; set; }

        [Required]
        [EmailAddress]
        [Display(Name = "Email")]
        public string Email { get; set; }

        [Required]
        [StringLength(100, ErrorMessage = "The {0} must be at least {2} characters long.", MinimumLength = 6)]
        [DataType(DataType.Password)]
        [Display(Name = "Password")]
        public string Password { get; set; }

        [DataType(DataType.Password)]
        [Display(Name = "Confirm password")]
        [Compare("Password", ErrorMessage = "The password and confirmation password do not match.")]
        public string ConfirmPassword { get; set; }

        [Required]
        [Display(Name = "Phone Number")]
        public string Phone { get; set; }

        [Required]
        [Display(Name = "Address")]
        public string Address { get; set; }

        [Required]
        [Display(Name = "User Type")]
        public string UserType { get; set; }

        // Bookstore specific fields
        [Display(Name = "Business Name")]
        public string BusinessName { get; set; }

        [Display(Name = "Business Description")]
        public string Description { get; set; }

        // Delivery Driver specific fields
        [Display(Name = "License Number")]
        public string LicenseNumber { get; set; }

        [Display(Name = "Vehicle Type")]
        public string VehicleType { get; set; }

        [Display(Name = "Vehicle Registration")]
        public string VehicleRegistration { get; set; }
    }

    public class ForgotPasswordViewModel
    {
        [Required]
        [EmailAddress]
        [Display(Name = "Email")]
        public string Email { get; set; }
    }

    public class ResetPasswordViewModel
    {
        [Required]
        [EmailAddress]
        [Display(Name = "Email")]
        public string Email { get; set; }

        [Required]
        [StringLength(100, ErrorMessage = "The {0} must be at least {2} characters long.", MinimumLength = 6)]
        [DataType(DataType.Password)]
        [Display(Name = "Password")]
        public string Password { get; set; }

        [DataType(DataType.Password)]
        [Display(Name = "Confirm password")]
        [Compare("Password", ErrorMessage = "The password and confirmation password do not match.")]
        public string ConfirmPassword { get; set; }

        public string Code { get; set; }
    }



    public class BookstoreEditViewModel
    {
        public string UserId { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; }

        public string Description { get; set; }

        public string Address { get; set; }

        [Display(Name = "Contact Number")]
    public string ContactNumber { get; set; }
}

public class CheckoutViewModel
{
    public System.Collections.Generic.List<CustomerCartItem> CartItems { get; set; }
    public string DeliveryAddress { get; set; }
    public string Notes { get; set; }
    public decimal WalletBalance { get; set; }
    public decimal TotalAmount { get; set; }
}

public class CustomerCartItem
{
    public int ProductId { get; set; }
    public string ProductName { get; set; }
    public decimal Price { get; set; }
    public int Quantity { get; set; }
    public bool IsRental { get; set; }
    public string BookstoreId { get; set; }
    public decimal TotalPrice => Price * Quantity;
}

public class BookstoreDashboardViewModel
{
    public Bookstore Bookstore { get; set; }
    public int TotalProducts { get; set; }
    public int TotalOrders { get; set; }
    public int PendingOrders { get; set; }
    public decimal TotalRevenue { get; set; }
    public System.Collections.Generic.List<Order> RecentOrders { get; set; }
    public decimal WalletBalance { get; set; }
}

public class BookstoreDetailsViewModel
{
    public Bookstore Bookstore { get; set; }
    public int TotalProducts { get; set; }
    public int TotalOrders { get; set; }
    public decimal TotalRevenue { get; set; }
}

public class UserListViewModel
{
    public IEnumerable<ApplicationUser> Users { get; set; }
}

public class UserEditViewModel
{
    public string Id { get; set; }

    [Required]
    [Display(Name = "First Name")]
    public string FirstName { get; set; }

    [Required]
    [Display(Name = "Last Name")]
    public string LastName { get; set; }

    [Required]
    [EmailAddress]
    public string Email { get; set; }

    public IEnumerable<string> Roles { get; set; }

    [Display(Name = "New Role")]
    public string NewRole { get; set; }
}

public class UserCreateViewModel
{
    [Required]
    [EmailAddress]
    [Display(Name = "Email")]
    public string Email { get; set; }

    [Required]
    [StringLength(100, ErrorMessage = "The {0} must be at least {2} characters long.", MinimumLength = 6)]
    [DataType(DataType.Password)]
    [Display(Name = "Password")]
    public string Password { get; set; }

    [DataType(DataType.Password)]
    [Display(Name = "Confirm password")]
    [Compare("Password", ErrorMessage = "The password and confirmation password do not match.")]
    public string ConfirmPassword { get; set; }

    [Required]
    [Display(Name = "User Role")]
    public string UserRole { get; set; }
}

public class BookstoreReportsViewModel
{
    public decimal TotalRevenue { get; set; }
    public int TotalOrders { get; set; }
    public int TotalProducts { get; set; }
    public System.Collections.Generic.List<Product> LowStockProducts { get; set; }
    public System.Collections.Generic.List<MonthlyRevenue> MonthlyRevenue { get; set; }
}

public class MonthlyRevenue
{
    public int Month { get; set; }
    public decimal Revenue { get; set; }
    public string MonthName { get { return new DateTime(2024, Month, 1).ToString("MMM"); } }
}

public class AdminBookstoresViewModel
{
    public System.Collections.Generic.List<Bookstore> Bookstores { get; set; }
}

public class AdminReportsViewModel
{
    public int TotalUsers { get; set; }
    public int TotalBookstores { get; set; }
    public int TotalOrders { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal MonthlyRevenue { get; set; }
    public int MonthlyOrders { get; set; }
    public List<TopBookstore> TopBookstores { get; set; }
    public List<OrdersByStatus> MonthlyOrdersByStatus { get; set; }
}

public class TopBookstore
{
    public Bookstore Bookstore { get; set; }
    public decimal Revenue { get; set; }
    public int Orders { get; set; }
}

public class OrdersByStatus
{
    public string Status { get; set; }
    public int Count { get; set; }
}

    public class DriverDashboardViewModel
    {
        public DeliveryDriver Driver { get; set; }
        public int TotalDeliveries { get; set; }
        public int CompletedDeliveries { get; set; }
        public int PendingDeliveries { get; set; }
        public int AvailableDeliveries { get; set; }
        public System.Collections.Generic.List<Delivery> RecentDeliveries { get; set; }
    }

    public class DriverEarningsViewModel
    {
        public DeliveryDriver Driver { get; set; }
        public decimal TotalEarnings { get; set; }
        public decimal MonthlyEarnings { get; set; }
        public decimal WeeklyEarnings { get; set; }
        public int CompletedDeliveries { get; set; }
        public System.Collections.Generic.List<Delivery> RecentEarnings { get; set; }
    }

    public class TransactionViewModel
    {
        public System.Collections.Generic.IEnumerable<Transaction> Transactions { get; set; }
    }

    public class AdminDashboardViewModel
    {
        public int TotalUsers { get; set; }
        public int TotalBookstores { get; set; }
        public int TotalCustomers { get; set; }
        public int TotalDeliveryDrivers { get; set; }
        public int TotalOrders { get; set; }
        public decimal TotalRevenue { get; set; }
        public int PendingOrders { get; set; }
        public System.Collections.Generic.List<Order> RecentOrders { get; set; }
        public System.Collections.Generic.List<RecentUser> RecentUsers { get; set; }
    }

    public class RecentUser
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string UserType { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class OrdersViewModel
    {
        public List<Order> Orders { get; set; }
        public List<string> Statuses { get; set; }
        public string SelectedStatus { get; set; }
        public string SearchTerm { get; set; }

        public OrdersViewModel()
        {
            Orders = new List<Order>();
            Statuses = new List<string> { "Pending", "Processing", "Shipped", "Delivered", "Cancelled" };
        }
    }
}