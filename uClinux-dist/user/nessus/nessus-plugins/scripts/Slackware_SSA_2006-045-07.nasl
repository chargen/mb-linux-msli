# This script was automatically generated from the SSA-2006-045-07
# Slackware Security Advisory
# It is released under the Nessus Script Licence.
# Slackware Security Advisories are copyright 1999-2004 Slackware Linux, Inc.
# SSA2nasl Convertor is copyright 2004 Michel Arboi
# See http://www.slackware.com/about/ or http://www.slackware.com/security/
# Slackware(R) is a registered trademark of Slackware Linux, Inc.

if (! defined_func("bn_random")) exit(0);
desc='
New php packages are available for Slackware 10.2 and -current to
fix minor security issues.

More details about these issues may be found on the PHP website:

  http://www.php.net/release_4_4_2.php


';
if (description) {
script_id(20918);
script_version("$Revision: 1.1 $");
script_category(ACT_GATHER_INFO);
script_family(english: "Slackware Local Security Checks");
script_dependencies("ssh_get_info.nasl");
script_copyright("This script is Copyright (C) 2006 Michel Arboi <mikhail@nessus.org>");
script_require_keys("Host/Slackware/release", "Host/Slackware/packages");
script_description(english: desc);

script_xref(name: "SSA", value: "2006-045-07");
script_summary("SSA-2006-045-07 php ");
name["english"] = "SSA-2006-045-07 php ";
script_name(english:name["english"]);
exit(0);
}

include('slackware.inc');
include('global_settings.inc');

if (slackware_check(osver: "10.2", pkgname: "php", pkgver: "4.4.2", pkgnum:  "3", pkgarch: "i486")) {
w++;
if (report_verbosity > 0) desc = strcat(desc, '
The package php is vulnerable in Slackware 10.2
Upgrade to php-4.4.2-i486-3 or newer.
');
}
if (slackware_check(osver: "-current", pkgname: "php", pkgver: "4.4.2", pkgnum:  "3", pkgarch: "i486")) {
w++;
if (report_verbosity > 0) desc = strcat(desc, '
The package php is vulnerable in Slackware -current
Upgrade to php-4.4.2-i486-3 or newer.
');
}

if (w) { security_hole(port: 0, data: desc); }
