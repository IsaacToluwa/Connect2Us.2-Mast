namespace Connect2Us.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class AlterDateColumnsToDateTime2 : DbMigration
    {
        public override void Up()
        {
            AlterColumn("dbo.Categories", "CreatedAt", c => c.DateTime(nullable: false, precision: 7, storeType: "datetime2"));
            AlterColumn("dbo.Categories", "UpdatedAt", c => c.DateTime(nullable: false, precision: 7, storeType: "datetime2"));
            AlterColumn("dbo.Products", "CreatedAt", c => c.DateTime(nullable: false, precision: 7, storeType: "datetime2"));
            AlterColumn("dbo.Products", "UpdatedAt", c => c.DateTime(precision: 7, storeType: "datetime2"));
        }
        
        public override void Down()
        {
            AlterColumn("dbo.Products", "UpdatedAt", c => c.DateTime());
            AlterColumn("dbo.Products", "CreatedAt", c => c.DateTime(nullable: false));
            AlterColumn("dbo.Categories", "UpdatedAt", c => c.DateTime(nullable: false));
            AlterColumn("dbo.Categories", "CreatedAt", c => c.DateTime(nullable: false));
        }
    }
}