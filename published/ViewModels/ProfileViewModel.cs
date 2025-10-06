using System;
using System.ComponentModel.DataAnnotations;

namespace Connect2Us.ViewModels
{
    public class ProfileViewModel
    {
        public string Id { get; set; }

        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Display(Name = "First Name")]
        public string FirstName { get; set; }

        [Display(Name = "Last Name")]
        public string LastName { get; set; }

        [Display(Name = "Phone Number")]
        public string PhoneNumber { get; set; }

        [Display(Name = "Date of Birth")]
        [DataType(DataType.Date)]
        public DateTime? DateOfBirth { get; set; }

        public string Address { get; set; }
        public string City { get; set; }
        public string State { get; set; }

        [Display(Name = "Postal Code")]
        public string PostalCode { get; set; }

        public string Country { get; set; }

        // Bookstore specific properties
        [Display(Name = "Bookstore Name")]
        public string BookstoreName { get; set; }

        [Display(Name = "Bookstore Description")]
        public string BookstoreDescription { get; set; }
    }
}