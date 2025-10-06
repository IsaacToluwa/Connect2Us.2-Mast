using System.Collections.Generic;

namespace Connect2Us.Models
{
    public class Wishlist
    {
        public int Id { get; set; }
        public string UserId { get; set; }
        public virtual ApplicationUser User { get; set; }
        public virtual ICollection<WishlistItem> WishlistItems { get; set; }
    }
}