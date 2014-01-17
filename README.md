CLI wrapper script for Opsview

Allows for execution of common Opsview tasks from the command line. Great for Bash scripting, etc.

Author: Timothy Patterson <tim@pc-professionals.net>
Date: 2014-01-17

Requires: Perl 5.10.0 or higher
          Opsview::REST (found on CPAN)
          Getopt::Mixed (found on CPAN)
          Config:IniFiles (found on CPAN)

Thanks go out to Miquel Ruiz <mruiz@cpan.org> for his work on the Opsview::REST module, and to Fabien Cortina <freongrr on GitHub> for his OpsView::Printer module.



Overview:
This tool allows an administrator to script various Opsview operations en-masse and also enables integration with various other systems that can make system calls.

 
Usage:
To use the Opsview CLI utility, you simply call it from the command line.  By calling it without any arguments, usage information is displayed as follows:




opsview [-p <config file profile name>] [-o | --op <operation>] <operation specific parameters>

Code version: 0.6 (2014-01-17)

-p <config file profile name>  This parameter determines which profile to use from the  ~/.opsview-wrapper file.
                               That file should contain authentication information, as well as which Opsview server
                               to use. For more information, refer to the complete documentation.

Operation:                 Parameters:                 Description:
----------                 -----------                 ------------
host-status                -n <hostname>               Displays the status of a given host.
viewport-status                                        Displays the status of the viewport.
hostgroup-status           -i <hostgroup id>           Displays the status of the specified hostgroup.
                                                       You can optionally specifiy a parent hostgroup ID.
disable-host-alerts        -n <hostname>               Places the specified host into downtime for the
                           -t <time in mins>           specified number of minutes.
                           -c <comment>
enable-host-alerts         -n <hostname>               Brings the specified host out of downtime.
disable-hostgroup-alerts   -n <hostgroup>              Places the specified hostgroup into downtime for the
                           -t <time in mins>           specified number of minutes.
                           -c <comment>
enable-hostgroup-alerts    -n <hostgroup>              Brings the specified hostgroup out of downtime.
clone-host                 -n <source hostname>        Clones an existing host to a new host entry.
                           -d <destination hostname>
                           -i <destination ip address>
create-host                -n <hostname>               Creates a new host. Name and IP address are
                           -i <ip address>             required.
delete-host                -n <hostname>               Deletes the specified host.
ack-host                   -n <hostname>               Acknolwedges all failed services on the specified
                           -a <notify (1 or 0)>        host. You can optionally set the notify and/or
                           -s <sticky (1 or 0)>        bits.  A comment is required.
                           -c <comment>
ack-service                -n <hostname>               Acknolwedges the specified service on the specified
                           -v <service>                host. You can optionally set the notify and/or
                           -a <notify (1 or 0)>        bits.  A comment is required.
                           -s <sticky (1 or 0)>
                           -c <comment>
get-host-id                -n <hostname>               Retrieves internal Opsview ID for specified hostname.



Setup: 
Before you can start using the Opsview CLI utility, you need to set up at least one server profile.  A server profile contains the URL to the Opsview REST API as well as your authentication information.  This file must reside in your user home directory and have the name '.opsview-wrapper' (i.e. ~/.opsview-wrapper).  This file must be structured as follows:
 
[default]
base_url=http://<URL to Opsview>/rest
username=<your username>
password=<your password>
 
[prod]
base_url=http://<URL to Opsview>/rest
username=<your username>
password=<your password>
 
You can have as many profiles in the .opsview-wrapper file as necessary.  You must have at least the default profile defined.  You can choose which profile to run the Opsview CLI command against with the -p or --profile command-line parameter.  If you do not specify a profile, the default profile is used.



Examples:

Example 1 -- Getting host status from the 'production' Opsview environment:
$ ./opsview -p prod --op host-status -n aacompute01-esxi001.domain.local
 Name                         Alias              State  Ok  Warning  Critical
 aacompute01-esxi001.domain.local  Cisco UCS B200 M3  up     1   0 (0)    0 (0)


Example 2 -- Getting status of all hostgroups from the 'sandbox' (default profile) Opsview environment:

$ ./opsview -p default --op hostgroup-status
 Id  Name                        State     Down   Warning  Critical
 1   Opsview                     critical  0 (0)  3 (1)    3 (2)
 3     789                       critical  0 (0)  0 (1)    0 (1)
 4       789 Linux Servers       critical  0 (0)  0 (1)    0 (1)
 20    789 Appliance             critical  0 (0)  0 (0)    1 (0)
 6     AWS US-EAST-1             ok        0 (0)  0 (0)    0 (0)
 7     DC4                       critical  0 (0)  0 (0)    1 (0)
 12      DC4 Windows Servers     ok        0 (0)  0 (0)    0 (0)
 18    789 Network               ok        0 (0)  0 (0)    0 (0)
 19    DC4 Linux Servers         critical  0 (0)  0 (0)    1 (0)


Example 3 -- Getting status of a specific hostgroup from the 'sandbox' (default profile) Opsview environment:
Note:  This command uses the ID from the output of the previous command.

$ ./opsview -p default --op hostgroup-status -i 7
 Id  Name  State     Down   Warning  Critical
 7   DC4   critical  0 (0)  0 (0)    1 (0)


Example 4 -- Putting a specific host into downtime (prod profile):

$ ./opsview -p prod --op disable-host-alerts -n aacompute01-esxi001.domain.local -t 5 -c "General maintenance"
Alerts have been disabled on aacompute01-esxi001.domain.local for 5 minutes. Reason: 'General maintenance'.


Example 5 -- Removing downtime from a specific host (prod profile):

$ ./opsview -p prod --op enable-host-alerts -n aacompute01-esxi001.domain.local
Alerts have been enabled on aacompute01-esxi001.domain.local.


Example 6 -- Acknowledging all down services for a specific host (prod profile):

$ ./opsview -p prod --op ack-host -n itawsdns-us-east-1a-101.aws.pqe -c "Working on issue."
All service failures on host itawsdns-us-east-1a-101.aws.pqe have been acknowledged.


Example 7 -- Acknowledging a specific service on a specific host (prod profile):

$ ./opsview -p prod --op ack-service -n ebsdb201.domain.local -v "SVC - NTP Local Time Sync" -c "Scripted ack."
Successfully acknowledged service SVC - NTP Local Time Sync on ebsdb201.domain.local. Reason: Scripted ack.


Example 8 -- Cloning a host to a new host (prod profile):

$ ./opsview -p prod --op clone-host -n aacompute01-esxi001.domain.local -d aacompute02-esxi001.domain.local -i 172.26.205.205
Cloning aacompute01-esxi001.domain.local to aacompute02-esxi001.domain.local at 172.26.205.205 was successful.


Example 9 -- Deleting a host (prod profile):

$ ./opsview -p prod --op delete-host -n aacompute02-esxi001.domain.local
Deleting host aacompute02-esxi001.domain.local was successful.

