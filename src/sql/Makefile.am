## Makefile.am -- Process this file with automake to produce Makefile.in
## Copyright (C) 2002 G.J. Paulissen
##
## This library is free software; you can redistribute it and/or
## modify it under the terms of the GNU Lesser General Public
## License as published by the Free Software Foundation; either
## version 2.1 of the License, or (at your option) any later version.
##
## This library is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public
## License along with this library; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# for documentation purposes only
pod_scripts      = dbug.pod dbug_trigger.pod

html_files       = $(pod_scripts:.pod=.html)

sql_scripts      = 0001.TYPE_SPEC.STD_OBJECT.sql \
									 0002.TYPE_SPEC.DBUG_LOG4PLSQL_OBJ_T.sql \
									 0003.TYPE_SPEC.DBUG_CALL_OBJ_T.sql \
									 0004.TYPE_SPEC.DBUG_CALL_TAB_T.sql \
									 0005.TYPE_SPEC.DBUG_OBJ_T.sql \
									 0006.TABLE.STD_OBJECTS.sql \
									 0024.INDEX.STD_OBJECTS.sql \
									 0025.CONSTRAINT.STD_OBJECTS.sql \
									 R__0007.PACKAGE_SPEC.STD_OBJECT_MGR.sql \
									 R__0008.TYPE_BODY.STD_OBJECT.sql \
									 R__0009.TYPE_BODY.DBUG_LOG4PLSQL_OBJ_T.sql \
									 R__0010.PACKAGE_SPEC.DBUG.sql \
									 R__0011.TYPE_BODY.DBUG_OBJ_T.sql \
									 R__0012.PACKAGE_SPEC.DBUG_TRIGGER.sql \
									 R__0013.PACKAGE_SPEC.DBUG_PROFILER.sql \
									 R__0014.PACKAGE_SPEC.DBUG_LOG4PLSQL.sql \
									 R__0015.PACKAGE_SPEC.DBUG_DBMS_OUTPUT.sql \
									 R__0016.PACKAGE_SPEC.DBUG_DBMS_APPLICATION_INFO.sql \
									 R__0017.PACKAGE_BODY.STD_OBJECT_MGR.sql \
									 R__0018.PACKAGE_BODY.DBUG_TRIGGER.sql \
									 R__0019.PACKAGE_BODY.DBUG_PROFILER.sql \
									 R__0020.PACKAGE_BODY.DBUG_LOG4PLSQL.sql \
									 R__0021.PACKAGE_BODY.DBUG_DBMS_OUTPUT.sql \
									 R__0022.PACKAGE_BODY.DBUG_DBMS_APPLICATION_INFO.sql \
									 R__0023.PACKAGE_BODY.DBUG.sql \
									 R__0026.OBJECT_GRANT.DBUG_TRIGGER.sql \
									 R__0027.OBJECT_GRANT.DBUG.sql \
									 V20221202174525.0001__TYPE_SPEC.STD_OBJECT.sql \
									 V20221202174525.0002__TYPE_SPEC.DBUG_LOG4PLSQL_OBJ_T.sql \
									 V20221202174525.0003__TYPE_SPEC.DBUG_CALL_OBJ_T.sql \
									 V20221202174525.0004__TYPE_SPEC.DBUG_CALL_TAB_T.sql \
									 V20221202174525.0005__TYPE_SPEC.DBUG_OBJ_T.sql \
									 V20221202174525.0006__TABLE.STD_OBJECTS.sql \
									 V20221202174525.0024__INDEX.STD_OBJECTS.sql \
									 V20221202174525.0025__CONSTRAINT.STD_OBJECTS.sql \
                   install.sql \
                   uninstall.sql

SUBDIRS          = .

noinst_DATA      = $(html_files)

MOSTLYCLEANFILES = $(html_files)

CLEANFILES       = pod*.tmp

EXTRA_DIST       = $(pod_scripts) \
                   $(html_files) \
                   $(sql_scripts)

POD2HTML        := pod2html

@SUFFIXES@: .pod .html

html: $(html_files)

.pod.html:
	sed 's/-- =pod/=pod/g;s/-- =cut/=cut/g' $? | @PERL@ -S $(POD2HTML) --outfile=$@
