using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Connect2Us.Models
{
    public class Cart
    {
        [Key]
        public int Id { get; set; }

        public string UserId { get; set; }

        public virtual ICollection<CartItem> CartItems { get; set; }
    }
}