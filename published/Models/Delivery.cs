using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Connect2Us.Models
{
    public class Delivery
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public int OrderId { get; set; }
        
        [ForeignKey("OrderId")]
        public virtual Order Order { get; set; }

        public string DeliveryDriverId { get; set; }

        [ForeignKey("DeliveryDriverId")]
        public virtual DeliveryDriver DeliveryDriver { get; set; }
        
        [Required]
        [StringLength(50)]
        public string TrackingNumber { get; set; }
        
        [Required]
        [StringLength(50)]
        public string Status { get; set; }
        
        public DateTime AssignedDate { get; set; }
        
        public DateTime? PickupDate { get; set; }
        
        public DateTime? DeliveryDate { get; set; }
        
        public decimal DeliveryFee { get; set; }
        
        public string Notes { get; set; }
        
        public Delivery()
        {
            AssignedDate = DateTime.Now;
            Status = "Assigned";
            DeliveryFee = 50.00m;
            TrackingNumber = "TRK" + DateTime.Now.ToString("yyyyMMddHHmmss");
        }
    }
}