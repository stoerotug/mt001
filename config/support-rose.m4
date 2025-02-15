
#-----------------------------------------------------------------------------
AC_DEFUN([ROSE_SUPPORT_ROSE_PART_1],
[
# Begin macro ROSE_SUPPORT_ROSE_PART_1.

# *********************************************************************
# This macro encapsulates the complexity of the tests required for ROSE
# to understnd the machine environment and the configure command line.
# It is represented a s single macro so that we can simplify the ROSE
# configure.in and permit other external project to call this macro as 
# a way to set up there environment and define the many macros that an
# application using ROSE might require.
# *********************************************************************

# DQ (2/11/2010): Jeremiah reported this as bad syntax, I think he is correct.
# I'm not sure how this made it into this file.
# AMTAR ?= $(TAR)
AMTAR = $(TAR)

# DQ (9/9/2009): Added output to test values of am__tar and am__untar (fails on nmi:x86_sles_9).
echo "Defined: am__tar   = $am__tar"
echo "Defined: am__untar = $am__untar"
echo "Defined: AMTAR     = $AMTAR"

# DQ (9/9/2009): Added test.
if test "$am__tar" = "false"; then
   echo "am__tar set to false -- this will be a problem later."
   exit 1
fi

# DQ (9/9/2009): Added test.
if test "$am__untar" = "false"; then
   echo "am__untar set to false -- this will be a problem later."
   exit 1
fi

# DQ (3/20/2009): Trying to get information about what system we are on so that I
# can detect Cygwin and OSX (and other operating systems in the future).
AC_CANONICAL_BUILD
# AC_CANONICAL_HOST
# AC_CANONICAL_TARGET

AC_MSG_CHECKING([machine hardware cpu])
AC_MSG_RESULT([$build_cpu])

AC_MSG_CHECKING([operating system vendor])
AC_MSG_RESULT([$build_vendor])

AC_MSG_CHECKING([operating system])
AC_MSG_RESULT([$build_os])

DETERMINE_OS

# DQ (3/20/2009): The default is to assume Linux, so skip supporting this test.
# AM_CONDITIONAL(ROSE_BUILD_OS_IS_LINUX,  [test "x$build_os" = xlinux-gnu])
AM_CONDITIONAL(ROSE_BUILD_OS_IS_OSX,    [test "x$build_vendor" = xapple])
AM_CONDITIONAL(ROSE_BUILD_OS_IS_CYGWIN, [test "x$build_os" = xcygwin])

# DQ (9/10/2009): A more agressive attempt to identify the OS vendor
# This sets up automake conditional variables for each OS vendor name.
DETERMINE_OS_VENDOR

# This appears to be a problem for Java (and so the Fortran support).
# CHECK_SSL
ROSE_SUPPORT_SSL

# Need the SSL automake conditional so that libssl can be added selectively for only those
# translators that require it (since it conflicts with use of Java, and thus Fortran support).
AM_CONDITIONAL(ROSE_USE_SSL_SUPPORT, [test "x$enable_ssl" = xyes])

configure_date=`date '+%A %B %e %H:%M:%S %Y'`
AC_SUBST(configure_date)
# echo "In ROSE/con figure: configure_date = $configure_date"

# DQ (1/27/2008): Added based on suggestion by Andreas.  This allows
# the binary analysis to have more specific information. However, it
# appears that it requires version 2.61 of autoconf and we are using 2.59.
# echo "$host_cpu"
# echo "host_cpu = $host_cpu"
# echo "host_vendor = $host_vendor"
# echo "ac_cv_host = $ac_cv_host"
# echo "host = $host"
# This does not currently work - I don't know why!
# AC_DEFINE([ROSE_HOST_CPU],$host_cpu,[Machine CPU Name where ROSE was configured.])

# DQ (9/7/2006): Allow the default prefix to be the current build tree
# This does not appear to work properly
# AC_PREFIX_DEFAULT(`pwd`)

# echo "In configure: prefix = $prefix"
# echo "In configure: pwd = $PWD"

if test "$prefix" = NONE; then
   echo "Setting prefix to default: $PWD"
   prefix="$PWD"
fi

# DQ & PC (11/3/2009): Debugging the Java support.
if false; then
  if test "x$JAVA_HOME" = "x"; then
    JAVA="`which javac`"
    if test -f /usr/bin/javaconfig; then # Mac Java
      :
    else
      while test `readlink "$JAVA"` ; do
        JAVA=`readlink "$JAVA"` ;
     done

     if test $JAVA = "gcj"; then
        AC_MSG_ERROR( "Error: gcj not supported. Please configure sun java as javac" );
     fi

    fi
    JAVA_HOME="`dirname $JAVA`/.."
  fi
fi

# Call supporting macro for the Java path required by the Open Fortran Parser (for Fortran 2003 support)
# Use our classpath in case the user's is messed up
AS_SET_CATFILE([ABSOLUTE_SRCDIR], [`pwd`], [${srcdir}])

# Check for Java support used internally to support both the Fortran language (OFP fortran parser) and Java language (ECJ java parser).
ROSE_SUPPORT_JAVA # This macro uses JAVA_HOME

# DQ (10/18/2010): Check for gfortran (required for syntax checking and semantic analysis of input Fortran codes)
AX_WITH_PROG(GFORTRAN_PATH, [gfortran], [])
AC_SUBST(GFORTRAN_PATH)

if test "x$GFORTRAN_PATH" != "x"; then
   AC_DEFINE([USE_GFORTRAN_IN_ROSE], [1], [Mark that GFORTRAN is available])
fi

#########################################################################################
##

  ROSE_SUPPORT_LANGUAGE_CONFIG_OPTIONS
  AC_CHECK_LIB([curl], [Curl_connect], [HAVE_CURL=yes], [HAVE_CURL=no])
  AM_CONDITIONAL([HAS_LIBRARY_CURL], [test "x$HAVE_CURL" = "xyes"])

AC_MSG_CHECKING([whether your GCC version is supported by ROSE (4.0.x - 4.4.x)])
AC_ARG_ENABLE([gcc-version-check],AS_HELP_STRING([--disable-gcc-version-check],[Disable GCC version 4.0.x - 4.4.x verification check]),,[enableval=yes])
if test "x$enableval" = "xyes" ; then
      AC_LANG_PUSH([C])
      # http://www.gnu.org/s/hello/manual/autoconf/Running-the-Compiler.html
      AC_COMPILE_IFELSE([
        AC_LANG_SOURCE([[
          #if (__GNUC__ >= 4 && __GNUC_MINOR__ <= 4)
            int rose_supported_gcc;
          #else
            not gcc, or gcc version is not supported by rose
          #endif
        ]])
       ],
       [AC_MSG_RESULT([done])],
       gcc_version=`gcc -dumpversion`
       [AC_MSG_FAILURE([your GCC $gcc_version version is currently NOT supported by ROSE. GCC 4.0.x to 4.4.x is supported now.])])
      AC_LANG_POP([C])
else
    AC_MSG_RESULT([skipping])
fi

  ROSE_SUPPORT_UPC
  ROSE_SUPPORT_COMPASS2
  ROSE_SUPPORT_GMP
  ROSE_SUPPORT_ISL
  ROSE_SUPPORT_MPI

##
#########################################################################################

# *******************************************************
# ROSE/projects directory compilation & testing
# *******************************************************
AC_MSG_CHECKING([if we should build & test the ROSE/projects directory])
AC_ARG_ENABLE([projects-directory],AS_HELP_STRING([--disable-projects-directory],[Disable compilation and testing of the ROSE/projects directory]),[],[enableval=yes])
support_projects_directory=yes
if test "x$enableval" = "xyes"; then
   support_projects_directory=yes
   AC_MSG_RESULT(enabled)
   AC_DEFINE([ROSE_BUILD_PROJECTS_DIRECTORY_SUPPORT], [], [Build ROSE projects directory])
else
   support_projects_directory=no
   AC_MSG_RESULT(disabled)
fi
AM_CONDITIONAL(ROSE_BUILD_PROJECTS_DIRECTORY_SUPPORT, [test "x$support_projects_directory" = xyes])
# ****************************************************
# ROSE/tests directory compilation & testing 
# ****************************************************
AC_MSG_CHECKING([if we should build & test the ROSE/tests directory])
AC_ARG_ENABLE([tests-directory],AS_HELP_STRING([--disable-tests-directory],[Disable compilation and testing of the ROSE/tests directory]),[],[enableval=yes])
support_tests_directory=yes
if test "x$enableval" = "xyes"; then
   support_tests_directory=yes
   AC_MSG_RESULT(enabled)
   AC_DEFINE([ROSE_BUILD_TESTS_DIRECTORY_SUPPORT], [], [Build ROSE tests directory])
else
   support_tests_directory=no
   AC_MSG_RESULT(disabled)
fi
AM_CONDITIONAL(ROSE_BUILD_TESTS_DIRECTORY_SUPPORT, [test "x$support_tests_directory" = xyes])
# *******************************************************
# ROSE/tutorial directory compilation & testing
# *******************************************************
AC_MSG_CHECKING([if we should build & test the ROSE/tutorial directory])
AC_ARG_ENABLE([tutorial-directory],AS_HELP_STRING([--disable-tutorial-directory],[Disable compilation and testing of the ROSE/tutorial directory]),[],[enableval=yes])
support_tutorial_directory=yes
if test "x$enableval" = "xyes"; then
   support_tutorial_directory=yes
   AC_MSG_RESULT(enabled)
   AC_DEFINE([ROSE_BUILD_TUTORIAL_DIRECTORY_SUPPORT], [], [Build ROSE tutorial directory])
else
   support_tutorial_directory=no
   AC_MSG_RESULT(disabled)
fi
AM_CONDITIONAL(ROSE_BUILD_TUTORIAL_DIRECTORY_SUPPORT, [test "x$support_tutorial_directory" = xyes])

# ************************************************************
# Option to control the size of the generated files by ROSETTA
# ************************************************************

# DQ (12/29/2009): This is part of optional support to reduce the sizes of some of the ROSETTA generated files.
AC_ARG_ENABLE(smallerGeneratedFiles, AS_HELP_STRING([--enable-smaller-generated-files], [ROSETTA generates smaller files (but more of them so it takes longer to compile)]))
AM_CONDITIONAL(ROSE_USE_SMALLER_GENERATED_FILES, [test "x$enable_smaller_generated_files" = xyes])
if test "x$enable_smaller_generated_files" = "xyes"; then
  AC_MSG_WARN([Using optional ROSETTA mechanim to generate numerous but smaller files for the ROSE IR.])
  AC_DEFINE([ROSE_USE_SMALLER_GENERATED_FILES], [], [Whether to use smaller (but more numerous) generated files for the ROSE IR])
fi


# JJW: This needs to be early as things like C++ header editing are not done for the new interface
# AC_ARG_ENABLE(new-edg-interface, AS_HELP_STRING([--enable-new-edg-interface], [Enable new (experimental) translator from EDG ASTs to Sage ASTs]))
# AM_CONDITIONAL(ROSE_USE_NEW_EDG_INTERFACE, [test "x$enable_new_edg_interface" = xyes])
# if test "x$enable_new_edg_interface" = "xyes"; then
#   AC_MSG_WARN([Using newest version of interface to translate EDG to ROSE (experimental)!])
#   AC_DEFINE([ROSE_USE_NEW_EDG_INTERFACE], [], [Whether to use the new interface to EDG])
# fi

# DQ (12/29/2008): the default is new EDG interface is 3.10, this option permits the use
# of the newer EDG 4.0 interface (which breaks some existing work).
# AC_ARG_ENABLE(edg-version4, AS_HELP_STRING([--enable-edg-version4], [Enable newest EDG version 4 (requires --enable-new-edg-interface option)]))
# AM_CONDITIONAL(ROSE_USE_EDG_VERSION_4, [test "x$enable_edg_version4" = xyes])
# if test "x$enable_edg_version4" = "xyes"; then
#   AC_MSG_WARN([Using newest EDG version 4.x (requires new interface) to translate EDG to ROSE (experimental)!])
#   AC_DEFINE([ROSE_USE_EDG_VERSION_4], [], [Whether to use the new EDG version 4.x])
# fi

# DQ (11/14/2011): Added new configure mode to support faster development of langauge specific 
# frontend support (e.g. for work on new EDG 4.3 front-end integration into ROSE).
AC_ARG_ENABLE(internalFrontendDevelopment, AS_HELP_STRING([--enable-internalFrontendDevelopment], [Enable development mode to reduce files required to support work on language frontends]))
AM_CONDITIONAL(ROSE_USE_INTERNAL_FRONTEND_DEVELOPMENT, [test "x$enable_internalFrontendDevelopment" = xyes])
if test "x$enable_internalFrontendDevelopment" = "xyes"; then
  AC_MSG_WARN([Using reduced set of files to support faster development of language frontend work; e.g. new EDG version 4.3 to translate EDG to ROSE (internal use only)!])

# DQ (11/14/2011): It is not good enough for this to be processed here (added to the rose_config.h file) 
# since it is seen too late in the process.
# AC_DEFINE([ROSE_USE_INTERNAL_FRONTEND_DEVELOPMENT], [], [Whether to use internal reduced mode to support integration of the new EDG version 4.x])
fi

# DQ (2/2/2010): New code to control use of different versions of EDG with ROSE.
AC_ARG_ENABLE(edg-version,
[  --enable-edg_version     major.minor version number for EDG (e.g. 3.3, 3.10, 4.0, 4.1).],
[ echo "Setting up EDG version"
])

# AM_CONDITIONAL(DOT_TO_GML_TRANSLATOR,test "$enable_dot2gml_translator" = yes)
echo "enable_edg_version = $enable_edg_version"
if test "x$enable_edg_version" = "x"; then
   echo "Default version of EDG used (3.3)"
   edg_major_version_number=3
   edg_minor_version_number=3
else
   edg_major_version_number=`echo $enable_edg_version | cut -d\. -f1`
   edg_minor_version_number=`echo $enable_edg_version | cut -d\. -f2`
fi

echo "edg_major_version_number = $edg_major_version_number"
echo "edg_minor_version_number = $edg_minor_version_number"

if test "x$edg_major_version_number" = "x3"; then
   echo "Recognized an accepted major version number."
   if test "x$edg_minor_version_number" = "x3"; then
      echo "Recognized an accepted minor version number."
   else
      if test "x$edg_minor_version_number" = "x10"; then
         echo "ERROR: EDG version 3.10 is not supported anymore."
      else
         echo "ERROR: Could not identify the EDG minor version number."
         exit 1
      fi
      enable_new_edg_interface=yes
      AC_DEFINE([ROSE_USE_NEW_EDG_INTERFACE], [], [Whether to use the new interface to EDG])
   fi
else
   if test "x$edg_major_version_number" = "x4"; then
      echo "Recognized an accepted major version number."
      if test "x$edg_minor_version_number" = "x0"; then
         echo "Recognized an accepted minor version number."
      else
         if test "x$edg_minor_version_number" = "x3"; then
            echo "Recognized an accepted minor version number."
            enable_edg_version43=yes
            AC_DEFINE([ROSE_USE_EDG_VERSION_4_3], [], [Whether to use the new EDG version 4.3])
         else
            echo "ERROR: Could not identify the EDG minor version number."
            exit 1
         fi
      fi
      enable_edg_version4=yes
      AC_DEFINE([ROSE_USE_EDG_VERSION_4], [], [Whether to use the new EDG version 4.x])
      enable_new_edg_interface=yes
      AC_DEFINE([ROSE_USE_NEW_EDG_INTERFACE], [], [Whether to use the new interface to EDG])
   else
      echo "ERROR: Could not identify the EDG major version number."
      exit 1
   fi
fi

AC_DEFINE_UNQUOTED([ROSE_EDG_MAJOR_VERSION_NUMBER], $edg_major_version_number , [EDG major version number])
AC_DEFINE_UNQUOTED([ROSE_EDG_MINOR_VERSION_NUMBER], $edg_minor_version_number , [EDG minor version number])

ROSE_EDG_MAJOR_VERSION_NUMBER=$edg_major_version_number
ROSE_EDG_MINOR_VERSION_NUMBER=$edg_minor_version_number

AC_SUBST(ROSE_EDG_MAJOR_VERSION_NUMBER)
AC_SUBST(ROSE_EDG_MINOR_VERSION_NUMBER)

# DQ (2/3/2010): I would like to not have to use these and use the new 
# ROSE_EDG_MAJOR_VERSION_NUMBER and ROSE_EDG_MINOR_VERSION_NUMBER instead.
AM_CONDITIONAL(ROSE_USE_NEW_EDG_INTERFACE, [test "x$enable_new_edg_interface" = xyes])
AM_CONDITIONAL(ROSE_USE_EDG_VERSION_4, [test "x$enable_edg_version4" = xyes])
AM_CONDITIONAL(ROSE_USE_EDG_VERSION_4_3, [test "x$enable_edg_version43" = xyes])

ROSE_SUPPORT_CLANG

# DQ (1/4/2009) Added support for optional GNU language extensions in new EDG/ROSE interface.
# This value will be substituted into EDG/4.0/src/rose_lang_feat.h in the future (not used at present!)
AC_ARG_ENABLE(gnu-extensions, AS_HELP_STRING([--enable-gnu-extensions], [Enable internal support in ROSE for GNU language extensions]))
if test "x$enable_gnu_extensions" = "xyes"; then
  ROSE_SUPPORT_GNU_EXTENSIONS="TRUE"
else
  ROSE_SUPPORT_GNU_EXTENSIONS="FALSE"
fi
AC_SUBST(ROSE_SUPPORT_GNU_EXTENSIONS)

# DQ (1/4/2009) Added support for optional Microsoft language extensions in new EDG/ROSE interface.
# This value will be substituted into EDG/4.0/src/rose_lang_feat.h in the future (not used at present!)
AC_ARG_ENABLE(microsoft-extensions, AS_HELP_STRING([--enable-microsoft-extensions], [Enable internal support in ROSE for Microsoft language extensions]))
if test "x$enable_microsoft_extensions" = "xyes"; then
  ROSE_SUPPORT_MICROSOFT_EXTENSIONS="TRUE"
else
  ROSE_SUPPORT_MICROSOFT_EXTENSIONS="FALSE"
fi
AC_SUBST(ROSE_SUPPORT_MICROSOFT_EXTENSIONS)


# DQ (8/18/2009): Removed this conditional macro.
# DQ (4/23/2009): Added support for commandline specification of using new graph IR nodes.
# AC_ARG_ENABLE(newGraphNodes, AS_HELP_STRING([--enable-newGraphNodes], [Enable new (experimental) graph IR nodes]))
#AM_CONDITIONAL(ROSE_USE_NEW_GRAPH_NODES, [test "x$enable_newGraphNodes" = xyes])
#if test "x$enable_newGraphNodes" = "xyes"; then
#  AC_MSG_WARN([Using the new graph IR nodes in ROSE (experimental)!])
#  AC_DEFINE([ROSE_USE_NEW_GRAPH_NODES], [], [Whether to use the new graph IR nodes])
#fi

# DQ (5/2/2009): Added support for backward compatability of new IR nodes with older API.
AC_ARG_ENABLE(use_new_graph_node_backward_compatability,
    AS_HELP_STRING([--enable-use_new_graph_node_backward_compatability], [Enable new (experimental) graph IR nodes backward compatability API]))
AM_CONDITIONAL(ROSE_USING_GRAPH_IR_NODES_FOR_BACKWARD_COMPATABILITY, [test "x$enable_use_new_graph_node_backward_compatability" = xyes])
if test "x$enable_use_new_graph_node_backward_compatability" = "xyes"; then
  AC_MSG_WARN([Using the new graph IR nodes in ROSE (experimental)!])
  AC_DEFINE([ROSE_USING_GRAPH_IR_NODES_FOR_BACKWARD_COMPATABILITY], [], [Whether to use the new graph IR nodes compatability option with older API])
fi


# Set up for use of bison to build dot2gml tool in directory
# src/roseIndependentSupport/dot2gml.  This is made optional
# because it seems that many don't have the correct version of bison
# to support the compilation of this tool.  This is it is a configure
# option to build it (or have the makefile system have it be built).
AC_ARG_ENABLE(dot2gml_translator,
[  --enable-dot2gml_translator   Configure option to have DOT to GML translator built (bison version specific tool).],
[ echo "Setting up optional DOT-to-GML translator in directory: src/roseIndependentSupport/dot2gml"
])
AM_CONDITIONAL(DOT_TO_GML_TRANSLATOR,test "$enable_dot2gml_translator" = yes)

# Set the value of srcdir so that it will be an absolute path instead of a relative path
# srcdir=`dirname "$0"`
# echo "In ROSE/con figure: srcdir = $srcdir"
# echo "In ROSE/con figure: $0"
# Record the location of the build tree (so it can be substituted into ROSE/docs/Rose/rose.cfg)
# topSourceDirectory=`dirname "$0"`
# echo "In ROSE/con figure: topSourceDirectory = $topSourceDirectory"
# AC_SUBST(topSourceDirectory)

# echo "Before test for CANONICAL HOST: CC (CC = $CC)"

AC_CANONICAL_HOST

ROSE_FLAG_C_OPTIONS
ROSE_FLAG_CXX_OPTIONS

# DQ (11/14/2011): This is defined here since it must be seen before any processing of the rose_config.h file.
if test "x$enable_internalFrontendDevelopment" = "xyes"; then
  AC_MSG_NOTICE([Adding -D to command line to support faster development of language frontend work.])
  CFLAGS+=" -DROSE_USE_INTERNAL_FRONTEND_DEVELOPMENT"
  CXXFLAGS+=" -DROSE_USE_INTERNAL_FRONTEND_DEVELOPMENT"
fi

echo "CFLAGS   = $CFLAGS"
echo "CXXFLAGS = $CXXFLAGS"
echo "CPPFLAGS = $CPPFLAGS"

# *****************************************************************
#    Option to define a uniform debug level for ROSE development
# *****************************************************************

# DQ (10/17/2010): This defines an advanced level of uniform support for debugging and compiler warnings in ROSE.
AC_MSG_CHECKING([for enabled advanced warning support])
# Default is that advanced warnings is off, but this can be changed later so that advanced warnings would have to be explicitly turned off.
AC_ARG_ENABLE(advanced_warnings, AS_HELP_STRING([--enable-advanced-warnings], [Support for an advanced uniform warning level for ROSE development]),[enableval=yes],[enableval=no])
AM_CONDITIONAL(ROSE_USE_UNIFORM_ADVANCED_WARNINGS_SUPPORT, [test "x$enable_advanced_warnings" = xyes])
if test "x$enable_advanced_warnings" = "xyes"; then
  AC_MSG_WARN([Using an advanced uniform warning level for ROSE development.])
  AC_DEFINE([ROSE_USE_UNIFORM_ADVANCED_WARNINGS_SUPPORT], [], [Support for an advanced uniform warning level for ROSE development])

# Suggested C++ specific flags (used to be run before Hudson, but fail currently).
  CXX_ADVANCED_WARNINGS+=" -D_GLIBCXX_CONCEPT_CHECKS -D_GLIBCXX_DEBUG"

# Additional flag (suggested by George).
  CXX_ADVANCED_WARNINGS+=" -D_GLIBCXX_DEBUG_PEDANTIC"

# Incrementally add the advanced options
  if test "$CXX_ADVANCED_WARNINGS"; then CXXFLAGS="$CXXFLAGS $CXX_ADVANCED_WARNINGS"; fi
fi
# ROSE_USE_UNIFORM_DEBUG_SUPPORT=7
AC_SUBST(ROSE_USE_UNIFORM_ADVANCED_WARNINGS_SUPPORT)

echo "After processing --enable-advanced-warnings: CXX_ADVANCED_WARNINGS = ${CXX_ADVANCED_WARNINGS}"
echo "After processing --enable-advanced-warnings: CXX_WARNINGS = ${CXX_WARNINGS}"
echo "After processing --enable-advanced-warnings: C_WARNINGS   = ${C_WARNINGS}"

echo "CFLAGS   = $CFLAGS"
echo "CXXFLAGS = $CXXFLAGS"
echo "CPPFLAGS = $CPPFLAGS"

# DQ: added here to see if it would be defined for the template tests and avoid placing 
# a $(CXX_TEMPLATE_REPOSITORY_PATH) directory in the top level build directory (a minor error)
CXX_TEMPLATE_REPOSITORY_PATH='$(top_builddir)/src'

# ROSE_HOME should be relative to top_srcdir or top_builddir.
ROSE_HOME=.
# ROSE_HOME=`pwd`/$top_srcdir
AC_SUBST(ROSE_HOME)
# echo "In ROSE/configure: ROSE_HOME = $ROSE_HOME"

# This does not appear to exist any more (not distributed in ROSE)
# Support for Gabriel's QRose GUI Library
# ROSE_SUPPORT_QROSE
#AM_CONDITIONAL(ROSE_USE_QROSE,test "$with_qrose" = true)

AC_LANG(C++)
AX_BOOST_BASE([1.36.0], [], [echo "Boost 1.36.0 or above is required for ROSE" 1>&2; exit 1])
AC_SUBST(ac_boost_path) dnl Hack using an internal variable from AX_BOOST_BASE -- this path should only be used to set --with-boost in distcheck

# Requested boost version
echo "Requested minimum boost version: boost_lib_version_req_major     = $boost_lib_version_req_major"
echo "Requested minimum boost version: boost_lib_version_req_minor     = $boost_lib_version_req_minor"
echo "Requested minimum boost version: boost_lib_version_req_sub_minor = $boost_lib_version_req_sub_minor"

# Actual boost version (version 1.42 will not set "_version", but version 1.37 will).
echo "Boost version being used is: $_version"

rose_boost_version=`grep "#define BOOST_VERSION " ${ac_boost_path}/include/boost/version.hpp | cut -d" " -f 3 | tr -d '\r'`
echo "rose_boost_version = $rose_boost_version"

# Define macros for conditional compilation of parts of ROSE based on version of boost
# (this ONLY happens for the tests in tests/CompilerOptionsTests/testWave)
#
# !! We don't want conditional compilation or code in ROSE based on version numbers of Boost. !!
#

AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_35,test "x$rose_boost_version" = "x103500" -o "x$_version" = "x1.35")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_36,test "x$rose_boost_version" = "x103600" -o "x$_version" = "x1.36")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_37,test "x$rose_boost_version" = "x103700" -o "x$_version" = "x1.37")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_38,test "x$rose_boost_version" = "x103800" -o "x$_version" = "x1.38")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_39,test "x$rose_boost_version" = "x103900" -o "x$_version" = "x1.39")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_40,test "x$rose_boost_version" = "x104000" -o "x$_version" = "x1.40")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_41,test "x$rose_boost_version" = "x104100" -o "x$_version" = "x1.41")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_42,test "x$rose_boost_version" = "x104200" -o "x$_version" = "x1.42")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_43,test "x$rose_boost_version" = "x104300" -o "x$_version" = "x1.43")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_44,test "x$rose_boost_version" = "x104400" -o "x$_version" = "x1.44")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_45,test "x$rose_boost_version" = "x104500" -o "x$_version" = "x1.45")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_46,test "x$rose_boost_version" = "x104600" -o "x$_version" = "x1.46")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_46,test "x$rose_boost_version" = "x104601" -o "x$_version" = "x1.46")
AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_47,test "x$rose_boost_version" = "x104700" -o "x$_version" = "x1.47")
# Liao 9/19/2012, 1.48 is not yet supported
#AM_CONDITIONAL(ROSE_USING_BOOST_VERSION_1_48,test "x$rose_boost_version" = "x104800" -o "x$_version" = "x1.48")

