using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Connect2Us.Models
{
    public class BankCard
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string UserId { get; set; }
        
        [ForeignKey("UserId")]
        public virtual ApplicationUser User { get; set; }
        
        [Required]
        [StringLength(16)]
        public string CardNumber { get; set; }
        
        [Required]
        [StringLength(50)]
        public string CardholderName { get; set; }
        
        [Required]
        [StringLength(5)]
        public string ExpiryDate { get; set; } // Format: MM/YY
        
        [Required]
        [StringLength(3)]
        public string CVV { get; set; }
        
        [StringLength(50)]
        public string CardType { get; set; } // Visa, Mastercard, etc.
        
        public bool IsActive { get; set; }
        
        public DateTime AddedDate { get; set; }
        
        public DateTime? LastUsedDate { get; set; }
        
        public BankCard()
        {
            IsActive = true;
            AddedDate = DateTime.Now;
        }
        
        // Computed property for masked card number
        [NotMapped]
        public string MaskedCardNumber
        {
            get
            {
                if (string.IsNullOrEmpty(CardNumber) || CardNumber.Length < 4)
                    return CardNumber;
                
                return "**** **** **** " + CardNumber.Substring(CardNumber.Length - 4);
            }
        }
    }
}