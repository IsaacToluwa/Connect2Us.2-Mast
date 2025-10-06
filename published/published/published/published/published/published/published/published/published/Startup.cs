using Microsoft.Owin;
using Owin;

[assembly: OwinStartup(typeof(Connect2Us.Startup))]

namespace Connect2Us
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}