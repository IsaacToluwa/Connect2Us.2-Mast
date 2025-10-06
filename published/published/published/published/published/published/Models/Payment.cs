using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Connect2Us.Models
{
    public class Payment
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public int OrderId { get; set; }
        
        [Required]
        public string PaymentIntentId { get; set; }
        
        [Required]
        public decimal Amount { get; set; }
        
        [Required]
        [StringLength(50)]
        public string PaymentMethod { get; set; }
        
        [Required]
        [StringLength(50)]
        public string Status { get; set; }
        
        public DateTime PaymentDate { get; set; }
        
        public string StripePaymentId { get; set; }
        
        [ForeignKey("OrderId")]
        public virtual Order Order { get; set; }
        
        public Payment()
        {
            PaymentDate = DateTime.Now;
            Status = "Pending";
            PaymentMethod = "Stripe";
        }
    }
}