# DQ (10/18/2010): Error checking for Boost version.
if test "x$rose_boost_version" = "x103600" -o "x$_version" = "x1.36" \
   -o "x$rose_boost_version" = "x103700" -o "x$_version" = "x1.37" \
   -o "x$rose_boost_version" = "x103800" -o "x$_version" = "x1.38" \
   -o "x$rose_boost_version" = "x103900" -o "x$_version" = "x1.39" \
   -o "x$rose_boost_version" = "x104000" -o "x$_version" = "x1.40" \
   -o "x$rose_boost_version" = "x104100" -o "x$_version" = "x1.41" \
   -o "x$rose_boost_version" = "x104200" -o "x$_version" = "x1.42" \
   -o "x$rose_boost_version" = "x104300" -o "x$_version" = "x1.43" \
   -o "x$rose_boost_version" = "x104400" -o "x$_version" = "x1.44" \
   -o "x$rose_boost_version" = "x104500" -o "x$_version" = "x1.45" \
   -o "x$rose_boost_version" = "x104600" -o "x$_version" = "x1.46" \
   -o "x$rose_boost_version" = "x104601" -o "x$_version" = "x1.46" \
   -o "x$rose_boost_version" = "x104700" -o "x$_version" = "x1.47" 
# Not ready   
#   -o "x$rose_boost_version" = "x104800" -o "x$_version" = "x1.48"
then
    echo "Supported version of Boost (1.36 to 1.47) has been found!"
else
    ROSE_MSG_ERROR([Unsupported version of Boost: '$_version' ('$rose_boost_version'). Only 1.36 to 1.47 is supported now.])
fi

# DQ (12/22/2008): Fix boost configure to handle OS with older version of Boost that will
# not work with ROSE, and use the newer version specified by the user on the configure line.
echo "In ROSE/configure: ac_boost_path = $ac_boost_path"
#AC_DEFINE([ROSE_BOOST_PATH],"$ac_boost_path",[Location of Boost specified on configure line.])
AC_DEFINE_UNQUOTED([ROSE_BOOST_PATH],"$ac_boost_path",[Location (unquoted) of Boost specified on configure line.])
#AC_DEFINE([ROSE_WAVE_PATH],"$ac_boost_path/wave",[Location of Wave specified on configure line.])
AC_DEFINE_UNQUOTED([ROSE_WAVE_PATH],"$ac_boost_path/wave",[Location (unquoted) of Wave specified on configure line.])

# DQ (11/5/2009): Added test for GraphViz's ``dot'' program
ROSE_SUPPORT_GRAPHVIZ
AX_BOOST_THREAD
AX_BOOST_DATE_TIME
AX_BOOST_REGEX
AX_BOOST_PROGRAM_OPTIONS
#AX_BOOST_SERIALIZATION
#AX_BOOST_ASIO
#AX_BOOST_SIGNALS
#AX_BOOST_TEST_EXEC_MONITOR
AX_BOOST_SYSTEM
AX_BOOST_FILESYSTEM
AX_BOOST_WAVE

# AM_CONDITIONAL(ROSE_USE_BOOST_WAVE,test "$with_wave" = true)

AX_LIB_SQLITE3
AX_LIB_MYSQL
AM_CONDITIONAL(ROSE_USE_MYSQL,test "$found_mysql" = yes)

# DQ (9/15/2009): I have moved this to before the backend compiler selection so that
# we can make the backend selection a bit more compiler dependent. Actually we likely
# don't need this!
# DQ (9/17/2006): These should be the same for both C and C++ (else we will need separate macros)
# Setup the -D<xxx> defines required to allow EDG to take the same path through the compiler 
# specific and system specific header files as for the backend compiler.  These depend
# upon the selection of the back-end compiler.
# GET_COMPILER_SPECIFIC_DEFINES

# Test this macro here at the start to avoid long processing times (before it fails)
CHOOSE_BACKEND_COMPILER

# For testing the configure script generation this link can be commented out
# to improve performance of tests unrelated to backend compiler headr files.
# DQ (9/17/2006): This must be done for BOTH C++ and C compilers (since the
# compiler-specific header files for each can be different; as is the case 
# for GNU).
# GENERATE_BACKEND COMPILER_SPECIFIC_HEADERS
# GENERATE_BACKEND_CXX_COMPILER_SPECIFIC_HEADERS


# End macro ROSE_SUPPORT_ROSE_PART_1.
]
)



