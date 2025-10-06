using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Connect2Us.Models
{
    public class DeliveryDriver
    {
        [Key]
        [ForeignKey("User")]
        public string UserId { get; set; }

        public string VehicleNumber { get; set; }

        public string LicenseNumber { get; set; }

        public string VehicleType { get; set; }

        public string VehicleRegistration { get; set; }

        public bool IsAvailable { get; set; }

        public virtual ApplicationUser User { get; set; }

        public virtual ICollection<Delivery> Deliveries { get; set; }
    }
}