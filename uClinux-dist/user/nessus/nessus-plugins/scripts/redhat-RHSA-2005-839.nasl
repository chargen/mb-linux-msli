#
# (C) Tenable Network Security
#
#
# The text of this plugin is (C) Red Hat Inc.

if ( ! defined_func("bn_random") ) exit(0);
if(description)
{
 script_id(20208);
 script_version ("$Revision: 1.1 $");
 script_cve_id("CVE-2005-2929");

 name["english"] = "RHSA-2005-839: lynx";
 
 script_name(english:name["english"]);
 
 desc["english"] = '

  An updated lynx package that corrects a security flaw is now available.

  This update has been rated as having critical security impact by the Red
  Hat Security Response Team.

  Lynx is a text-based Web browser.

  An arbitrary command execute bug was found in the lynx "lynxcgi:" URI
  handler. An attacker could create a web page redirecting to a malicious URL
  which could execute arbitrary code as the user running lynx. The Common
  Vulnerabilities and Exposures project assigned the name CVE-2005-2929 to
  this issue.

  Users should update to this erratum package, which contains a backported
  patch to correct this issue.




Solution : http://rhn.redhat.com/errata/RHSA-2005-839.html
Risk factor : High';

 script_description(english:desc["english"]);
 
 summary["english"] = "Check for the version of the lynx packages";
 script_summary(english:summary["english"]);
 
 script_category(ACT_GATHER_INFO);
 
 script_copyright(english:"This script is Copyright (C) 2005 Tenable Network Security");
 family["english"] = "Red Hat Local Security Checks";
 script_family(english:family["english"]);
 
 script_dependencies("ssh_get_info.nasl");
 
 script_require_keys("Host/RedHat/rpm-list");
 exit(0);
}

include("rpm.inc");
if ( rpm_check( reference:"lynx-2.8.4-18.1.2", release:"RHEL2.1") )
{
 security_hole(0);
 exit(0);
}
if ( rpm_check( reference:"lynx-2.8.5-11.2", release:"RHEL3") )
{
 security_hole(0);
 exit(0);
}
if ( rpm_check( reference:"lynx-2.8.5-18.2", release:"RHEL4") )
{
 security_hole(0);
 exit(0);
}

if ( rpm_exists(rpm:"lynx-", release:"RHEL2.1") )
{
 set_kb_item(name:"CVE-2005-2929", value:TRUE);
}
if ( rpm_exists(rpm:"lynx-", release:"RHEL3") )
{
 set_kb_item(name:"CVE-2005-2929", value:TRUE);
}
if ( rpm_exists(rpm:"lynx-", release:"RHEL4") )
{
 set_kb_item(name:"CVE-2005-2929", value:TRUE);
}

set_kb_item(name:"RHSA-2005-839", value:TRUE);
