namespace Connect2Us.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class FixBookstoreRoleAndWalletChanges : DbMigration
    {
        public override void Up()
        {
            // This migration primarily fixes role references and wallet functionality
            // Since AutomaticMigrationsEnabled is true, the schema changes should be handled automatically
            
            // Update any existing BookstoreOwner role references to Bookstore
            Sql(@"
                IF EXISTS (SELECT 1 FROM AspNetRoles WHERE Name = 'BookstoreOwner')
                BEGIN
                    UPDATE AspNetRoles SET Name = 'Bookstore', NormalizedName = 'BOOKSTORE' WHERE Name = 'BookstoreOwner'
                END
            ");
            
            // Ensure all Bookstore users have the correct role
            Sql(@"
                UPDATE AspNetUserRoles 
                SET RoleId = (SELECT Id FROM AspNetRoles WHERE Name = 'Bookstore')
                WHERE RoleId = (SELECT Id FROM AspNetRoles WHERE Name = 'BookstoreOwner')
            ");
            
            // Clean up any orphaned BookstoreOwner role
            Sql(@"
                DELETE FROM AspNetRoles WHERE Name = 'BookstoreOwner'
            ");
            
            // Ensure wallet table has proper constraints
            Sql(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
                               WHERE CONSTRAINT_NAME = 'FK_Wallets_AspNetUsers')
                BEGIN
                    ALTER TABLE Wallets
                    ADD CONSTRAINT FK_Wallets_AspNetUsers
                    FOREIGN KEY (UserId) REFERENCES AspNetUsers(Id)
                END
            ");
            
            // Ensure transactions table has proper constraints
            Sql(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
                               WHERE CONSTRAINT_NAME = 'FK_Transactions_Wallets')
                BEGIN
                    ALTER TABLE Transactions
                    ADD CONSTRAINT FK_Transactions_Wallets
                    FOREIGN KEY (WalletId) REFERENCES Wallets(Id)
                END
            ");
        }
        
        public override void Down()
        {
            // Revert changes if needed
            Sql(@"
                IF NOT EXISTS (SELECT 1 FROM AspNetRoles WHERE Name = 'BookstoreOwner')
                BEGIN
                    INSERT INTO AspNetRoles (Id, Name, NormalizedName) 
                    VALUES (NEWID(), 'BookstoreOwner', 'BOOKSTOREOWNER')
                END
            ");
        }
    }
}