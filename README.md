Description
===========
Installs Artifactory repository manager.<br>
For the moment only runs on CentOS.<br> 
If someone finds that worth and wants to contribute is welcome.

Requirements
============
- Java<br>
- MySQL server (recommended)

Attributes
==========
Check the default attributes and set them according to your needs.<br>
To change the version just modify ```default[:artifactory][:ver]``` on the default attributes file.

Usage
=====
The recipe will download and install the Open Source rpm from SourceForge.
If the MySQL server is installed, the recipe is going to create the database and configuration files.

