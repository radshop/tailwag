# tailwag

This Perl script is intended for use on Linux systems where the Tailscale client is installed and configured to use Mullvad exit nodes. It randomly selects a Tailscale exit node from the list of available nodes based on optional country and city parameters tied to the format of Mullvad country/city host names. For Tailscale users subscribing to Mullvad exit nodes, this is useful to easily change to another country or city, or randomly select from anywhere in the world.

Tailscale users can view the list of available exit nodes for their host by running `tailscale exit-node list`.

### Usage

```
tailwag [options]

Options:
  --country=CODE     Filter by country code (e.g., us, gb, de)
  --city=CODE        Filter by city code (e.g., lax, nyc, lon)
  --region=NAME      Filter by predefined region (e.g., uswest, europe)
  --named=HOSTNAME   Use specific exit node by hostname
  --off              Turn off exit node usage
  --list-regions     List all available regions
  --debug            Show debug information
  --help, -h         Show brief help message
  --man              Show full documentation
```

### Notes:

* I wrote this in Perl because it's ubiquitous and good for parsing, not because I'm a Perl expert. Set expectations accordingly.
* This is a pretty basic script developed for personal use and not intended to handle every possible scenario. For example, if the Tailscale client has both Mullvad and non-Mullvad exit nodes available, running the script with no parameters would presumably include the non-Mullvad exit nodes in the pool for selection. If country or city parameters are provided, unexpected results might occur if the host names accidentally match the provided pattern.
* The country and city parameters use the code portions of the hostname. So for example, Manchester, UK, hosts follow the pattern `gb-mnc-wg-999.mullvad.ts.net`, in which the country code is 'gb' and the city code is 'mnc'.
* There's no smart checking of the filter parameters. If the filters return no exit nodes, then the script does nothing.
* If the host is currently connected to an exit node, that node will not be reselected. If however, that results in an empty set of available nodes, the script will do nothing. For example, if there is only 1 node in Malmo and the user is connected to it, entering the parameter `--city mma` will do nothing because there's no other node to select.
* Because the script modifies the Tailscale configuration, in most cases it will need to be run as `sudo`.

### Examples:

* `sudo tailwag` randomly selects an online node from any country.
* `sudo tailwag --country us` randomly selects an online node from the USA.
* `sudo tailwag --city lax` randomly selects an online node with the city code of 'lax', which is Los Angeles.
* `sudo tailwag --region europe` randomly selects a node from European countries.
* `sudo tailwag --list-regions` shows all available regions.
* `sudo tailwag --named us-lax-wg-301.mullvad.ts.net` connects to a specific node.
* `sudo tailwag --off` disconnects from exit node (returns to direct connection).
* `tailwag --help` shows usage information.

This project is for use by customers of Tailscale. The developer not affiliated with Tailscale or Mullvad in any way other than as a licensed user.

### Configuration

Tailwag now supports custom regions via a configuration file at `~/.tailwag.conf`. The script comes with several built-in regions:

* **uswest**: US West Coast (lax, sjc, phx, sea, slc, den)
* **useast**: US East Coast (nyc, bos, atl, mia, ord, dfw)
* **europe**: European countries (gb, de, fr, nl, ch, se, no, fi, dk, es, it)
* **asia**: Asian countries (jp, sg, hk, tw, kr)
* **oceania**: Australia and New Zealand (au, nz)

You can override these or add your own regions by creating `~/.tailwag.conf`:

```bash
# Custom regions in ~/.tailwag.conf
favorites = ^(us-lax|gb-lon|nl-ams)
nordics = ^(se|no|fi|dk)
techcities = ^us-(sjc|sea|aus|bos)
```

See `.tailwag.conf.example` for more examples.

### Requirements

* Perl 5.x (standard on all Linux distributions)
* Tailscale installed and authenticated
* For Mullvad nodes: active Mullvad account linked to Tailscale
* Sudo/admin privileges to change exit nodes