AC_DEFUN([ROSE_SUPPORT_ROSE_BUILD_INCLUDE_FILES],
[
# Begin macro ROSE_SUPPORT_ROSE_BUILD_INCLUDE_FILES.

# JJW (12/10/2008): We don't preprocess the header files for the new interface
rm -rf ./include-staging
if test x$enable_new_edg_interface = xyes; then
  :
# DQ (11/1/2011): I think that we need these for more complex header file 
# requirements than we have seen in testing C code to date.  Previously
# in testing C codes with the EDG 4.x we didn't need as many header files.
  GENERATE_BACKEND_C_COMPILER_SPECIFIC_HEADERS
  GENERATE_BACKEND_CXX_COMPILER_SPECIFIC_HEADERS
else
  if test x$enable_clang_frontend = xyes; then
    INSTALL_CLANG_SPECIFIC_HEADERS
  else
    GENERATE_BACKEND_C_COMPILER_SPECIFIC_HEADERS
    GENERATE_BACKEND_CXX_COMPILER_SPECIFIC_HEADERS
  fi
fi

# End macro ROSE_SUPPORT_ROSE_BUILD_INCLUDE_FILES.
]
)


#-----------------------------------------------------------------------------

AC_DEFUN([ROSE_SUPPORT_ROSE_PART_2],
[
# Begin macro ROSE_SUPPORT_ROSE_PART_2.

# AC_REQUIRE([AC_PROG_CXX])
AC_PROG_CXX

echo "In configure.in ... CXX = $CXX"

# DQ (9/17/2006): These should be the same for both C and C++ (else we will need separate macros)
# Setup the -D<xxx> defines required to allow EDG to take the same path through the compiler 
# specific and system specific header files as for the backend compiler.  These depend
# upon the selection of the back-end compiler.
GET_COMPILER_SPECIFIC_DEFINES

# This must go after the setup of the headers options
# Setup the CXX_INCLUDE_STRING to be used by EDG to find the correct headers
# SETUP_BACKEND_COMPILER_SPECIFIC_REFERENCES
# JJW (12/10/2008): We don't preprocess the header files for the new interface,
# but we still need to use the original C++ header directories
SETUP_BACKEND_C_COMPILER_SPECIFIC_REFERENCES
SETUP_BACKEND_CXX_COMPILER_SPECIFIC_REFERENCES

# DQ (1/15/2007): Check if longer internal make check rule is to be used (default is short tests)
ROSE_SUPPORT_LONG_MAKE_CHECK_RULE

# Make the use of longer test optional where it is used in some ROSE/tests directories
AM_CONDITIONAL(ROSE_USE_LONG_MAKE_CHECK_RULE,test "$with_ROSE_LONG_MAKE_CHECK_RULE" = yes)

# The libxml2 library is availabe in /usr/lib on most Linux systems, however this is not
# enough when using the Intel compilers.  So we need to turn it on explicitly when we
# expect it to work with a specific platform/compiler combination.

# JJW -- use standard version in /usr/share/aclocal, and configure XML only
# once for roseHPCT and BinaryContextLookup
with_xml="no"
AM_PATH_XML2(2.0.0, [with_xml="yes"])

# Make the use of libxml2 explicitly controlled.
AM_CONDITIONAL(ROSE_USE_XML,test "$with_xml" != no)

# DQ (10/17/2009): This is a bug introduced (again) into ROSE which disables the Java support.
# See elsewhere in this file where this macro is commented out and the reason explained in 
# more details.
# AS Check for ssl for the binary clone detection work
# CHECK_SSL

# Check for objdump for BinaryContextLookup since it doesn't normally exist on
# Mac
AC_CHECK_TOOL(ROSE_OBJDUMP_PATH, [objdump], [no])
AM_CONDITIONAL(ROSE_USE_OBJDUMP, [test "$ROSE_OBJDUMP_PATH" != "no"])
AM_CONDITIONAL(ROSE_USE_BINARYCONTEXTLOOKUP, [test "$with_xml" != "no" -a "$ROSE_OBJDUMP_PATH" != "no"])

# Check for availability of wget (used for downloading the EDG binaries used in ROSE).
AC_CHECK_TOOL(ROSE_WGET_PATH, [wget], [no])
AM_CONDITIONAL(ROSE_USE_WGET, [test "$ROSE_WGET_PATH" != "no"])
if test "$ROSE_WGET_PATH" = "no"; then
   echo "***** wget was NOT found *****";
   echo "ROSE now requires wget to download EDG binaries automatically.";
   exit 1;
else
 # Not clear if we really should have ROSE configure automatically do something like this.
   echo "ROSE might use wget to automatically download EDG binaries as required during the build ...";
   echo "***** wget WAS found *****";
fi
# Check for availability of ps2pdf, part of ghostscript (used for generating pdf files).
AC_CHECK_TOOL(ROSE_PS2PDF_PATH, [ps2pdf], [no])
AM_CONDITIONAL(ROSE_USE_PS2PDF, [test "$ROSE_PS2PDF_PATH" != "no"])
if test "$ROSE_PS2PDF_PATH" = "no"; then
   echo "Error: ps2pdf was NOT found "
   echo "ROSE requires ps2pdf (part of ghostscript) to generate pdf files.";
   exit 1;
else
   echo "***** ps2pdf WAS found *****";
fi

AC_C_BIGENDIAN
AC_CHECK_HEADERS([byteswap.h machine/endian.h])

# PKG_CHECK_MODULES([VALGRIND], [valgrind], [with_valgrind=yes; AC_DEFINE([ROSE_USE_VALGRIND], 1, [Use Valgrind calls in ROSE])], [with_valgrind=no])
VALGRIND_BINARY=""
AC_ARG_WITH(valgrind, [  --with-valgrind ... Run uninitialized field tests that use Valgrind],
            [AC_DEFINE([ROSE_USE_VALGRIND], 1, [Use Valgrind calls in ROSE])
             if test "x$withval" = "xyes"; then VALGRIND_BINARY="`which valgrind`"; else VALGRIND_BINARY="$withval"; fi])

AC_ARG_WITH(wave-default, [  --with-wave-default     Use Wave as the default preprocessor],
            [AC_DEFINE([ROSE_WAVE_DEFAULT], true, [Use Wave as default in ROSE])],
            [AC_DEFINE([ROSE_WAVE_DEFAULT], false, [Simple preprocessor as default in ROSE])]
            )

# Don't set VALGRIND here because that turns on actually running valgrind in
# many tests, as opposed to just having the path available for
# uninitializedField_tests
AC_SUBST(VALGRIND_BINARY)
AM_CONDITIONAL(USE_VALGRIND, [test "x$VALGRIND_BINARY" != "x"])

# Add --disable-binary-analysis-tests flag to turn off tests that sometimes
# sometimes break.
AC_ARG_ENABLE(binary-analysis-tests, AS_HELP_STRING([--disable-binary-analysis-tests], [Disable tests of ROSE binary analysis code]), binary_analysis_tests="$withval", binary_analysis_tests=yes)
AM_CONDITIONAL(USE_BINARY_ANALYSIS_TESTS, test "x$binary_analysis_tests" = "xyes")

# Figure out what version of lex we have available
# flex works better than lex (this gives a preference to flex (flex is gnu))
AM_PROG_LEX
AC_SUBST(LEX)
AC_PROG_YACC
AC_SUBST(YACC)

# echo "After test for LEX: CC (CC = $CC)"

# DQ (4/1/2001) Need to call this macro to avoid having "MAKE" set to "make" in the
# top level Makefile (this is important to getting gmake to be used in the "make distcheck"
# makefile rule.  (This does not seem to work, since calling "make distcheck" still fails and
# only "gmake distcheck" seems to work.  I don't know why!
AC_PROG_MAKE_SET

# DQ (9/21/2009): Debugging for RH release 5
echo "Testing the value of CC: (CC = $CC)"
echo "Testing the value of CPPFLAGS: (CPPFLAGS = $CPPFLAGS)"

# Call supporting macro for MAPLE
ROSE_SUPPORT_MAPLE

# Setup Automake conditional in Projects/programModeling/Makefile.am
AM_CONDITIONAL(ROSE_USE_MAPLE,test ! "$with_maple" = no)

# DQ (4/10/2010): Added configure support for Backstroke project.
ROSE_SUPPORT_BACKSTOKE

#Call supporting macro for IDA PRO
ROSE_SUPPORT_IDA

# Setup Automake conditional in projects/AstEquivalence/Makefile.am
AM_CONDITIONAL(ROSE_USE_IDA,test ! "$with_ida" = no)

# DQ (10/15/2010): Adding execution trace file analysis support to ROSE (default is off).
trace_support="no"
# ROSE_SUPPORT_TRACE_ANALYSIS
AM_CONDITIONAL(ROSE_USE_TRACE_ANALYSIS, [test "x$trace_support" = xyes])

# Call supporting macro to Yices Satisfiability Modulo Theories (SMT) Solver
ROSE_SUPPORT_YICES

# Call supporting macro to check for "--enable-i386" switch
ROSE_SUPPORT_I386

# Call supporting macro to internal Satisfiability (SAT) Solver
ROSE_SUPPORT_SAT

# Setup Automake conditional in --- (not yet ready for use)
echo "with_sat = $with_sat"
AM_CONDITIONAL(ROSE_USE_SAT,test ! "$with_sat" = no)

# Call supporting macro to Intel Pin Dynamic Instrumentation
ROSE_SUPPORT_INTEL_PIN

# Setup Automake conditional in --- (not yet distributed)
AM_CONDITIONAL(ROSE_USE_INTEL_PIN,test ! "$with_IntelPin" = no)

# Call supporting macro to DWARF (libdwarf)
ROSE_SUPPORT_DWARF

# Setup Automake conditional in --- (not yet distributed)
AM_CONDITIONAL(ROSE_USE_DWARF,test ! "$with_dwarf" = no)

# Call supporting macro for libffi (Foreign Function Interface library)
# This library is used by Peter's work on the Interpreter in ROSE.
ROSE_SUPPORT_LIBFFI

# Setup Automake conditional in projects/interpreter/Makefile.am
AM_CONDITIONAL(ROSE_USE_LIBFFI,test ! "$with_libffi" = no)

TEST_SMT_SOLVER=""
AC_ARG_WITH(smt-solver,
[  --with-smt-solver=PATH	Specify the path to an SMT-LIB compatible SMT solver.  Used only for testing.],
if test "x$with_smt_solver" = "xcheck" -o "x$with_smt_solver" = "xyes"; then
  AC_ERROR([--with-smt-solver cannot be auto-detected])
fi
if test "x$with_smt_solver" != "xno"; then
  TEST_SMT_SOLVER="$with_smt_solver"
fi,
)

AM_CONDITIONAL(ROSE_USE_TEST_SMT_SOLVER,test ! "$TEST_SMT_SOLVER" = "")
AC_SUBST(TEST_SMT_SOLVER)

# DQ (3/13/2009): Trying to get Intel Pin and ROSE to both use the same version of libdwarf.
# DQ (3/10/2009): The Dwarf support in Intel Pin conflicts with the Dwarf support in ROSE.
# Maybe there is a way to fix this later, for now we want to disallow it.
# echo "with_dwarf    = $with_dwarf"
# echo "with_IntelPin = $with_IntelPin"
#if test "$with_dwarf" != no && test "$with_IntelPin" != no; then
# # echo "Support for both DWARF and Intel Pin fails, these configure options are incompatable."
#   AC_MSG_ERROR([Support for both DWARF and Intel Pin fails, these configure options are incompatable!])
#fi

ROSE_SUPPORT_MINT

ROSE_SUPPORT_VECTORIZATION

ROSE_SUPPORT_PHP

AM_CONDITIONAL(ROSE_USE_PHP,test ! "$with_php" = no)

ROSE_SUPPORT_PYTHON

AM_CONDITIONAL(ROSE_USE_PYTHON,test ! "$with_python" = no)

#ASR
ROSE_SUPPORT_LLVM

AM_CONDITIONAL(ROSE_USE_LLVM,test ! "$with_llvm" = no)

# Call supporting macro for Windows Source Code Analysis
ROSE_SUPPORT_WINDOWS_ANALYSIS

# Setup Automake conditional in Projects/programModeling/Makefile.am
AM_CONDITIONAL(ROSE_USE_WINDOWS_ANALYSIS_SUPPORT,test ! "$with_wine" = no)

# Control use of debugging support to convert most unions in EDG to structs.
ROSE_SUPPORT_EDG_DEBUGGING

# Call supporting macro for Omni OpenMP
# 
ROSE_SUPPORT_OMNI_OPENMP

# call supporting macro for GCC 4.4.x gomp OpenMP runtime library
# AM_CONDITIONAL is already included into the macro
ROSE_WITH_GOMP_OPENMP_LIBRARY

# Call supporting macro for GCC OpenMP
ROSE_SUPPORT_GCC_OMP

# Configuration commandline support for OpenMP in ROSE
AM_CONDITIONAL(ROSE_USE_GCC_OMP,test ! "$with_parallel_ast_traversal_omp" = no)


# JJW and TP (3-17-2008) -- added MPI support
AC_ARG_WITH(parallel_ast_traversal_mpi,
[  --with-parallel_ast_traversal_mpi     Enable AST traversal in parallel using MPI.],
[ echo "Setting up optional MPI-based tools"
])
AM_CONDITIONAL(ROSE_MPI,test "$with_parallel_ast_traversal_mpi" = yes)
AC_CHECK_TOOLS(MPICXX, [mpiCC mpic++ mpicxx])


# TPS (2-11-2009) -- added PCH Support
AC_ARG_WITH(pch,
[  --with-pch                    Configure option to have pre-compiled header support enabled.],
[ echo "Enabling precompiled header"
])
AM_CONDITIONAL(ROSE_PCH,test "$with_pch" = yes)
if test "x$with_pch" = xyes; then
  CPPFLAGS="-U_REENTRANT $CPPFLAGS";
  AC_MSG_NOTICE( "PCH enabled: You got the following CPPFLAGS: $CPPFLAGS" );
if test "x$with_parallel_ast_traversal_mpi" = xyes; then
  AC_MSG_ERROR( "PCH Support cannot be configured together with MPI support" );
fi
if test "x$with_parallel_ast_traversal_omp" = xyes; then
  AC_MSG_ERROR( "PCH Support cannot be configured together with GCC_OMP support" );
fi
else
  AC_MSG_NOTICE( "PCH disabled: No Support for PCH." );
fi





# TP (2-27-2009) -- support for RTED
ROSE_SUPPORT_RTED

AM_CONDITIONAL(ROSE_USE_RTED,test ! "$with_rted" = no)

# TP SUPPORT FOR OPENGL
#AC_DEFINE([openGL],1,[By default OpenGL is disabled.])
AC_ARG_ENABLE([rose-openGL],
  [  --enable-rose-openGL  enable openGL],
  [  rose_openGL=${enableval}
AC_PATH_X dnl We need to do this by hand for some reason
MDL_HAVE_OPENGL
echo "have_GL = '$have_GL' and have_glut = '$have_glut' and rose_openGL = '$rose_openGL'"
#AM_CONDITIONAL(ROSE_USE_OPENGL, test ! "x$have_GL" = xno -a ! "x$openGL" = xno)
if test ! "x$rose_openGL" = xno; then
   AC_MSG_NOTICE( "Checking OpenGL dependencies..." );
  if test "x$have_GL" = xyes; then
    AC_MSG_NOTICE( "OpenGL enabled. Found OpenGL." );
  else
    AC_MSG_ERROR( "OpenGL not found!" );
  fi
 if test "x$have_glut" = xyes; then
    AC_MSG_NOTICE( "OpenGL enabled. Found GLUT." );
 else
#    AC_MSG_NOTICE( "OpenGL GLUT not found Msg" );
   AC_MSG_NOTICE( "OpenGL GLUT not found. Please use --with-glut" );
 fi
fi
], [ rose_openGL=no
  AC_MSG_NOTICE( "OpenGL disabled." );
])
AM_CONDITIONAL(ROSE_USE_OPENGL, test ! "x$have_GL" = xno -a ! "x$rose_openGL" = xno)


AM_CONDITIONAL(USE_ROSE_GLUT_SUPPORT, false)

AC_ARG_WITH(glut,
[  --with-glut=PATH     Configure option to have GLUT enabled.],
,
if test ! "$with_glut" ; then
   with_glut=no
fi
)

echo "In ROSE SUPPORT MACRO: with_glut $with_glut"

if test "$with_glut" = no; then
   # If dwarf is not specified, then don't use it.
   echo "Skipping use of GLUT support!"
else
   AM_CONDITIONAL(USE_ROSE_GLUT_SUPPORT, true)
   glut_path=$with_glut
   echo "Setup GLUT support in ROSE! path = $glut_path"
   AC_DEFINE([USE_ROSE_GLUT_SUPPORT],1,[Controls use of ROSE support for GLUT library.])
fi


AC_SUBST(glut_path)



AC_CHECK_PROGS(PERL, [perl])

# DQ (9/4/2009): Added checking for indent command (common in Linux, but not on some platforms).
# This command is used in the tests/roseTests/astInterfaceTests/Makefile.am file.
AC_CHECK_PROGS(INDENT, [indent])
AM_CONDITIONAL(ROSE_USE_INDENT, [test "x$INDENT" = "xindent"])
echo "value of INDENT variable = $INDENT"

# DQ (9/30/2009): Added checking for tclsh command (common in Linux, but not on some platforms).
# This command is used in the src/frontend/BinaryDisassembly/Makefile.am file.
AC_CHECK_PROGS(TCLSH, [tclsh])
AM_CONDITIONAL(ROSE_USE_TCLSH, [test "x$TCLSH" = "xtclsh"])
echo "value of TCLSH variable = $TCLSH"

# Call supporting macro for OFP
ROSE_SUPPORT_OFP

AC_PROG_SWIG(1.3.31)
SWIG_ENABLE_CXX
#AS (10/23/07): introduced conditional use of javaport
AC_ARG_WITH(javaport,
   [  --with-javaport ... Enable generation of Java bindings for ROSE using Swig],
   [with_javaport=yes],
   [with_javaport=no])
AM_CONDITIONAL(ENABLE_JAVAPORT,test "$with_javaport" = yes)

if test "x$with_javaport" = "xyes"; then
  if test "x$USE_JAVA" = "x0"; then
    AC_MSG_ERROR([Trying to enable --with-javaport without --with-java also being set])
  fi
  if /bin/sh -c "$SWIG -version" >& /dev/null; then
    :
  else
    AC_MSG_ERROR([Trying to enable --with-javaport without SWIG installed])
  fi
  AC_MSG_WARN([Enabling Java binding support -- SWIG produces invalid C++ code, so -fno-strict-aliasing is being added to CXXFLAGS to work around this issue.  If you are not using GCC as a compiler, this flag will need to be changed.])
  CXXFLAGS="$CXXFLAGS -fno-strict-aliasing"
fi

# Call supporting macro for Haskell
ROSE_SUPPORT_HASKELL

# Call supporting macro for SWI Prolog
ROSE_SUPPORT_SWIPL

# Call supporting macro for minitermite
ROSE_CONFIGURE_MINITERMITE

# Call supporting macro for bddbddb
ROSE_SUPPORT_BDDBDDB

# Setup Automake conditional in Projects/DatalogAnalysis/Makefile.am
AM_CONDITIONAL(ROSE_USE_BDDBDDB,test ! "$with_bddbddb" = no)

# Call supporting macro for VISUALIZATION (FLTK and GraphViz)
ROSE_SUPPORT_VISUALIZATION

# if ((test ! "$with_FLTK_include" = no) || (test ! "$with_FLTK_libs" = no) || (test ! "$with_GraphViz_include" = no) || (test ! "$with_GraphViz_libs" = no)); then
#   echo "Skipping visualization support!"
# else
#   echo "Setting up visualization support!"
# fi

# Setup Automake conditional in src/roseIndependentSupport/visualization/Makefile.am
AM_CONDITIONAL(ROSE_USE_VISUALIZATION,(test ! "$with_FLTK_include" = no) || (test ! "$with_FLTK_libs" = no) || (test ! "$with_GraphViz_include" = no) || (test ! "$with_GraphViz_libs" = no))


# *****************************************************************
# Option to control internal support of CUDA (GPU langauge support)
# *****************************************************************

# DQ (4/28/2010): This is part of optional support for CUDA.
AC_MSG_CHECKING([for enabled CUDA support])
AC_ARG_ENABLE(cuda, AS_HELP_STRING([--enable-cuda], [Support for CUDA graphics processor language support (from Nvidia)]))
AM_CONDITIONAL(ROSE_USE_CUDA_SUPPORT, [test "x$enable_cuda" = xyes])
if test "x$enable_cuda" = "xyes"; then
  AC_MSG_WARN([Using incomplete CUDA langauge support in ROSE.])
  AC_DEFINE([ROSE_USE_CUDA_SUPPORT], [], [Whether to use CUDA language support or not within ROSE])
fi
# DQ (10/17/2010): Why is this set to the value "7".
ROSE_USE_CUDA_SUPPORT=7
AC_SUBST(ROSE_USE_CUDA_SUPPORT)

# *****************************************************
# Option to control building of CUDA support in EDG 4.0
# *****************************************************

# TV (03/22/2011): This is part of optional building of CUDA support in EDG 4.0
AC_MSG_CHECKING([for building of CUDA support in EDG 4.0])
AC_ARG_ENABLE(edg_cuda, AS_HELP_STRING([--enable-edg-cuda], [Build EDG 4.0 with CUDA support.]), [case "${enableval}" in
  yes) edg_cuda=true ;;
  no)  edg_cuda=false ;;
  *)   edg_cuda=false ;;
esac])
AM_CONDITIONAL(ROSE_BUILD_EDG_WITH_CUDA_SUPPORT, [test x$edg_cuda = xtrue])
if test x$edg_cuda = xtrue; then
  AC_MSG_WARN([Add CUDA specific headers to the include-staging directory.])
  GENERATE_CUDA_SPECIFIC_HEADERS
