using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Connect2Us.Models
{
    public class Wallet
    {
        [Key]
        [ForeignKey("User")]
        public string UserId { get; set; }

        public decimal Balance { get; set; }

        public virtual ApplicationUser User { get; set; }

        public virtual ICollection<Transaction> Transactions { get; set; }
    }
}