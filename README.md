# shinto

Shinto is a collections of commands that parses, and combines relevant
information for use in an incident response report. It was written to
aide in documenting that information which most DFIR individuals find
most helpful.

It will parse out system information, the date, time, and last logins of
users. The current connections as well as display the owner info associated
with those connections. Running processes, loaded modules, which files those
modules are accessing, and so forth. It also performs an md5 on all opened
files, in which if needed/desired, an analyst can check those hashes against
any database (virustotal, etc).

It lists any script running on startup (this is limited to files found in
/etc/rc.d and /usr/local/etc/rc.d 

Connection-wise, shinto parses through the output of applications, and
performs lookups using Shadowserver, whois as well as performs a traceroute
against the destination and source addresses. The reasoning for this is that
it allows an analyst to see what route a an application is taking, in the
event some funny routing/networking/tunneling has occurred.

Shinto was written for FreeBSD and has only been test on FreeBSD 5.4 and 9.0
It uses tools already available on the system without needing to install any
specific tool/language (ruby, python, etc.) with the exception of perl which
available by default on *most* installs. 

It is more or less a mechanism to do common commands in one fell swoop with
the output sent via email in a zip file, or the option to open in Firefox.