fi

# *******************************************************************
# Option to control internal support of OpenCL (GPU langauge support)
# *******************************************************************

# DQ (4/28/2010): This is part of optional support for OpenCL.
AC_MSG_CHECKING([for enabled OpenCL support])
AC_ARG_ENABLE(opencl, AS_HELP_STRING([--enable-opencl], [Support for opencl graphics processor language support]))
AM_CONDITIONAL(ROSE_USE_OPENCL_SUPPORT, [test "x$enable_opencl" = xyes])
if test "x$enable_opencl" = "xyes"; then
  AC_MSG_WARN([Using incomplete OpenCL langauge support in ROSE.])
  AC_DEFINE([ROSE_USE_OPENCL_SUPPORT], [], [Whether to use OpenCL language support or not within ROSE])
fi
AC_SUBST(ROSE_USE_OPENCL_SUPPORT)

# *******************************************************
# Option to control building of OpenCL support in EDG 4.0
# *******************************************************

# TV (05/06/2011): This is part of optional building of OpenCL support in EDG 4.0
AC_MSG_CHECKING([for building of OpenCL support in EDG 4.0])
AC_ARG_ENABLE(edg_opencl, AS_HELP_STRING([--enable-edg-opencl], [Build EDG 4.0 with OpenCL support.]), [case "${enableval}" in
  yes) edg_opencl=true ;;
  no)  edg_opencl=false ;;
  *)   edg_opencl=false ;;
esac])
AM_CONDITIONAL(ROSE_BUILD_EDG_WITH_OPENCL_SUPPORT, [test x$edg_opencl = xtrue])
if test x$edg_opencl = xtrue; then
  AC_MSG_WARN([Add OpenCL specific headers to the include-staging directory.])
  GENERATE_OPENCL_SPECIFIC_HEADERS
fi

# support for Unified Parallel Runtime, check for CUDA and OpenCL
ROSE_SUPPORT_UPR

# *********************************************************************
# Option to control internal support of PPL (Parma Polyhedron Library)
# *********************************************************************

# TV (05/25/2010): Check for Parma Polyhedral Library (PPL)

AC_ARG_WITH(
	[ppl],
	AS_HELP_STRING([--with-ppl@<:@=DIR@:>@], [use Parma Polyhedral Library (PPL)]),
	[
	if test "$withval" = "no"; then
		echo "Error: --with-ppl=PATH must be specified to use option --with-ppl (a valid Parma Polyhedral Library (PPL) intallation)"
		exit 1
	elif test "$withval" = "yes"; then
		echo "Error: --with-ppl=PATH must be specified to use option --with-ppl (a valid Parma Polyhedral Library (PPL) intallation)"
		exit 1
	else
		has_ppl_path="yes"
		ppl_path="$withval"
	fi
	],
	[has_ppl_path="no"]
)

AC_ARG_ENABLE(
	ppl,
	AS_HELP_STRING(
		[--enable-ppl],
		[Support for Parma Polyhedral Library (PPL)]
	)
)
AM_CONDITIONAL(
	ROSE_USE_PPL,
	[test "x$enable_ppl" = "xyes"])
if test "x$enable_ppl" = "xyes"; then
	if test "x$has_ppl_path" = "xyes"; then
		PPL_PATH="$ppl_path"
		AC_DEFINE([ROSE_USE_PPL], [], [Whether to use Parma Polyhedral Library (PPL) support or not within ROSE])
	fi
fi
AC_SUBST(ROSE_USE_PPL)
AC_SUBST(PPL_PATH)

# *********************************************************************************
# Option to control internal support of Cloog (Code generator for Polyhedral Model)
# *********************************************************************************

AC_ARG_WITH(
	[cloog],
	AS_HELP_STRING([--with-cloog@<:@=DIR@:>@], [use Cloog]),
	[
	if test "$withval" = "no"; then
		echo "Error: --with-cloog=PATH must be specified to use option --with-cloog (a valid Cloog intallation)"
		exit 1
	elif test "$withval" = "yes"; then
		echo "Error: --with-cloog=PATH must be specified to use option --with-cloog (a valid Cloog intallation)"
		exit 1
	else
		has_cloog_path="yes"
		cloog_path="$withval"
	fi
	],
	[has_cloog_path="no"]
)

AC_ARG_ENABLE(
	cloog,
	AS_HELP_STRING(
		[--enable-cloog],
		[Support for Cloog]
	)
)
AM_CONDITIONAL(
	ROSE_USE_CLOOG,
	[test "x$enable_cloog" = "xyes"])
if test "x$enable_cloog" = "xyes"; then
	if test "x$has_cloog_path" = "xyes"; then
		CLOOG_PATH="$cloog_path"
		AC_DEFINE([ROSE_USE_CLOOG], [], [Whether to use Cloog support or not within ROSE])
	fi
fi
AC_SUBST(ROSE_USE_CLOOG)
AC_SUBST(CLOOG_PATH)

# **************************************************************************************
# Option to control internal support of ScopLib (A classic library for Polyhedral Model)
# **************************************************************************************

AC_ARG_WITH(
	[scoplib],
	AS_HELP_STRING([--with-scoplib@<:@=DIR@:>@], [use ScopLib]),
	[
	if test "$withval" = "no"; then
		echo "Error: --with-scoplib=PATH must be specified to use option --with-scoplib (a valid ScopLib intallation)"
		exit 1
	elif test "$withval" = "yes"; then
		echo "Error: --with-scoplib=PATH must be specified to use option --with-scoplib (a valid ScopLib intallation)"
		exit 1
	else
		has_scoplib_path="yes"
		scoplib_path="$withval"
	fi
	],
	[has_scoplib_path="no"]
)

AC_ARG_ENABLE(
	scoplib,
	AS_HELP_STRING(
		[--enable-scoplib],
		[Support for ScopLib]
	)
)
AM_CONDITIONAL(
	ROSE_USE_SCOPLIB,
	[test "x$enable_scoplib" = "xyes"])
if test "x$enable_scoplib" = "xyes"; then
	if test "x$has_scoplib_path" = "xyes"; then
		SCOPLIB_PATH="$scoplib_path"
		AC_DEFINE([ROSE_USE_SCOPLIB], [], [Whether to use ScopLib support or not within ROSE])
	fi
fi
AC_SUBST(ROSE_USE_SCOPLIB)
AC_SUBST(SCOPLIB_PATH)

# *************************************************************************************
# Option to control internal support of Candl (Dependency analysis in Polyhedral Model)
# *************************************************************************************

AC_ARG_WITH(
	[candl],
	AS_HELP_STRING([--with-candl@<:@=DIR@:>@], [use Candl]),
	[
	if test "$withval" = "no"; then
		echo "Error: --with-candl=PATH must be specified to use option --with-candl (a valid Candl intallation)"
		exit 1
	elif test "$withval" = "yes"; then
		echo "Error: --with-candl=PATH must be specified to use option --with-candl (a valid Candl intallation)"
		exit 1
	else
		has_candl_path="yes"
		candl_path="$withval"
	fi
	],
	[has_candl_path="no"]
)

AC_ARG_ENABLE(
	candl,
	AS_HELP_STRING(
		[--enable-candl],
		[Support for Candl]
	)
)
AM_CONDITIONAL(
	ROSE_USE_CANDL,
	[test "x$enable_candl" = "xyes"])
if test "x$enable_candl" = "xyes"; then
	if test "x$has_candl_path" = "xyes"; then
		CANDL_PATH="$candl_path"
		AC_DEFINE([ROSE_USE_CANDL], [], [Whether to use Candl support or not within ROSE])
	fi
fi
AC_SUBST(ROSE_USE_CANDL)
AC_SUBST(CANDL_PATH)

# *****************************************************************
#            Option to define DOXYGEN SUPPORT
# *****************************************************************

# allow either user or developer level documentation using Doxygen
ROSE_SUPPORT_DOXYGEN

# DQ (8/25/2004): Disabled fast docs option.
# Setup Automake conditional to allow use of Doxygen Tag file to speedup
# generation of Rose documentation this does not however provide the
# best organized documentation so we use it as an option to speed up
# the development of the documenation and then alternatively build the 
# final documentation.
# AM_CONDITIONAL(DOXYGEN_GENERATE_FAST_DOCS,test "$enable_doxygen_generate_fast_docs" = yes)
# echo "In configure.in: enable_doxygen_generate_fast_docs = $enable_doxygen_generate_fast_docs"

# Test for setup of document merge of Sage docs with Rose docs
# Causes document build process to take longer but builds better documentation
if (test "$enable_doxygen_generate_fast_docs" = yes) ; then
   AC_MSG_NOTICE([Generate Doxygen documentation faster (using tag file mechanism) ...])
else
   AC_MSG_NOTICE([Generate Doxygen documentation slower (reading all of Sage III and Rose together) ...])
fi

AC_PROG_CXXCPP
dnl AC_PROG_RANLIB
# echo "In configure.in (before libtool win32 setup): libtool test for 64 bit libs = `/usr/bin/file conftest.o`"
dnl AC_LIBTOOL_WIN32_DLL -- ROSE is probably not set up for this

# echo "In configure.in (before libtool setup): disabling static libraries by default (use --enable-static or --enable-static= to override)"
AC_DISABLE_STATIC

# echo "In configure.in (before libtool setup): libtool test for 64 bit libs = `/usr/bin/file conftest.o`"
LT_AC_PROG_SED dnl This seems to not be called, even though it is needed in the other macros
m4_pattern_allow([LT_LIBEXT])dnl From http://www.mail-archive.com/libtool-commit@gnu.org/msg01369.html

# Liao 8/17/2010. Tried to work around a undefined SED on NERSC hopper.
# But this line is expanded after AC_PROG_LIBTOOL.
# I had to promote it to configure.in, right before calling  ROSE_SUPPORT_ROSE_PART_2
#test -z "$SED" && SED=sed

AC_PROG_LIBTOOL
AC_LIBLTDL_CONVENIENCE dnl We need to use our version because libtool can't handle when we use libtool v2 but the v1 libltdl is installed on a system
AC_SUBST(LTDLINCL)
AC_SUBST(LIBLTDL)
AC_LIBTOOL_DLOPEN
AC_LIB_LTDL(recursive)
dnl AC_LT DL_SHLIBPATH dnl Get the environment variable like LD_LIBRARY_PATH for the Fortran support to use
dnl This seems to be an internal variable, set by different macros in different
dnl Libtool versions, but with the same name
AC_DEFINE_UNQUOTED(ROSE_SHLIBPATH_VAR, ["$shlibpath_var"], [Variable like LD_LIBRARY_PATH])

echo 'int i;' > conftest.$ac_ext
AC_TRY_EVAL(ac_compile);
# echo "In configure.in (after libtool setup): libtool test for 64 bit libs = `/usr/bin/file conftest.o`"

