namespace Connect2Us.Models
{
    public class WishlistItem
    {
        public int Id { get; set; }
        public int WishlistId { get; set; }
        public virtual Wishlist Wishlist { get; set; }
        public int ProductId { get; set; }
        public virtual Product Product { get; set; }
    }
}