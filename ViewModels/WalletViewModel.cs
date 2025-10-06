using Connect2Us.Models;
using System.Collections.Generic;

namespace Connect2Us.ViewModels
{
    public class WalletViewModel
    {
        public Wallet Wallet { get; set; }
        public IEnumerable<Transaction> Transactions { get; set; }
    }
}