# Various functions for finding the location of librose.* (used to make the
# ROSE executables relocatable to different locations without recompilation on
# some platforms)
AC_CHECK_HEADERS([dlfcn.h], [have_dladdr=yes], [have_dladdr=no])
if test "x$have_dladdr" = "xyes"; then
  AC_CHECK_LIB([dl], [dladdr], [], [have_dladdr=no])
fi
if test "x$have_dladdr" = "xyes"; then
  AC_DEFINE([HAVE_DLADDR], [], [Whether <dlfcn.h> and -ldl contain dladdr()])
  use_rose_in_build_tree_var=no
else
  AC_MSG_WARN([ROSE cannot find the locations of loaded shared libraries using your dynamic linker.  ROSE can only be used with the given build directory or prefix, and the ROSE_IN_BUILD_TREE environment variable must be used to distinguish the two cases.])
  use_rose_in_build_tree_var=yes
fi
AM_CONDITIONAL(USE_ROSE_IN_BUILD_TREE_VAR, [test "x$use_rose_in_build_tree_var" = "xyes"])

# Figure out what version of lex we have available
# flex works better than lex (this gives a preference to flex (flex is gnu))
dnl AM_PROG_LEX
dnl AC_SUBST(LEX)
# This will work with flex and lex (but flex will not set LEXLIB to -ll unless it finds the gnu
# flex library which is not often installed (and at any rate not installed on our system at CASC)).
# Once the lex file contains its own version of yywrap then we will not need this set explicitly.

# next two lines commented out by BP : 10/29/2001,
# the flex library IS installed on our systems, setting it to -ll causes problems on
# Linux systems
# echo "Setting LEXLIB explicitly to -ll (even if flex is used: remove this once lex file contains it's own version of yywrap)"
# dnl LEXLIB='-ll'
# dnl AC_SUBST(LEXLIB)

# Determine what C++ compiler is being used.
AC_MSG_CHECKING(what the C++ compiler $CXX really is)
BTNG_INFO_CXX_ID
AC_MSG_RESULT($CXX_ID-$CXX_VERSION)

# Define various C++ compiler options.
# echo "Before ROSE_FLAG _ CXX_OPTIONS macro"
# ROSE_FLAG_C_OPTIONS
# ROSE_FLAG_CXX_OPTIONS
# echo "Outside of ROSE_FLAG _ CXX_OPTIONS macro: CXX_DEBUG= $CXX_DEBUG"

# Enable turning on purify and setting its options, etc.
ROSE_SUPPORT_PURIFY
# echo "In ROSE/configure: AUX_LINKER = $AUX_LINKER" 

# Enable turning on Insure and setting its options, etc.
ROSE_SUPPORT_INSURE
# echo "In ROSE/configure: AUX_LINKER = $AUX_LINKER" 

# DQ (7/8/2004): Added support for shared libraries using Brian's macros
# ROSE_TEST_LIBS="-L`pwd`/src"

# DQ (9/7/2006): build the directory where libs will be placed.
# mkdir -p $prefix/libs
# echo "Before calling \"mkdir -p $prefix/lib\": prefix = $prefix"
# mkdir -p $prefix/lib

# DQ (1/14/2007): I don't think this is required any more!
# ROSE_TEST_LIBS="-L$prefix/lib"

# DQ (1/14/2007): I don't know if this is required, but too many people are resetting this variable!
# LIBS_WITH_RPATH="$(WAVE_LIBRARIES)"

dnl PC (09/15/2006): None of the following should not be relevant any more
dnl
dnl echo "Calling LIBS_ADD_RPATH ROSE_TEST_LIBS = $ROSE_TEST_LIBS"
dnl # Macro copied from Brian Gummey's implementation and turned on by default.
dnl ROSE_LIBS_ADD_RPATH(ROSE_TEST_LIBS,LIBS_WITH_RPATH,0)
dnl 
dnl # This is part of support for Boost-Wave (CPP Preprocessor Library)
dnl # Only add the Boost-Wave library to rpath if it has been set
dnl if (test "$with_boost_wave" = yes); then
dnl    MY_WAVE_PATH="-L$wave_libraries"
dnl    ROSE_LIBS_ADD_RPATH(MY_WAVE_PATH,LIBS_WITH_RPATH,0)
dnl fi
dnl 
dnl echo "DONE: MY_WAVE_PATH                   = $MY_WAVE_PATH"
dnl echo "DONE: LIBS_ADD_RPATH ROSE_TEST_LIBS  = $ROSE_TEST_LIBS"
dnl echo "DONE: LIBS_ADD_RPATH LIBS_WITH_RPATH = $LIBS_WITH_RPATH"
dnl 
dnl # exit 1
dnl 
dnl # This is part of support for QRose (specification of QT Graphics Library)
dnl # Only add the QT library to rpath if it has been set
dnl if (test "$ac_qt_libraries"); then
dnl    MY_QT_PATH="-L$ac_qt_libraries"
dnl    ROSE_LIBS_ADD_RPATH(MY_QT_PATH,LIBS_WITH_RPATH,0)
dnl fi
dnl 
dnl echo "DONE: MY_QT_PATH                     = $MY_QT_PATH"
dnl echo "DONE: LIBS_ADD_RPATH ROSE_TEST_LIBS  = $ROSE_TEST_LIBS"
dnl echo "DONE: LIBS_ADD_RPATH LIBS_WITH_RPATH = $LIBS_WITH_RPATH"

AC_SUBST(LIBS_WITH_RPATH)

# Determine how to create C++ libraries.
AC_MSG_CHECKING(how to create C++ libraries)
BTNG_CXX_AR
AC_MSG_RESULT($CXX_STATIC_LIB_UPDATE and $CXX_DYNAMIC_LIB_UPDATE)

# DQ (6/23/2004) Commented out due to warning in running build
# I do not know why in this case, INCLUDES is not generically
# defined and automatically substituted.  It usually is.  BTNG.
# INCLUDES='-I. -I$(srcdir) -I$(top_builddir)'
# AC_SUBST(INCLUDES)

# We don't need to select between SAGE 2 and SAGE 3 anymore (must use SAGE 3)
# SAGE_VAR_INCLUDES_AND_LIBS

# Let user specify where to find A++P++ installation.
# Specify by --with-AxxPxx= or setting AxxPxx_PREFIX.
# Note that the prefix specified should be that specified
# when installing A++P++.  The prefix appendages are also
# added here.
# BTNG.
AC_MSG_CHECKING(for A++P++)
AC_ARG_WITH(AxxPxx,
[  --with-AxxPxx=PATH	Specify the prefix where A++P++ is installed],
,
if test "$AxxPxx_PREFIX" ; then 
   with_AxxPxx="$AxxPxx_PREFIX"
else
   with_AxxPxx=no
fi
)
test "$with_AxxPxx" && test "$with_AxxPxx" != no && AxxPxx_PREFIX="$with_AxxPxx"
AC_MSG_RESULT($AxxPxx_PREFIX)
if test "$AxxPxx_PREFIX" ; then
  # Note that the prefix appendages are added to AxxPxx_PREFIX to find A++ and P++.
  AC_MSG_RESULT(using $AxxPxx_PREFIX as path to A++ Library)
  Axx_INCLUDES="-I$AxxPxx_PREFIX/A++/lib/include"
  Axx_LIBS="-L$AxxPxx_PREFIX/A++/lib/lib -lApp -lApp_static -lApp"
  Pxx_INCLUDES="-I$AxxPxx_PREFIX/P++/lib/include"
  Pxx_LIBS="-L$AxxPxx_PREFIX/P++/lib/lib -lApp -lApp_static -lApp"
  # optional_AxxPxxSpecificExample_subdirs="EXAMPLES"
  # we will want to setup subdirectories in the TESTS directory later so set it up now
  # optional_AxxPxxSpecificTest_subdirs="A++Tests"
else
  AC_MSG_RESULT(No path specified for A++ Library)
fi
AC_SUBST(Axx_INCLUDES)
AC_SUBST(Axx_LIBS)
AC_SUBST(Pxx_INCLUDES)
AC_SUBST(Pxx_LIBS)
# AC_SUBST(optional_AxxPxxSpecificExample_subdirs)
# AC_SUBST(optional_AxxPxxSpecificTest_subdirs)
# Do not append to INCLUDES and LIBS because Axx is not needed everywhere.
# It is only needed in EXAMPLES.
# Set up A++/P++ directories that require A++/P++ Libraries (EXAMPLES)
AM_CONDITIONAL(AXXPXX_SPECIFIC_TESTS,test ! "$with_AxxPxx" = no)

# BTNG_CHOOSE_STL defines STL_DIR and STL_INCLUDES
# BTNG_CHOOSE_STL
# echo "STL_INCLUDE = $STL_INCLUDE"
# AC _SUB ST(STL_INCLUDES)
# AC _SUB ST(STL_DIR)

# We no longer want to have the ROSE configure.in setup the PerformanceTests/Makefile
# PerformanceTests/Makefile
AC_ARG_WITH(PERFORMANCE_TESTS,
   [  --with-PERFORMANCE_TESTS ... compile and run performance tests within both A++ and P++],, with_PERFORMANCE_TESTS=no )
# BTNG_AC_LOG(with_PERFORMANCE_TESTS is $with_PERFORMANCE_TESTS)
# with_PERFORMANCE_TESTS variable is exported so that other packages
# (e.g. indirect addressing) can set 
# themselves up dependent upon the use/non-use of PADRE
export with_PERFORMANCE_TESTS;

# Inclusion of PerformanceTests and/or its sublibraries.
# if test "$with_PERFORMANCE_TESTS" = no; then
#   # If PerformanceTests is not specified, then don't use it.
#     echo "Skipping PerformanceTests!"
# else
#   # If PERFORMANCE_TESTS is specified, then configure in PERFORMANCE_TESTS
#   # without regard to its sublibraries.
#   # subdir_list="BenchmarkBase $subdir_list"
#   # optional_PERFORMANCE_subdirs="TESTS/PerformanceTests/BenchmarkBase"
#   # optional_PERFORMANCE_subdirs="TESTS/PerformanceTests"
#   optional_PERFORMANCE_subdirs="PerformanceTests"
#   # echo "Setup PerformanceTests! optional_PERFORMANCE_subdirs = $optional_PERFORMANCE_subdirs"
#   AC_CONFIG_SUBDIRS(TESTS/PerformanceTests/BenchmarkBase)
# fi

dnl # PC (8/16/2006): Now we test for GCJ since MOPS uses it
dnl AC_ARG_WITH([gcj],
dnl [  --with-gcj .................. Specify use of Java (gcj must be in path, required for use with ROSE/projects/FiniteStateModelChecker which uses MOPS internally)], [
dnl    AM_PROG_GCJ
dnl    echo "GCJ = '$GCJ'"
dnl    if test "x$GCJ" == "x" ; then
dnl      echo "gcj not found in path; please add gcj to path or omit --with-gcj option"
dnl      exit 1
dnl    fi
dnl    with_gcj=yes
dnl ],[
dnl    _AM_IF_OPTION([no-dependencies],, [_AM_DEPENDENCIES(GCJ)])
dnl ]) 
with_gcj=no ; # JJW 5-22-2008 The code that was here before broke if gcj was not present, even if the --with-gcj flag was absent
AM_CONDITIONAL(USE_GCJ,test "$with_gcj" = yes)

ROSE_CONFIGURE_SECTION([Running system checks])

AC_SEARCH_LIBS(clock_gettime, [rt], [
  RT_LIBS="$LIBS"
  LIBS=""
],[
  RT_LIBS=""
])
AC_SUBST(RT_LIBS)

# DQ (9/11/2006): Removed performance tests conditional, the performance tests were
# removed previously, but we still have the tests/PerformanceTests directory.
# AM_CONDITIONAL(ROSE_PERFORMANCE_TESTS,test ! "$with_PERFORMANCE_TESTS" = no)

# DQ (9/11/2006): skipping use of optional_PERFORMANCE_subdirs
# There is no configure.in in TESTS/PerformanceTests (only in TESTS/PerformanceTests/BenchmarkBase)
# AC_CONFIG_SUBDIRS(TESTS/PerformanceTests)
# AC_CONFIG_SUBDIRS(TESTS/PerformanceTests/BenchmarkBase)
# AC_SUBST(optional_PERFORMANCE_subdirs)

# DQ (12/16/2009): This option is now removed since the developersScratchSpace has been 
# removed from the ROSE's git repository and it is a separate git repository that can be 
# checked out internally by ROSE developers.
# Set up for Dan Quinlan's development test directory.
# AC_ARG_ENABLE(dq-developer-tests,
# [--enable-dq-developer-tests   Development option for Dan Quinlan (disregard).],
# [ echo "Setting up optional ROSE/developersScratchSpace/Dan directory"
# if test -d ${srcdir}/developersScratchSpace; then
#   :
# else
#   echo "This is a non-developer version of ROSE (source distributed with EDG binary)"
#   enable_dq_developer_tests=no
# fi
# ])
# AM_CONDITIONAL(DQ_DEVELOPER_TESTS,test "$enable_dq_developer_tests" = yes)

## This should be set after a complex test (turn it on as default)
AC_DEFINE([HAVE_EXPLICIT_TEMPLATE_INSTANTIATION],[],[Use explicit template instantiation.])

# Copied from the P++/configure.in
# Determine how to build a C++ library.
AC_MSG_CHECKING(how to build C++ libraries)
BTNG_CXX_AR
if test "$CXX_ID" = ibm; then
  # IBM does not have a method for supporting shared libraries
  # Here is a kludge.
  CXX_SHARED_LIB_UPDATE="`cd ${srcdir}/../config && pwd`/mklib.aix -o"
  BTNG_AC_LOG(CXX_SHARED_LIB_UPDATE changed to $CXX_SHARED_LIB_UPDATE especially for the IBM)
fi
AC_MSG_RESULT($CXX_STATIC_LIB_UPDATE and $CXX_SHARED_LIB_UPDATE)
AC_SUBST(CXX_STATIC_LIB_UPDATE)
AC_SUBST(CXX_SHARED_LIB_UPDATE)

# The STL tests use the CC command line which specifies -ptr$(CXX_TEMPLATE_REPOSITORY_PATH) but this
# is not defined in the shell so no substitution is done and a directory named
# $(CXX_TEMPLATE_REPOSITORY_PATH) is built in the top level directory.  The least we can do is
# delete it if we can't stop it from being generated.
# AC_MSG_RESULT(deleting temporary template directory built during STL tests.)
# rm -rf '$(CXX_TEMPLATE_REPOSITORY_PATH)'
rm -rf Templates.DB

# End macro ROSE_SUPPORT_ROSE_PART_2.
]
)

#-----------------------------------------------------------------------------


AC_DEFUN([ROSE_SUPPORT_ROSE_PART_3],
[
# Begin macro ROSE_SUPPORT_ROSE_PART_3.

## Setup the EDG specific stuff
SETUP_EDG

# AM_CONDITIONAL(ROSE_USE_EDG_3_3,test "$with_EDG_3_3" = yes)

# Find md5 or md5sum and create a signature for ROSE binary compatibility
AC_CHECK_PROGS(MD5, [md5 md5sum], [false])
AC_SUBST(MD5)
if test -e ${srcdir}/src/frontend/CxxFrontend/EDG/Makefile.am; then
  has_edg_source=yes
  if test "x$MD5" = "xfalse"; then
    AC_MSG_WARN([Could not find either md5 or md5sum -- building binary EDG tarballs is disabled])
    binary_edg_tarball_enabled=no
  else
    binary_edg_tarball_enabled=yes
  fi
else
  has_edg_source=no
  binary_edg_tarball_enabled=no # This is a binary release version of ROSE anyway
fi

AM_CONDITIONAL(ROSE_HAS_EDG_SOURCE, [test "x$has_edg_source" = "xyes"])
AM_CONDITIONAL(BINARY_EDG_TARBALL_ENABLED, [test "x$binary_edg_tarball_enabled" = "xyes"])

ROSE_ARG_ENABLE(
  [alternate-edg-build-cpu],
  [for alternate EDG build cpu],
  [allows you to generate EDG binaries with a different CPU type in the name string]
)

#The build_triplet_without_redhat variable is used only in src/frontend/CxxFrontend/Makefile.am to determine the binary edg name
build_triplet_without_redhat=`${srcdir}/config/cleanConfigGuessOutput "$build" "$build_cpu" "$build_vendor"`
if test "x$CONFIG_HAS_ROSE_ENABLE_ALTERNATE_EDG_BUILD_CPU" = "xyes"; then
  # Manually modify the build CPU <build_cpu>-<build_vendor>-<build>
  build_triplet_without_redhat="$(echo "$build_triplet_without_redhat" | sed 's/^[[^-]]*\(.*\)/'$ROSE_ENABLE_ALTERNATE_EDG_BUILD_CPU'\1/')"
fi
AC_SUBST(build_triplet_without_redhat) dnl This is done even with EDG source, since it is used to determine the binary to make in roseFreshTest

# End macro ROSE_SUPPORT_ROSE_PART_3.
])

