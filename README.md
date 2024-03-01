# tailwag

This Perl script is intended for use on Linux systems where the Tailscale client is installed and configured to use Mullvad exit nodes. It randomly selects a Tailscale exit node from the list of available nodes based on optional country and city parameters tied to the format of Mullvad country/city host names. For Tailscale users subscribing to Mullvad exit nodes, this is useful to easily change to another country or city, or randomly select from anywhere in the world.

Tailscale users can view the list of available exit nodes for their host by running `tailscale exit-node list`.

Optional parameters

* --country [country code]
* --city [city code]
* --region [uswest] (currently uswest is the only region defined)
* --debug (flag to output the list of hostnames)

Notes:

* This is a pretty basic script developed for personal use and not intended to handle every possible scenario. For example, if the Tailscale client has both Mullvad and non-Mullvad exit nodes available, running the script with no parameters would presumably include the non-Mullvad exit nodes in the pool for selection. If country or city parameters are provided, unexpected results might occur if the host names accidentally match the provided pattern.
* The country and city parameters use the code portions of the hostname. So for example, Manchester, UK, hosts follow the pattern `gb-mnc-wg-999.mullvad.ts.net`, in which the country code is 'gb' and the city code is 'mnc'.
* There's no smart checking of the filter parameters. If the filters return no exit nodes, then the script does nothing.
* If the host is currently connected to an exit node, that node will not be reselected. If however, that results in an empty set of available nodes, the script will do nothing. For example, if there is only 1 node in Malmo and the user is connected to it, entering the parameter `--city mma` will do nothing because there's no other node to select.
* Because the script modifies the Tailscale configuration, in most cases it will need to be run as `sudo`

Examples:

* `sudo ./tailwag.pl` randomly selects an online node from any country.
* `sudo ./tailwag.pl --country us` randomly selects an online node from the USA.
* `sudo ./tailwag.pl --city lax` randomly selects an online node with the city code of 'lax', which is Los Angeles.
* `sudo ./tailwag.pl --country gb --city lax` does nothing because there is no 'lax' city i the UK

This project is for use by customers of Tailscale. The developer not affiliated with Tailscale or Mullvad in any way other than as a licensed user.
