using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Connect2Us.Models
{
    public class Category
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [StringLength(50)]
        public string Name { get; set; }
        
        public string Description { get; set; }
        
        public bool IsActive { get; set; }
        
        [Column(TypeName = "datetime2")]
        public DateTime CreatedAt { get; set; }
        
        [Column(TypeName = "datetime2")]
        public DateTime UpdatedAt { get; set; }
        
        public virtual ICollection<Product> Products { get; set; }
        
        public Category()
        {
            Products = new HashSet<Product>();
            IsActive = true;
            CreatedAt = DateTime.UtcNow;
            UpdatedAt = DateTime.UtcNow;
        }
    }
}