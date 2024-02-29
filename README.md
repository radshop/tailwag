# tailwag

This Perl script selects a Tailscale exit node from the list of available nodes. For Tailscale users subscribing to Mullvad exit nodes, this is useful to easily change to another country or city, or randomly select from anywhere in the world.

Tailscale users can view the list of available exit nodes for their host by running `tailscale exit-node list`.

Notes:

* The country and city parameters use the code portions of the hostname. So for example, Manchester, UK, hosts follow the pattern `gb-mnc-wg-999.mullvad.ts.net`, in which the country code is 'gb' and the city code is 'mnc'.
* If the host is currently connected to an exit node, that node will not be reselect. If however, that results in an empty set of available nodes, the script will do nothing. For example, if there is only 1 node in Malmo and the user is connected to it, entering the parameter `--city mma` will do nothing because there's no other node to select.

Examples:

* `sudo ./tailwag.pl` randomly selects an online node from any country.
* `sudo ./tailwag.pl --country us` randomly selects an online node from the USA.
* `sudo ./tailwag.pl --city lax` randomly selects an online node with the city code of 'lax', which is Los Angeles.
* `sudo ./tailwag.pl --country gb --city lax` randomly selects an online node from the UK. If both parameters are provided, the script uses the country and ignores the city parameter.

This project is for use by customers of Tailscale. The developer not affiliated with Tailscale or Mullvad in any way other than as a licensed user.
