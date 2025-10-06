using System;
using System.ComponentModel.DataAnnotations;

namespace Connect2Us.Models
{
    public class SystemSettings
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string SiteName { get; set; }

        [StringLength(500)]
        public string SiteDescription { get; set; }

        [StringLength(255)]
        public string SiteLogo { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(100)]
        public string ContactEmail { get; set; }

        [Required]
        [Range(0, 100)]
        public decimal CommissionRate { get; set; }

        [Required]
        [Range(0, 1000)]
        public decimal DeliveryFee { get; set; }

        [Required]
        [Range(0, 50)]
        public decimal TaxRate { get; set; }

        [Required]
        public bool IsMaintenanceMode { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public SystemSettings()
        {
            CreatedAt = DateTime.Now;
            IsMaintenanceMode = false;
        }
    }
}