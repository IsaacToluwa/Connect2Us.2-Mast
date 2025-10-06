using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Connect2Us.Models;
using System.Collections.Generic;

namespace Connect2Us.ViewModels
{
    public class BankCardViewModel
    {
        public int Id { get; set; }
        
        [Required(ErrorMessage = "Card number is required")]
        [StringLength(16, MinimumLength = 13, ErrorMessage = "Card number must be between 13 and 16 digits")]
        [RegularExpression(@"^[0-9]{13,16}$", ErrorMessage = "Card number must contain only digits")]
        public string CardNumber { get; set; }
        
        [Required(ErrorMessage = "Cardholder name is required")]
        [StringLength(50, ErrorMessage = "Cardholder name cannot exceed 50 characters")]
        [RegularExpression(@"^[a-zA-Z\s\-']+$", ErrorMessage = "Cardholder name can only contain letters, spaces, hyphens, and apostrophes")]
        public string CardholderName { get; set; }
        
        [Required(ErrorMessage = "Expiry date is required")]
        [StringLength(5, ErrorMessage = "Expiry date must be in MM/YY format")]
        [RegularExpression(@"^(0[1-9]|1[0-2])\/([0-9]{2})$", ErrorMessage = "Expiry date must be in MM/YY format")]
        public string ExpiryDate { get; set; }
        
        [Required(ErrorMessage = "CVV is required")]
        [StringLength(3, MinimumLength = 3, ErrorMessage = "CVV must be exactly 3 digits")]
        [RegularExpression(@"^[0-9]{3}$", ErrorMessage = "CVV must contain only digits")]
        public string CVV { get; set; }
        
        public string CardType { get; set; }
        
        public bool IsActive { get; set; }
        
        public DateTime AddedDate { get; set; }
        
        public DateTime? LastUsedDate { get; set; }
        
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
        
        // Helper method to detect card type
        public static string DetectCardType(string cardNumber)
        {
            if (string.IsNullOrEmpty(cardNumber))
                return "Unknown";
            
            cardNumber = cardNumber.Replace(" ", "").Replace("-", "");
            
            if (cardNumber.StartsWith("4"))
                return "Visa";
            else if (cardNumber.StartsWith("5") && cardNumber.Length >= 2)
                return "Mastercard";
            else if (cardNumber.StartsWith("3") && cardNumber.Length >= 2 && (cardNumber[1] == '4' || cardNumber[1] == '7'))
                return "American Express";
            else if (cardNumber.StartsWith("6"))
                return "Discover";
            else
                return "Unknown";
        }
    }
    
    public class WalletWithCardsViewModel
    {
        public Wallet Wallet { get; set; }
        public List<BankCard> BankCards { get; set; }
        public List<Transaction> Transactions { get; set; }
        public BankCardViewModel NewCard { get; set; }
    }
}