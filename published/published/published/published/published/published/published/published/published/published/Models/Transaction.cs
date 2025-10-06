using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Connect2Us.Models
{
    public class Transaction
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string UserId { get; set; }
        
        [ForeignKey("UserId")]
        public virtual ApplicationUser User { get; set; }

        public string WalletId { get; set; }

        [ForeignKey("WalletId")]
        public virtual Wallet Wallet { get; set; }
        
        public int? OrderId { get; set; }

        [ForeignKey("OrderId")]
        public virtual Order Order { get; set; }
        
        [Required]
        [StringLength(50)]
        public string TransactionType { get; set; }
        
        [Required]
        public decimal Amount { get; set; }
        
        [Required]
        public decimal BalanceBefore { get; set; }
        
        [Required]
        public decimal BalanceAfter { get; set; }
        
        [StringLength(200)]
        public string Description { get; set; }
        
        public DateTime TransactionDate { get; set; }
        
        public Transaction()
        {
            TransactionDate = DateTime.Now;
        }
    }
}