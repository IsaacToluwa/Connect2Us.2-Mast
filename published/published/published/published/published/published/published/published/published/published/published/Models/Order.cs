using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Connect2Us.Models
{
    public class Order
    {
        [Key]
        public int Id { get; set; }

        public string UserId { get; set; }
        
        [Required]
        public string CustomerId { get; set; }
        
        [Required]
        public string BookstoreId { get; set; }
        
        [Required]
        [StringLength(50)]
        public string OrderNumber { get; set; }
        
        [Required]
        public decimal TotalAmount { get; set; }
        
        [Required]
        [StringLength(50)]
        public string Status { get; set; }
        
        public DateTime OrderDate { get; set; }
        
        public DateTime? DeliveryDate { get; set; }
        
        [Required]
        [StringLength(200)]
        public string DeliveryAddress { get; set; }
        
        public string Notes { get; set; }
        
        public bool IsPaid { get; set; }
        
        public DateTime? PaymentDate { get; set; }
        
        [ForeignKey("CustomerId")]
        public virtual Customer Customer { get; set; }
        
        [ForeignKey("BookstoreId")]
        public virtual Bookstore Bookstore { get; set; }
        
        public virtual ICollection<OrderItem> OrderItems { get; set; }
        public virtual ICollection<Payment> Payments { get; set; }
        public virtual ICollection<Delivery> Deliveries { get; set; }
        
        public Order()
        {
            OrderItems = new HashSet<OrderItem>();
            Payments = new HashSet<Payment>();
            Deliveries = new HashSet<Delivery>();
            OrderDate = DateTime.Now;
            Status = "Pending";
            IsPaid = false;
            OrderNumber = "ORD" + DateTime.Now.ToString("yyyyMMddHHmmss");
        }
    }
}