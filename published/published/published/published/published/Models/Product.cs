using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Connect2Us.Models
{
    public class Product
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string BookstoreId { get; set; }
        
        [Required]
        public int CategoryId { get; set; }
        
        [Required]
        [StringLength(200)]
        public string Name { get; set; }
        
        [StringLength(1000)]
        public string Description { get; set; }
        
        [Required]
        public decimal Price { get; set; }
        
        [Required]
        public int StockQuantity { get; set; }
        
        [StringLength(50)]
        public string ISBN { get; set; }
        
        [StringLength(100)]
        public string Author { get; set; }
        
        [StringLength(100)]
        public string Publisher { get; set; }
        
        [StringLength(20)]
        public string ProductType { get; set; }
        
        public bool IsForRent { get; set; }
        
        public decimal? RentalPrice { get; set; }
        
        public bool IsAvailable { get; set; }
        
        public string ImageUrl { get; set; }

        [Column(TypeName = "datetime2")]
        public DateTime CreatedAt { get; set; }

        [Column(TypeName = "datetime2")]
        public DateTime? UpdatedAt { get; set; }

        [ForeignKey("BookstoreId")]
        public virtual Bookstore Bookstore { get; set; }
        
        [ForeignKey("CategoryId")]
        public virtual Category Category { get; set; }
        
        public virtual ICollection<OrderItem> OrderItems { get; set; }
        
        public Product()
        {
            OrderItems = new HashSet<OrderItem>();
            CreatedAt = DateTime.Now;
            IsAvailable = true;
            ProductType = "Book";
        }
    }
}