#-----------------------------------------------------------------------------

AC_DEFUN([ROSE_SUPPORT_ROSE_PART_4],
[
# Begin macro ROSE_SUPPORT_ROSE_PART_4.

dnl ---------------------------------------------------------------------
dnl (8/29/2007): This was added to provide more portable times upon the 
dnl suggestion of Matt Sottile at LANL.
dnl ---------------------------------------------------------------------
AC_C_INLINE
AC_HEADER_TIME
AC_CHECK_HEADERS([sys/time.h c_asm.h intrinsics.h mach/mach_time.h])

AC_CHECK_TYPE([hrtime_t],[AC_DEFINE(HAVE_HRTIME_T, 1, [Define to 1 if hrtime_t is defined in <sys/time.h>])],,[#if HAVE_SYS_TIME_H 
#include <sys/time.h> 
#endif])

AC_CHECK_FUNCS([gethrtime read_real_time time_base_to_time clock_gettime mach_absolute_time])

dnl Cray UNICOS _rtc() (real-time clock) intrinsic
AC_MSG_CHECKING([for _rtc intrinsic])
rtc_ok=yes
AC_TRY_LINK([#ifdef HAVE_INTRINSICS_H
#include <intrinsics.h>
#endif], [_rtc()], [AC_DEFINE(HAVE__RTC,1,[Define if you have the UNICOS _rtc() intrinsic.])], [rtc_ok=no])
AC_MSG_RESULT($rtc_ok)
dnl ---------------------------------------------------------------------


# Record the location of the build tree (so it can be substituted into ROSE/docs/Rose/rose.cfg)
top_pwd=$PWD
AC_SUBST(top_pwd)
# echo "In ROSE/con figure: top_pwd = $top_pwd"

absolute_path_srcdir="`cd $srcdir; pwd`"
AC_SUBST(absolute_path_srcdir)

# Liao 6/20/2011, store source path without symbolic links, used to have consistent source and compile paths for ROSE 
# when call graph analysis tests are used.
res_top_src=$(cd "$srcdir" && pwd -P)
AC_DEFINE_UNQUOTED([ROSE_SOURCE_TREE_PATH],"$res_top_src",[Location of ROSE Source Tree.])

# This is silly, but it is done to hide an include command (in
# projects/compass/Makefile.am, including compass-makefile.inc in the build
# tree) from Automake because the needed include file does not exist when
# automake is run
INCLUDE_COMPASS_MAKEFILE_INC="include compass_makefile.inc"
AC_SUBST(INCLUDE_COMPASS_MAKEFILE_INC)

# ROSE-HPCT module -- note that this needs the XML check to have already
# happened
ACROSE_ENABLE_ROSEHPCT

# PC (08/20/2009): Symbolic links need to be resolved for the callgraph analysis tests
res_top_pwd=$(cd "$top_pwd" && pwd -P)

# DQ (11/10/2007): Add paths defined by automake to the generated rose.h.in and rose.h
# header files so that this information will be available at compile time. Unclear
# which syntax is best for the specification of these paths.
AC_DEFINE_UNQUOTED([ROSE_COMPILE_TREE_PATH],"$res_top_pwd",[Location of ROSE Compile Tree.])

# This block turns off features of libharu that don't work with Java
with_png=no
export with_png
with_zlib=no
export with_zlib

# DQ (4/11/2010): This seems to have to appear before the Qt macros
# because the "AC PATH QT" are defined in config/qrose_indigo_1.m4.
# *****************************************************
#  Support for QRose Qt GUI (work at Imperial College)
# *****************************************************

# GMY (9/3/2008) QT4 & QROSE Optional Packages
AC_ARG_WITH(QRose, [  --with-QRose=PATH     prefix of QRose installation],
   [QROSE_PREFIX=$with_QRose
    if test "x$with_QRose" = xyes; then
       echo "Error: --with-QRose=PATH must be specified to use option --with-QRose (a valid QRose intallation)"
       exit 1
    fi
    if test "x$with_QRose" = x; then
       echo "Error: empty path used in --with-QRose=PATH must be specified to use option --with-QRose (a valid Qt intallation)"
       exit 1
    fi
   ],
	[with_QRose=no])

AC_SUBST(QROSE_PREFIX)
AM_CONDITIONAL(ROSE_USE_QROSE,test "x$with_QRose" != xno)

echo "with_QRose = $with_QRose"

#AM_CONDITIONAL(USE_QROSE, test "$with_QRose" != no)
#QROSE_LDFLAGS="-L${QROSE_PREFIX}/lib -lqrose"
#QROSE_CXXFLAGS="-I${QROSE_PREFIX}/include"
#AC_SUBST(QROSE_LDFLAGS)
#AC_SUBST(QROSE_CXXFLAGS)


# DQ (4/11/2010): Organized the Qt configure support.
# ****************************************************
#         Support for Qt (General GUI support)
# ****************************************************

# These are defined in config/qrose_indigo_1.m4, they 
# are not standard AC macros.
AC_PATH_QT
AC_PATH_QT_MOC
AC_PATH_QT_RCC
AC_PATH_QT_UIC

# The code to set ROSEQT is in this macro's definition.
AC_PATH_QT_VERSION

echo "with_qt     = $with_qt"
AM_CONDITIONAL(ROSE_USE_QT,test x"$with_qt" != x"no")
if test "x$with_qt" = xyes; then
   echo "Error: Path to Qt not specified...(usage: --with-qt=PATH)"
   exit 1
fi

# If QRose was specified then make sure that Qt was specified.
if test "x$with_QRose" != xno; then
   if test "x$with_qt" = xno; then
      echo "Error: QRose requires valid specification of Qt installation...(requires option: --with-qt=PATH)"
      exit 1
   fi
fi

# *****************************************************
#   Support for RoseQt GUI (ROSE specific Qt widgets)
# *****************************************************

# ROSE_SUPPORT_ROSEQT
# echo "with_roseQt = $with_roseQt"
# AM_CONDITIONAL(ROSE_WITH_ROSEQT,test x"$with_roseQt" != x"no")

# ****************************************************
#   Support for Assembly Semantics (binary analysis)
# ****************************************************

AC_ARG_ENABLE(assembly-semantics, AS_HELP_STRING([--enable-assembly-semantics], [Enable semantics-based analysis of assembly code]))
AM_CONDITIONAL(ROSE_USE_ASSEMBLY_SEMANTICS, [test "x$enable_assembly_semantics" = xyes])

# Xen and Ether [RPM 2009-10-28]
AC_ARG_WITH(ether,
        [  --with-ether=PATH   prefix of Xen/Ether installation
                      Xen is a hypervisor for running virtual machines (http://www.xen.org)
                      Ether is a layer on top of Xen for accessing Windows XP OS-level data
                      structures (http://ether.gtisc.gatech.edu)],
        [AC_DEFINE(ROSE_USE_ETHER, 1, [Defined if Ether from Georgia Tech is available.])
	 if test "$with_ether" = "yes"; then ETHER_PREFIX=/usr; else ETHER_PREFIX="$with_ether"; fi],
        [with_ether=no])
AC_SUBST(ETHER_PREFIX)
AM_CONDITIONAL(ROSE_USE_ETHER,test "$with_ether" != "no")

# libgcrypt is used for computing SHA1 hashes of binary basic block semantics, among other things. [RPM 2010-05-12]
AC_CHECK_HEADERS(gcrypt.h)
AC_CHECK_LIB(gpg-error,gpg_strerror) dnl needed by statically linked libgcrypt
AC_CHECK_LIB(gcrypt,gcry_check_version)

# Added support for detection of libnuma, a NUMA aware memory allocation mechanism for many-core optimizations.
AC_CHECK_HEADERS(numa.h, [found_libnuma=yes])

if test "x$found_libnuma" = xyes; then
  AC_DEFINE([HAVE_NUMA_H],[],[Support for libnuma a NUMA memory allocation library for many-core optimizations])
fi

AM_CONDITIONAL(ROSE_USE_LIBNUMA, [test "x$found_libnuma" = xyes])

# Multi-thread support is needed by the simulator.  This also enables/disables major parts of threadSupport.[Ch] within
# the ROSE library.
AC_CHECK_HEADERS(pthread.h)

# Check for the __thread keyword.  This type qualifier creates objects that are thread local.
AC_MSG_CHECKING([for thread local storage type qualifier])
AC_COMPILE_IFELSE([struct S {int a, b;}; static __thread struct S x;],
	[AC_DEFINE(ROSE_THREAD_LOCAL_STORAGE, __thread, [Define to __thread keyword for thread local storage.])
	 AC_MSG_RESULT([__thread])],
	[AC_MSG_RESULT([not supported])])

# These headers and types are needed by projects/simulator [matzke 2009-07-02]
AC_CHECK_HEADERS([asm/ldt.h elf.h linux/types.h linux/dirent.h linux/unistd.h])
AC_CHECK_HEADERS([sys/types.h sys/mman.h sys/stat.h sys/uio.h sys/wait.h sys/utsname.h sys/ioctl.h sys/sysinfo.h sys/socket.h])
AC_CHECK_HEADERS([termios.h grp.h syscall.h])
AC_CHECK_FUNCS(pipe2)
AC_CHECK_TYPE(user_desc,
              AC_DEFINE(HAVE_USER_DESC, [], [Defined if the user_desc type is declared in <asm/ldt.h>]),
              [],
	      [#include <asm/ldt.h>])

# PC (7/10/2009): The Haskell build system expects a fully numeric version number.
PACKAGE_VERSION_NUMERIC=`echo $PACKAGE_VERSION | sed -e 's/\([[a-z]]\+\)/\.\1/; y/a-i/1-9/'`
AC_SUBST(PACKAGE_VERSION_NUMERIC)

# This CPP symbol is defined so we can check whether rose_config.h is included into a public header file.  It serves
# no other purpose.  The name must not begin with "ROSE_" but must have a high probability of being globally unique (which
# is why it ends with "_ROSE").
AC_DEFINE(CONFIG_ROSE, 1, [Always defined and used for checking whether global CPP namespace is polluted])

# End macro ROSE_SUPPORT_ROSE_PART_4.
]
)




dnl ---------------------------------------------------------------
dnl CLASSPATH_COND_IF(COND, SHELL-CONDITION, [IF-TRUE], [IF-FALSE])
dnl ---------------------------------------------------------------
dnl Automake 1.11 can emit conditional rules for AC_CONFIG_FILES,
dnl using AM_COND_IF.  This wrapper uses it if it is available,
dnl otherwise falls back to code compatible with Automake 1.9.6.
AC_DEFUN([CLASSPATH_COND_IF],
[m4_ifdef([AM_COND_IF],
  [AM_COND_IF([$1], [$3], [$4])],
  [if $2; then
     m4_default([$3], [:])
   else
     m4_default([$4], [:])
   fi
])])

#-----------------------------------------------------------------------------

AC_DEFUN([ROSE_SUPPORT_ROSE_PART_5],
[
# Begin macro ROSE_SUPPORT_ROSE_PART_5.

# DQ (9/21/2009): Debugging for RH release 5
echo "Testing the value of CC: (CC = $CC)"
echo "Testing the value of CPPFLAGS: (CPPFLAGS = $CPPFLAGS)"

echo "subdirs $subdirs"
AC_CONFIG_SUBDIRS([libltdl src/3rdPartyLibraries/libharu-2.1.0])

# This list should be the same as in build (search for Makefile.in)
CLASSPATH_COND_IF([ROSE_HAS_EDG_SOURCE], [test "x$has_edg_source" = "xyes"], [
AC_CONFIG_FILES([
src/frontend/CxxFrontend/EDG/Makefile
src/frontend/CxxFrontend/EDG/EDG_3.3/Makefile
src/frontend/CxxFrontend/EDG/EDG_3.3/misc/Makefile
src/frontend/CxxFrontend/EDG/EDG_3.3/src/Makefile
src/frontend/CxxFrontend/EDG/EDG_3.10/Makefile
src/frontend/CxxFrontend/EDG/EDG_3.10/misc/Makefile
src/frontend/CxxFrontend/EDG/EDG_3.10/src/Makefile
src/frontend/CxxFrontend/EDG/EDG_3.10/src/disp/Makefile
src/frontend/CxxFrontend/EDG/EDG_3.10/lib/Makefile
src/frontend/CxxFrontend/EDG/EDG_4.0/Makefile
src/frontend/CxxFrontend/EDG/EDG_4.0/misc/Makefile
src/frontend/CxxFrontend/EDG/EDG_4.0/src/Makefile
src/frontend/CxxFrontend/EDG/EDG_4.0/src/disp/Makefile
src/frontend/CxxFrontend/EDG/EDG_4.0/lib/Makefile
src/frontend/CxxFrontend/EDG/EDG_4.3/Makefile
src/frontend/CxxFrontend/EDG/EDG_4.3/misc/Makefile
src/frontend/CxxFrontend/EDG/EDG_4.3/src/Makefile
src/frontend/CxxFrontend/EDG/EDG_4.3/src/disp/Makefile
src/frontend/CxxFrontend/EDG/EDG_4.3/lib/Makefile
src/frontend/CxxFrontend/EDG/EDG_SAGE_Connection/Makefile
src/frontend/CxxFrontend/EDG/edgRose/Makefile
src/frontend/CxxFrontend/EDG/edg43Rose/Makefile
])], [])


# End macro ROSE_SUPPORT_ROSE_PART_5.
]
)


#-----------------------------------------------------------------------------
AC_DEFUN([ROSE_SUPPORT_ROSE_PART_6],
[
# Begin macro ROSE_SUPPORT_ROSE_PART_6.

# RV 9/14/2005: Removed src/3rdPartyLibraries/PDFLibrary/Makefile
# JJW 1/30/2008: Removed rose_paths.h as it is now built by a separate Makefile included from $(top_srcdir)/Makefile.am
AC_CONFIG_FILES([
stamp-h
Makefile
rose.docs
config/Makefile
config/include-staging/Makefile
src/Makefile
src/util/Makefile
src/util/stringSupport/Makefile
src/util/commandlineProcessing/Makefile
src/util/support/Makefile
src/util/graphs/Makefile
src/3rdPartyLibraries/Makefile
src/3rdPartyLibraries/MSTL/Makefile
src/3rdPartyLibraries/fortran-parser/Makefile
src/3rdPartyLibraries/antlr-jars/Makefile
src/3rdPartyLibraries/java-parser/Makefile
src/3rdPartyLibraries/qrose/Makefile
src/3rdPartyLibraries/qrose/Framework/Makefile
src/3rdPartyLibraries/qrose/QRoseLib/Makefile
src/3rdPartyLibraries/qrose/Widgets/Makefile
src/3rdPartyLibraries/qrose/Components/Makefile
src/3rdPartyLibraries/qrose/Components/Common/Makefile
src/3rdPartyLibraries/qrose/Components/Common/icons/Makefile
src/3rdPartyLibraries/qrose/Components/QueryBox/Makefile
src/3rdPartyLibraries/qrose/Components/SourceBox/Makefile
src/3rdPartyLibraries/qrose/Components/TreeBox/Makefile
src/3rdPartyLibraries/UPR/Makefile
src/3rdPartyLibraries/UPR/docs/Makefile
src/3rdPartyLibraries/UPR/docs/doxygen/Makefile
src/3rdPartyLibraries/UPR/docs/doxygen/doxy.conf
src/3rdPartyLibraries/UPR/examples/Makefile
src/3rdPartyLibraries/UPR/examples/cuda/Makefile
src/3rdPartyLibraries/UPR/examples/opencl/Makefile
src/3rdPartyLibraries/UPR/examples/xomp/Makefile
src/3rdPartyLibraries/UPR/include/Makefile
src/3rdPartyLibraries/UPR/include/UPR/Makefile
src/3rdPartyLibraries/UPR/lib/Makefile
src/3rdPartyLibraries/UPR/tools/Makefile
src/ROSETTA/Makefile
src/ROSETTA/src/Makefile
src/frontend/Makefile
src/frontend/SageIII/Makefile
src/frontend/SageIII/sage.docs
src/frontend/SageIII/astFixup/Makefile
src/frontend/SageIII/astPostProcessing/Makefile
src/frontend/SageIII/astFileIO/Makefile
src/frontend/SageIII/astMerge/Makefile
src/frontend/SageIII/sageInterface/Makefile
src/frontend/SageIII/virtualCFG/Makefile
src/frontend/SageIII/astTokenStream/Makefile
src/frontend/SageIII/astHiddenTypeAndDeclarationLists/Makefile
src/frontend/SageIII/astVisualization/Makefile
src/frontend/SageIII/GENERATED_CODE_DIRECTORY_Cxx_Grammar/Makefile
src/frontend/SageIII/astFromString/Makefile
src/frontend/SageIII/includeDirectivesProcessing/Makefile
src/frontend/CxxFrontend/Makefile
src/frontend/CxxFrontend/Clang/Makefile
src/frontend/OpenFortranParser_SAGE_Connection/Makefile
src/frontend/ECJ_ROSE_Connection/Makefile
src/frontend/PHPFrontend/Makefile
src/frontend/PythonFrontend/Makefile
src/frontend/BinaryDisassembly/Makefile
src/frontend/BinaryLoader/Makefile
src/frontend/BinaryFormats/Makefile
src/frontend/Disassemblers/Makefile
src/midend/Makefile
src/midend/binaryAnalyses/Makefile
src/midend/programAnalysis/Makefile
src/midend/programAnalysis/staticSingleAssignment/Makefile
src/midend/programAnalysis/ssaUnfilteredCfg/Makefile
src/midend/programAnalysis/systemDependenceGraph/Makefile
src/midend/programTransformation/extractFunctionArgumentsNormalization/Makefile
src/midend/programTransformation/loopProcessing/Makefile
src/backend/Makefile
src/roseSupport/Makefile
src/roseExtensions/Makefile
src/roseExtensions/sqlite3x/Makefile
src/roseExtensions/dataStructureTraversal/Makefile
src/roseExtensions/highLevelGrammar/Makefile
src/roseExtensions/qtWidgets/Makefile
src/roseExtensions/qtWidgets/AsmInstructionBar/Makefile
src/roseExtensions/qtWidgets/AsmView/Makefile
src/roseExtensions/qtWidgets/AstBrowserWidget/Makefile
src/roseExtensions/qtWidgets/AstGraphWidget/Makefile
src/roseExtensions/qtWidgets/AstProcessing/Makefile
src/roseExtensions/qtWidgets/BeautifiedAst/Makefile
src/roseExtensions/qtWidgets/FlopCounter/Makefile
src/roseExtensions/qtWidgets/InstructionCountAnnotator/Makefile
src/roseExtensions/qtWidgets/KiviatView/Makefile
src/roseExtensions/qtWidgets/MetricFilter/Makefile
src/roseExtensions/qtWidgets/MetricsConfig/Makefile
src/roseExtensions/qtWidgets/MetricsKiviat/Makefile
src/roseExtensions/qtWidgets/NodeInfoWidget/Makefile
src/roseExtensions/qtWidgets/ProjectManager/Makefile
src/roseExtensions/qtWidgets/PropertyTreeWidget/Makefile
src/roseExtensions/qtWidgets/QtGradientEditor/Makefile
src/roseExtensions/qtWidgets/QCodeEditWidget/Makefile
src/roseExtensions/qtWidgets/QCodeEditWidget/QCodeEdit/Makefile
src/roseExtensions/qtWidgets/QCodeEditWidget/QCodeEdit/document/Makefile
src/roseExtensions/qtWidgets/QCodeEditWidget/QCodeEdit/widgets/Makefile
src/roseExtensions/qtWidgets/QCodeEditWidget/QCodeEdit/qnfa/Makefile
src/roseExtensions/qtWidgets/RoseCodeEdit/Makefile
src/roseExtensions/qtWidgets/RoseFileSelector/Makefile
src/roseExtensions/qtWidgets/SrcBinView/Makefile
src/roseExtensions/qtWidgets/TaskSystem/Makefile
src/roseExtensions/qtWidgets/TreeModel/Makefile
src/roseExtensions/qtWidgets/util/Makefile
src/roseExtensions/qtWidgets/WidgetCreator/Makefile
src/roseExtensions/roseHPCToolkit/Makefile
src/roseExtensions/roseHPCToolkit/src/Makefile
src/roseExtensions/roseHPCToolkit/include/Makefile
src/roseExtensions/roseHPCToolkit/include/rosehpct/Makefile
src/roseExtensions/roseHPCToolkit/src/util/Makefile
src/roseExtensions/roseHPCToolkit/include/rosehpct/util/Makefile
src/roseExtensions/roseHPCToolkit/src/xml/Makefile
src/roseExtensions/roseHPCToolkit/include/rosehpct/xml/Makefile
src/roseExtensions/roseHPCToolkit/src/xml-xercesc/Makefile
src/roseExtensions/roseHPCToolkit/include/rosehpct/xml-xercesc/Makefile
src/roseExtensions/roseHPCToolkit/src/profir/Makefile
src/roseExtensions/roseHPCToolkit/include/rosehpct/profir/Makefile
src/roseExtensions/roseHPCToolkit/src/gprof/Makefile
src/roseExtensions/roseHPCToolkit/include/rosehpct/gprof/Makefile
src/roseExtensions/roseHPCToolkit/src/xml2profir/Makefile
src/roseExtensions/roseHPCToolkit/include/rosehpct/xml2profir/Makefile
src/roseExtensions/roseHPCToolkit/src/sage/Makefile
src/roseExtensions/roseHPCToolkit/include/rosehpct/sage/Makefile
src/roseExtensions/roseHPCToolkit/src/profir2sage/Makefile
src/roseExtensions/roseHPCToolkit/include/rosehpct/profir2sage/Makefile
src/roseExtensions/roseHPCToolkit/docs/Makefile
src/roseIndependentSupport/Makefile
src/roseIndependentSupport/dot2gml/Makefile
projects/AstEquivalence/Makefile
projects/AstEquivalence/gui/Makefile
projects/BabelPreprocessor/Makefile
projects/BinFuncDetect/Makefile
projects/BinQ/Makefile
projects/BinaryCloneDetection/Makefile
projects/BinaryCloneDetection/gui/Makefile
projects/C_to_Promela/Makefile
projects/CertSecureCodeProject/Makefile
projects/CloneDetection/Makefile
projects/DataFaultTolerance/Makefile
projects/DataFaultTolerance/src/Makefile
projects/DataFaultTolerance/test/Makefile
projects/DataFaultTolerance/test/array/Makefile
projects/DataFaultTolerance/test/array/transformation/Makefile
projects/DataFaultTolerance/test/array/transformation/tests/Makefile
projects/DataFaultTolerance/test/array/faultCheck/Makefile
projects/DatalogAnalysis/Makefile
projects/DatalogAnalysis/relationTranslatorGenerator/Makefile
projects/DatalogAnalysis/src/DBFactories/Makefile
projects/DatalogAnalysis/src/Makefile
projects/DatalogAnalysis/tests/Makefile
projects/DistributedMemoryAnalysisCompass/Makefile
projects/DocumentationGenerator/Makefile
projects/FiniteStateModelChecker/Makefile
projects/graphColoring/Makefile
projects/HeaderFilesInclusion/HeaderFilesGraphGenerator/Makefile
projects/HeaderFilesInclusion/HeaderFilesNotIncludedList/Makefile
projects/HeaderFilesInclusion/Makefile
projects/MPI_Tools/Makefile
projects/MPI_Tools/MPICodeMotion/Makefile
projects/MPI_Tools/MPIDeterminismAnalysis/Makefile
projects/MacroRewrapper/Makefile
projects/Makefile
projects/OpenMP_Analysis/Makefile
projects/OpenMP_Checker/Makefile
projects/OpenMP_Translator/Makefile
projects/OpenMP_Translator/includes/Makefile
projects/OpenMP_Translator/tests/Makefile
projects/OpenMP_Translator/tests/cvalidationsuite/Makefile
projects/OpenMP_Translator/tests/developmentTests/Makefile
projects/OpenMP_Translator/tests/epcc-c/Makefile
projects/OpenMP_Translator/tests/npb2.3-omp-c/BT/Makefile
projects/OpenMP_Translator/tests/npb2.3-omp-c/CG/Makefile
projects/OpenMP_Translator/tests/npb2.3-omp-c/EP/Makefile
projects/OpenMP_Translator/tests/npb2.3-omp-c/FT/Makefile
projects/OpenMP_Translator/tests/npb2.3-omp-c/IS/Makefile
projects/OpenMP_Translator/tests/npb2.3-omp-c/LU/Makefile
projects/OpenMP_Translator/tests/npb2.3-omp-c/MG/Makefile
projects/OpenMP_Translator/tests/npb2.3-omp-c/Makefile
projects/OpenMP_Translator/tests/npb2.3-omp-c/SP/Makefile
projects/pragmaParsing/Makefile
projects/QtDesignerPlugins/Makefile
projects/RTED/CppRuntimeSystem/DebuggerQt/Makefile
projects/RTED/CppRuntimeSystem/Makefile
projects/RTED/Makefile
projects/RoseQt/AstViewer/Makefile
projects/RoseQt/Makefile
projects/SatSolver/Makefile
projects/UpcTranslation/Makefile
projects/UpcTranslation/tests/Makefile
projects/arrayOptimization/Makefile
projects/arrayOptimization/test/Makefile
projects/autoParallelization/Makefile
projects/autoParallelization/tests/Makefile
projects/autoTuning/Makefile
projects/autoTuning/doc/Makefile
projects/autoTuning/tests/Makefile
projects/backstroke/Makefile
projects/backstroke/eventDetection/Makefile
projects/backstroke/eventDetection/ROSS/Makefile
projects/backstroke/eventDetection/SPEEDES/Makefile
projects/backstroke/normalizations/Makefile
projects/backstroke/slicing/Makefile
projects/backstroke/valueGraph/Makefile
projects/backstroke/valueGraph/headerUnparser/Makefile
projects/backstroke/pluggableReverser/Makefile
projects/backstroke/testCodeGeneration/Makefile
projects/backstroke/restrictedLanguage/Makefile
projects/backstroke/tests/Makefile
projects/backstroke/tests/cfgReverseCodeGenerator/Makefile
projects/backstroke/tests/expNormalizationTest/Makefile
projects/backstroke/tests/pluggableReverserTest/Makefile
projects/backstroke/tests/restrictedLanguageTest/Makefile
projects/backstroke/tests/testCodeBuilderTest/Makefile
projects/backstroke/tests/incrementalInversionTest/Makefile
projects/backstroke/utilities/Makefile
projects/backstroke/sdg/Makefile
projects/binCompass/Makefile
projects/binCompass/analyses/Makefile
projects/binCompass/graphanalyses/Makefile
projects/binaryVisualization/Makefile
projects/bugSeeding/Makefile
projects/bugSeeding/bugSeeding.tex
projects/checkPointExample/Makefile
projects/compass/Makefile
projects/compass/src/Makefile
projects/compass/src/compassSupport/Makefile
projects/compass/src/util/C-API/Makefile
projects/compass/src/util/MPIAbstraction/Makefile
projects/compass/src/util/MPIAbstraction/alt-mpi-headers/Makefile
projects/compass/src/util/MPIAbstraction/alt-mpi-headers/mpich-1.2.7p1/Makefile
projects/compass/src/util/MPIAbstraction/alt-mpi-headers/mpich-1.2.7p1/include/Makefile
projects/compass/src/util/MPIAbstraction/alt-mpi-headers/mpich-1.2.7p1/include/mpi2c++/Makefile
projects/compass/src/util/Makefile
projects/compass/tools/Makefile
projects/compass/tools/compass/Makefile
projects/compass/tools/compass/buildInterpreter/Makefile
projects/compass/tools/compass/doc/Makefile
projects/compass/tools/compass/doc/compass.tex
projects/compass/tools/compass/gui/Makefile
projects/compass/tools/compass/gui2/Makefile
projects/compass/tools/compass/tests/Compass_C_tests/Makefile
projects/compass/tools/compass/tests/Compass_Cxx_tests/Makefile
projects/compass/tools/compass/tests/Compass_OpenMP_tests/Makefile
projects/compass/tools/compass/tests/Makefile
projects/compass/tools/compassVerifier/Makefile
projects/compass/tools/sampleCompassSubset/Makefile
projects/dataStructureGraphing/Makefile
projects/extractMPISkeleton/Makefile
projects/extractMPISkeleton/src/Makefile
projects/extractMPISkeleton/tests/Makefile
projects/haskellport/Makefile
projects/haskellport/Setup.hs
projects/haskellport/rose.cabal.in
projects/highLevelGrammars/Makefile
projects/interpreter/Makefile
projects/javaport/Makefile
projects/palette/Makefile
projects/programModeling/Makefile
projects/roseToLLVM/Analysis/Alias/Makefile
projects/roseToLLVM/Analysis/Alias/src/Makefile
projects/roseToLLVM/Analysis/Alias/tests/Makefile
projects/roseToLLVM/Analysis/Makefile
projects/roseToLLVM/Makefile
projects/roseToLLVM/src/Makefile
projects/roseToLLVM/src/rosetollvm/Makefile
projects/roseToLLVM/tests/Makefile
projects/RosePolly/Makefile
projects/simulator/Makefile
projects/symbolicAnalysisFramework/Makefile
projects/symbolicAnalysisFramework/src/chkptRangeAnalysis/Makefile
projects/symbolicAnalysisFramework/src/external/Makefile
projects/symbolicAnalysisFramework/src/mpiAnal/Makefile
projects/symbolicAnalysisFramework/src/ompAnal/Makefile
projects/symbolicAnalysisFramework/src/unionFind/Makefile
projects/symbolicAnalysisFramework/src/varBitVector/Makefile
projects/symbolicAnalysisFramework/src/varLatticeVector/Makefile
projects/symbolicAnalysisFramework/src/taintAnalysis/Makefile
projects/symbolicAnalysisFramework/src/parallelCFG/Makefile
projects/symbolicAnalysisFramework/src/Makefile
projects/symbolicAnalysisFramework/tests/Makefile
projects/symbolicAnalysisFramework/include/Makefile
projects/taintcheck/Makefile
projects/RTC/Makefile
projects/PowerAwareCompiler/Makefile
projects/ManyCoreRuntime/Makefile
projects/ManyCoreRuntime/docs/Makefile
projects/minitermite/Makefile
projects/minitermite/Doxyfile
projects/minitermite/src/minitermite/minitermite.h
projects/mint/Makefile
projects/mint/src/Makefile
projects/mint/tests/Makefile
projects/mpiAnalysis/Makefile
projects/mpiAnalysis/staticMatching/Makefile
projects/mpiAnalysis/staticMatching/src/Makefile
projects/mpiAnalysis/staticMatching/tests/Makefile
projects/mpiAnalysis/simpleStaticMarking/Makefile
projects/mpiAnalysis/simpleStaticMarking/src/Makefile
projects/mpiAnalysis/simpleStaticMarking/tests/Makefile
projects/vectorization/Makefile
projects/vectorization/src/Makefile
projects/vectorization/tests/Makefile
projects/Fortran_to_C/Makefile
projects/Fortran_to_C/src/Makefile
projects/Fortran_to_C/tests/Makefile
projects/traceAnalysis/Makefile
projects/PolyhedralModel/Makefile
projects/PolyhedralModel/src/Makefile
projects/PolyhedralModel/docs/Makefile
projects/PolyhedralModel/tests/Makefile
projects/PolyhedralModel/tests/rose-pragma/Makefile
projects/PolyhedralModel/tests/rose-max-cover/Makefile
projects/PolyhedralModel/tests/cuda-kernel/Makefile
projects/PolyhedralModel/projects/Makefile
projects/PolyhedralModel/projects/loop-ocl/Makefile
projects/PolyhedralModel/projects/spmd-generator/Makefile
projects/PolyhedralModel/projects/polygraph/Makefile
projects/PolyhedralModel/projects/utils/Makefile
projects/mpiAnalOptTools/Makefile
projects/mpiAnalOptTools/mpiToGOAL/Makefile
projects/mpiAnalOptTools/mpiToGOAL/src/Makefile
projects/mpiAnalOptTools/mpiToGOAL/tests/Makefile
tests/Makefile
tests/RunTests/Makefile
tests/RunTests/A++Tests/Makefile
tests/RunTests/AstDeleteTests/Makefile
tests/RunTests/FortranTests/Makefile
tests/RunTests/FortranTests/LANL_POP/Makefile
tests/RunTests/PythonTests/Makefile
tests/PerformanceTests/Makefile
tests/CompilerOptionsTests/Makefile
tests/CompilerOptionsTests/testCpreprocessorOption/Makefile
tests/CompilerOptionsTests/testWave/Makefile
tests/CompilerOptionsTests/testForSpuriousOutput/Makefile
tests/CompilerOptionsTests/testHeaderFileOutput/Makefile
tests/CompilerOptionsTests/testOutputFileOption/Makefile
tests/CompilerOptionsTests/testGnuOptions/Makefile
tests/CompilerOptionsTests/testFileNamesAndExtensions/Makefile
tests/CompilerOptionsTests/testFileNamesAndExtensions/fileNames/Makefile
tests/CompilerOptionsTests/testFileNamesAndExtensions/fileExtensions/Makefile
tests/CompilerOptionsTests/testFileNamesAndExtensions/fileExtensions/caseInsensitive/Makefile
tests/CompilerOptionsTests/testFileNamesAndExtensions/fileExtensions/caseSensitive/Makefile
tests/CompilerOptionsTests/testGenerateSourceFileNames/Makefile
tests/CompileTests/Makefile
tests/CompileTests/A++Tests/Makefile
tests/CompileTests/P++Tests/Makefile
tests/CompileTests/A++Code/Makefile
tests/CompileTests/OvertureCode/Makefile
tests/CompileTests/ElsaTestCases/Makefile
tests/CompileTests/ElsaTestCases/ctests/Makefile
tests/CompileTests/ElsaTestCases/gnu/Makefile
tests/CompileTests/ElsaTestCases/kandr/Makefile
tests/CompileTests/ElsaTestCases/std/Makefile
tests/CompileTests/C_tests/Makefile
tests/CompileTests/C99_tests/Makefile
tests/CompileTests/Java_tests/Makefile
tests/CompileTests/Cxx_tests/Makefile
tests/CompileTests/C_subset_of_Cxx_tests/Makefile
tests/CompileTests/Fortran_tests/Makefile
tests/CompileTests/Fortran_tests/LANL_POP/Makefile
tests/CompileTests/Fortran_tests/gfortranTestSuite/Makefile
tests/CompileTests/Fortran_tests/gfortranTestSuite/gfortran.fortran-torture/Makefile
tests/CompileTests/Fortran_tests/gfortranTestSuite/gfortran.dg/Makefile
tests/CompileTests/CAF2_tests/Makefile
tests/CompileTests/RoseExample_tests/Makefile
tests/CompileTests/ExpressionTemplateExample_tests/Makefile
tests/CompileTests/PythonExample_tests/Makefile
tests/CompileTests/Python_tests/Makefile
tests/CompileTests/UPC_tests/Makefile
tests/CompileTests/OpenMP_tests/Makefile
tests/CompileTests/OpenMP_tests/fortran/Makefile
tests/CompileTests/OpenMP_tests/cvalidation/Makefile
tests/CompileTests/copyAST_tests/Makefile
tests/CompileTests/colorAST_tests/Makefile
tests/CompileTests/mergeAST_tests/Makefile
tests/CompileTests/unparseToString_tests/Makefile
tests/CompileTests/boost_tests/Makefile
tests/CompileTests/virtualCFG_tests/Makefile
tests/CompileTests/staticCFG_tests/Makefile
tests/CompileTests/uninitializedField_tests/Makefile
tests/CompileTests/sourcePosition_tests/Makefile
tests/CompileTests/hiddenTypeAndDeclarationListTests/Makefile
tests/CompileTests/sizeofOperation_tests/Makefile
tests/CompileTests/MicrosoftWindows_tests/Makefile
tests/CompileTests/nameQualificationAndTypeElaboration_tests/Makefile
tests/CompileTests/NewEDGInterface_C_tests/Makefile
tests/CompileTests/UnparseHeadersTests/Makefile
tests/CompileTests/CudaTests/Makefile
tests/CompileTests/OpenClTests/Makefile
tests/CompileTests/EDG_4_x/Makefile
tests/CompilerOptionsTests/collectAllCommentsAndDirectives_tests/Makefile
tests/CompilerOptionsTests/preinclude_tests/Makefile
tests/CompilerOptionsTests/tokenStream_tests/Makefile
tests/roseTests/Makefile
tests/roseTests/abstractMemoryObjectTests/Makefile
tests/roseTests/PHPTests/Makefile
tests/roseTests/astFileIOTests/Makefile
tests/roseTests/astInliningTests/Makefile
tests/roseTests/astInterfaceTests/Makefile
tests/roseTests/astLValueTests/Makefile
tests/roseTests/astMergeTests/Makefile
tests/roseTests/astOutliningTests/Makefile
tests/roseTests/astOutliningTests/fortranTests/Makefile
tests/roseTests/astPerformanceTests/Makefile
tests/roseTests/astProcessingTests/Makefile
tests/roseTests/astQueryTests/Makefile
tests/roseTests/astRewriteTests/Makefile
tests/roseTests/astSymbolTableTests/Makefile
tests/roseTests/astTokenStreamTests/Makefile
tests/roseTests/binaryTests/Makefile
tests/roseTests/binaryTests/SemanticVerification/Makefile
tests/roseTests/binaryTests/libraryIdentification_tests/Makefile
tests/roseTests/binaryTests/Pin_tests/Makefile
tests/roseTests/binaryTests/Dwarf_tests/Makefile
tests/roseTests/loopProcessingTests/Makefile
tests/roseTests/ompLoweringTests/Makefile
tests/roseTests/ompLoweringTests/fortran/Makefile
tests/roseTests/programAnalysisTests/Makefile
tests/roseTests/programAnalysisTests/defUseAnalysisTests/Makefile
tests/roseTests/programAnalysisTests/sideEffectAnalysisTests/Makefile
tests/roseTests/programAnalysisTests/staticInterproceduralSlicingTests/Makefile
tests/roseTests/programAnalysisTests/testCallGraphAnalysis/Makefile
tests/roseTests/programAnalysisTests/variableLivenessTests/Makefile
tests/roseTests/programAnalysisTests/variableRenamingTests/Makefile
tests/roseTests/programAnalysisTests/ssa_UnfilteredCfg_Test/Makefile
tests/roseTests/programAnalysisTests/staticSingleAssignmentTests/Makefile
tests/roseTests/programAnalysisTests/generalDataFlowAnalysisTests/Makefile
tests/roseTests/programAnalysisTests/systemDependenceGraphTests/Makefile
tests/roseTests/programTransformationTests/Makefile
tests/roseTests/programTransformationTests/extractFunctionArgumentsTest/Makefile
tests/roseTests/roseHPCToolkitTests/Makefile
tests/roseTests/roseHPCToolkitTests/data/01/ANALYSIS/Makefile
tests/roseTests/roseHPCToolkitTests/data/01/Makefile
tests/roseTests/roseHPCToolkitTests/data/01/PROFILE/Makefile
tests/roseTests/roseHPCToolkitTests/data/01/PROGRAM/Makefile
tests/roseTests/roseHPCToolkitTests/data/02/Makefile
tests/roseTests/roseHPCToolkitTests/data/02/PROFILE/Makefile
tests/roseTests/roseHPCToolkitTests/data/02/struct_ls/Makefile
tests/roseTests/roseHPCToolkitTests/data/03/Makefile
tests/roseTests/roseHPCToolkitTests/data/03/PROFILE/Makefile
tests/roseTests/roseHPCToolkitTests/data/03/struct_ls/Makefile
tests/roseTests/roseHPCToolkitTests/data/Makefile
tests/roseTests/utilTests/Makefile
tests/roseTests/fileLocation_tests/Makefile
tests/roseTests/graph_tests/Makefile
tests/roseTests/mergeTraversal_tests/Makefile
tests/translatorTests/Makefile
tutorial/Makefile
tutorial/exampleMakefile
tutorial/roseHPCT/Makefile
tutorial/outliner/Makefile
tutorial/intelPin/Makefile
tutorial/binaryAnalysis/Makefile
exampleTranslators/Makefile
exampleTranslators/AstCopyReplTester/Makefile
exampleTranslators/DOTGenerator/Makefile
exampleTranslators/PDFGenerator/Makefile
exampleTranslators/documentedExamples/Makefile
exampleTranslators/documentedExamples/simpleTranslatorExamples/Makefile
exampleTranslators/documentedExamples/simpleTranslatorExamples/exampleMakefile
exampleTranslators/documentedExamples/AstRewriteExamples/Makefile
exampleTranslators/documentedExamples/dataBaseExamples/Makefile
exampleTranslators/defaultTranslator/Makefile
docs/Makefile
docs/Rose/footer.html
docs/Rose/leftmenu.html
docs/Rose/AvailableDocumentation.docs
docs/Rose/Makefile
docs/Rose/manual.tex
docs/Rose/ROSE_InstallationInstructions.tex
docs/Rose/ROSE_Exam.tex
docs/Rose/ROSE_DeveloperInstructions.tex
docs/Rose/ROSE_DemoGuide.tex
docs/Rose/gettingStarted.tex
docs/Rose/rose.cfg
docs/Rose/roseQtWidgets.doxygen
docs/Rose/sage.cfg
docs/Rose/Tutorial/Makefile
docs/Rose/Tutorial/tutorial.tex
docs/Rose/Tutorial/gettingStarted.tex
docs/testDoxygen/test.cfg
docs/testDoxygen/Makefile
tools/Makefile
scripts/Makefile
demo/Makefile
demo/qrose/Makefile
binaries/Makefile
binaries/samples/Makefile
])

dnl
dnl Compass2
dnl
AC_CONFIG_FILES([
projects/compass2/Makefile
projects/compass2/docs/Makefile
projects/compass2/docs/asciidoc/Makefile
projects/compass2/docs/doxygen/doxygen.config
projects/compass2/docs/doxygen/Makefile
projects/compass2/tests/Makefile
projects/compass2/tests/checkers/Makefile
projects/compass2/tests/checkers/dead_function/Makefile
projects/compass2/tests/checkers/dead_function/compass_parameters.xml
projects/compass2/tests/checkers/default_argument/Makefile
projects/compass2/tests/checkers/default_argument/compass_parameters.xml
projects/compass2/tests/checkers/function_pointer/Makefile
projects/compass2/tests/checkers/function_pointer/compass_parameters.xml
projects/compass2/tests/checkers/function_prototype/Makefile
projects/compass2/tests/checkers/function_prototype/compass_parameters.xml
projects/compass2/tests/checkers/function_with_multiple_returns/Makefile
projects/compass2/tests/checkers/function_with_multiple_returns/compass_parameters.xml
projects/compass2/tests/checkers/global_variables/Makefile
projects/compass2/tests/checkers/global_variables/compass_parameters.xml
projects/compass2/tests/checkers/keyword_macro/Makefile
projects/compass2/tests/checkers/keyword_macro/compass_parameters.xml
projects/compass2/tests/checkers/non_global_cpp_directive/Makefile
projects/compass2/tests/checkers/non_global_cpp_directive/compass_parameters.xml
projects/compass2/tests/checkers/non_static_array_size/Makefile
projects/compass2/tests/checkers/non_static_array_size/compass_parameters.xml
projects/compass2/tests/checkers/variable_name_similarity/Makefile
projects/compass2/tests/checkers/variable_name_similarity/compass_parameters.xml
projects/compass2/tests/core/Makefile
projects/compass2/tests/core/compass_parameters.xml
])

# DQ (10/27/2010): New Fortran tests (from gfortan test suite).
# tests/CompileTests/Fortran_tests/gfortranTestSuite/Makefile
# tests/CompileTests/Fortran_tests/gfortranTestSuite/gfortran.fortran-torture/Makefile
# tests/CompileTests/Fortran_tests/gfortranTestSuite/gfortran.dg/Makefile

# DQ (8/12/2010): We want to get permission to distribute these files as test codes.
# tests/CompileTests/Fortran_tests/LANL_POP/Makefile

# DQ (10/24/2009): We don't need to support EDG 3.10 anymore.
# src/frontend/CxxFrontend/EDG_3.10/Makefile
# src/frontend/CxxFrontend/EDG_3.10/misc/Makefile
# src/frontend/CxxFrontend/EDG_3.10/src/Makefile
# src/frontend/CxxFrontend/EDG_3.10/src/disp/Makefile
# src/frontend/CxxFrontend/EDG_3.10/lib/Makefile


# DQ (9/12/2009): Removed so that this can be added properly a little later.
# This currently breaks "make distcheck"
# projects/StaticDynamicAnalysis/DynamicCPU/Makefile


# DQ (12/31/2008): Skip these, since we don't have SPEC and NAS benchmarks setup yet.
# developersScratchSpace/Dan/Fortran_tests/NPB3.2-SER/Makefile
# developersScratchSpace/Dan/Fortran_tests/NPB3.2-SER/BT/Makefile
# developersScratchSpace/Dan/SpecCPU2006/Makefile
# developersScratchSpace/Dan/SpecCPU2006/config/Makefile
# developersScratchSpace/Dan/SpecCPU2006/config/rose.cfg

# DQ (9/12/2008): Removed older version of QRose (now an external project)
# src/roseIndependentSupport/graphicalUserInterface/Makefile
# src/roseIndependentSupport/graphicalUserInterface/src/Makefile
# src/roseIndependentSupport/graphicalUserInterface/src/QRTree/Makefile
# src/roseIndependentSupport/graphicalUserInterface/src/QRCodeBox/Makefile
# src/roseIndependentSupport/graphicalUserInterface/src/QRGui/Makefile
# src/roseIndependentSupport/graphicalUserInterface/src/QRGui/icons22/Makefile
# src/roseIndependentSupport/graphicalUserInterface/src/QRQueryBox/Makefile
# exampleTranslators/graphicalUserInterfaceExamples/Makefile
# exampleTranslators/graphicalUserInterfaceExamples/slicing/Makefile
# exampleTranslators/graphicalUserInterfaceExamples/attributes/Makefile
# exampleTranslators/graphicalUserInterfaceExamples/query/Makefile
# exampleTranslators/graphicalUserInterfaceExamples/layout/Makefile

# End macro ROSE_SUPPORT_ROSE_PART_6.
]
)


#-----------------------------------------------------------------------------


AC_DEFUN([ROSE_SUPPORT_ROSE_PART_7],
[
# Begin macro ROSE_SUPPORT_ROSE_PART_7.

AC_CONFIG_COMMANDS([default],[[
     echo "Ensuring Grammar in the compile tree (assuming source tree is not the same as the compile tree)."
     pathToSourceDir="`cd $srcdir && pwd`"
     test -d src/ROSETTA/Grammar || ( rm -rf src/ROSETTA/Grammar && ln -s "$pathToSourceDir/src/ROSETTA/Grammar" src/ROSETTA/Grammar )
]],[[
]])

# Generate rose_paths.C
AC_CONFIG_COMMANDS([rose_paths.C], [[
	make src/util/rose_paths.C
]])

# Generate public config file from private config file. The public config file adds "ROSE_" to the beginning of
# certain symbols. See scripts/publicConfiguration.pl for details.
AC_CONFIG_COMMANDS([rosePublicConfig.h],[[
	make rosePublicConfig.h
]])


# End macro ROSE_SUPPORT_ROSE_PART_7.
]
)

