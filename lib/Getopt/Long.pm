# GetOpt::Long.pm -- POSIX compatible options parsing

# RCS Status      : $Id: GetoptLong.pm,v 2.3 1996-04-05 21:03:05+02 jv Exp $
# Author          : Johan Vromans
# Created On      : Tue Sep 11 15:00:12 1990
# Last Modified By: Johan Vromans
# Last Modified On: Fri Apr  5 21:02:52 1996
# Update Count    : 433
# Status          : Released

package Getopt::Long;
require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(&GetOptions $REQUIRE_ORDER $PERMUTE $RETURN_IN_ORDER);
$VERSION = sprintf("%d.%02d", '$Revision: 2.3 $ ' =~ /(\d+)\.(\d+)/);
use vars qw($autoabbrev $getopt_compat $ignorecase $bundling $order
	    $error $debug $REQUIRE_ORDER $PERMUTE $RETURN_IN_ORDER
	    $VERSION $major_version $minor_version);
use strict;

=head1 NAME

GetOptions - extended processing of command line options

=head1 SYNOPSIS

  use Getopt::Long;
  $result = GetOptions (...option-descriptions...);

=head1 DESCRIPTION

The Getopt::Long module implements an extended getopt function called
GetOptions(). This function adheres to the POSIX syntax for command
line options, with GNU extensions. In general, this means that options
have long names instead of single letters, and are introduced with a
double dash "--". Support for bundling of command line options, as was
the case with the more traditional single-letter approach, is provided
but not enabled by default. For example, the UNIX "ps" command can be
given the command line "option"

  -vax

which means the combination of B<-v>, B<-a> and B<-x>. With the new
syntax B<--vax> would be a single option, probably indicating a
computer architecture. 

Command line options can be used to set values. These values can be
specified in one of two ways:

  --size 24
  --size=24

GetOptions is called with a list of option-descriptions, each of which
consists of two elements: the option specifier and the option linkage.
The option specifier defines the name of the option and, optionally,
the value it can take. The option linkage is usually a reference to a
variable that will be set when the option is used. For example, the
following call to GetOptions:

  &GetOptions("size=i" => \$offset);

will accept a command line option "size" that must have an integer
value. With a command line of "--size 24" this will cause the variable
$offset to get the value 24.

Alternatively, the first argument to GetOptions may be a reference to
a HASH describing the linkage for the options. The following call is
equivalent to the example above:

  %optctl = ("size" => \$offset);
  &GetOptions(\%optctl, "size=i");

Linkage may be specified using either of the above methods, or both.
Linkage specified in the argument list takes precedence over the
linkage specified in the HASH.

The command line options are taken from array @ARGV. Upon completion
of GetOptions, @ARGV will contain the rest (i.e. the non-options) of
the command line.
 
Each option specifier designates the name of the option, optionally
followed by an argument specifier. Values for argument specifiers are:

=over 8

=item E<lt>noneE<gt>

Option does not take an argument. 
The option variable will be set to 1.

=item !

Option does not take an argument and may be negated, i.e. prefixed by
"no". E.g. "foo!" will allow B<--foo> (with value 1) and B<-nofoo>
(with value 0).
The option variable will be set to 1, or 0 if negated.

=item =s

Option takes a mandatory string argument.
This string will be assigned to the option variable.
Note that even if the string argument starts with B<-> or B<-->, it
will not be considered an option on itself.

=item :s

Option takes an optional string argument.
This string will be assigned to the option variable.
If omitted, it will be assigned "" (an empty string).
If the string argument starts with B<-> or B<-->, it
will be considered an option on itself.

=item =i

Option takes a mandatory integer argument.
This value will be assigned to the option variable.
Note that the value may start with B<-> to indicate a negative
value. 

=item :i

Option takes an optional integer argument.
This value will be assigned to the option variable.
If omitted, the value 0 will be assigned.
Note that the value may start with B<-> to indicate a negative
value.

=item =f

Option takes a mandatory real number argument.
This value will be assigned to the option variable.
Note that the value may start with B<-> to indicate a negative
value.

=item :f

Option takes an optional real number argument.
This value will be assigned to the option variable.
If omitted, the value 0 will be assigned.

=back

A lone dash B<-> is considered an option, the corresponding option
name is the empty string.

A double dash on itself B<--> signals end of the options list.

=head2 Linkage specification

The linkage specifier is optional. If no linkage is explicitly
specified but a ref HASH is passed, GetOptions will place the value in
the HASH. For example:

  %optctl = ();
  &GetOptions (\%optctl, "size=i");

will perform the equivalent of the assignment

  $optctl{"size"} = 24;

For array options, a reference to an array is used, e.g.:

  %optctl = ();
  &GetOptions (\%optctl, "sizes=i@");

with command line "-sizes 24 -sizes 48" will perform the equivalent of
the assignment

  $optctl{"sizes"} = [24, 48];

If no linkage is explicitly specified and no ref HASH is passed,
GetOptions will put the value in a global variable named after the
option, prefixed by "opt_". To yield a usable Perl variable,
characters that are not part of the syntax for variables are
translated to underscores. For example, "--fpp-struct-return" will set
the variable $opt_fpp_struct_return. Note that this variable resides
in the namespace of the calling program, not necessarily B<main>.
For example:

  &GetOptions ("size=i", "sizes=i@");

with command line "-size 10 -sizes 24 -sizes 48" will perform the
equivalent of the assignments

  $opt_size = 10;
  @opt_sizes = (24, 48);

A lone dash B<-> is considered an option, the corresponding Perl
identifier is $opt_ .

The linkage specifier can be a reference to a scalar, a reference to
an array or a reference to a subroutine.

If a REF SCALAR is supplied, the new value is stored in the referenced
variable. If the option occurs more than once, the previous value is
overwritten. 

If a REF ARRAY is supplied, the new value is appended (pushed) to the
referenced array. 

If a REF CODE is supplied, the referenced subroutine is called with
two arguments: the option name and the option value.
The option name is always the true name, not an abbreviation or alias.

=head2 Aliases and abbreviations

The option name may actually be a list of option names, separated by
"|"s, e.g. "foo|bar|blech=s". In this example, "foo" is the true name
of this option. If no linkage is specified, options "foo", "bar" and
"blech" all will set $opt_foo.

Option names may be abbreviated to uniqueness, depending on
configuration variable $Getopt::Long::autoabbrev.

=head2 Non-option call-back routine

A special option specifier, E<lt>E<gt>, can be used to designate a subroutine
to handle non-option arguments. GetOptions will immediately call this
subroutine for every non-option it encounters in the options list.
This subroutine gets the name of the non-option passed.
This feature requires $Getopt::Long::order to have the value $PERMUTE.
See also the examples.

=head2 Option starters

On the command line, options can start with B<-> (traditional), B<-->
(POSIX) and B<+> (GNU, now being phased out). The latter is not
allowed if the environment variable B<POSIXLY_CORRECT> has been
defined.

Options that start with "--" may have an argument appended, separated
with an "=", e.g. "--foo=bar".

=head2 Return value

A return status of 0 (false) indicates that the function detected
one or more errors.

=head1 COMPATIBILITY

Getopt::Long::GetOptions() is the successor of
B<newgetopt.pl> that came with Perl 4. It is fully upward compatible.
In fact, the Perl 5 version of newgetopt.pl is just a wrapper around
the module.

If an "@" sign is appended to the argument specifier, the option is
treated as an array.  Value(s) are not set, but pushed into array
@opt_name. This only applies if no linkage is supplied.

If configuration variable $Getopt::Long::getopt_compat is set to a
non-zero value, options that start with "+" may also include their
arguments, e.g. "+foo=bar". This is for compatiblity with older
implementations of the GNU "getopt" routine.

If the first argument to GetOptions is a string consisting of only
non-alphanumeric characters, it is taken to specify the option starter
characters. Everything starting with one of these characters from the
starter will be considered an option. B<Using a starter argument is
strongly deprecated.>

For convenience, option specifiers may have a leading B<-> or B<-->,
so it is possible to write:

   GetOptions qw(-foo=s --bar=i --ar=s);

=head1 EXAMPLES

If the option specifier is "one:i" (i.e. takes an optional integer
argument), then the following situations are handled:

   -one -two		-> $opt_one = '', -two is next option
   -one -2		-> $opt_one = -2

Also, assume specifiers "foo=s" and "bar:s" :

   -bar -xxx		-> $opt_bar = '', '-xxx' is next option
   -foo -bar		-> $opt_foo = '-bar'
   -foo --		-> $opt_foo = '--'

In GNU or POSIX format, option names and values can be combined:

   +foo=blech		-> $opt_foo = 'blech'
   --bar=		-> $opt_bar = ''
   --bar=--		-> $opt_bar = '--'

Example of using variable references:

   $ret = &GetOptions ('foo=s', \$foo, 'bar=i', 'ar=s', \@ar);

With command line options "-foo blech -bar 24 -ar xx -ar yy" 
this will result in:

   $foo = 'blech'
   $opt_bar = 24
   @ar = ('xx','yy')

Example of using the E<lt>E<gt> option specifier:

   @ARGV = qw(-foo 1 bar -foo 2 blech);
   &GetOptions("foo=i", \$myfoo, "<>", \&mysub);

Results:

   &mysub("bar") will be called (with $myfoo being 1)
   &mysub("blech") will be called (with $myfoo being 2)

Compare this with:

   @ARGV = qw(-foo 1 bar -foo 2 blech);
   &GetOptions("foo=i", \$myfoo);

This will leave the non-options in @ARGV:

   $myfoo -> 2
   @ARGV -> qw(bar blech)

=head1 CONFIGURATION VARIABLES

The following variables can be set to change the default behaviour of
GetOptions():

=over 12

=item $Getopt::Long::autoabbrev      

Allow option names to be abbreviated to uniqueness.
Default is 1 unless environment variable
POSIXLY_CORRECT has been set.

=item $Getopt::Long::getopt_compat   

Allow '+' to start options.
Default is 1 unless environment variable
POSIXLY_CORRECT has been set.

=item $Getopt::Long::order           

Whether non-options are allowed to be mixed with
options.
Default is $REQUIRE_ORDER if environment variable
POSIXLY_CORRECT has been set, $PERMUTE otherwise.

$PERMUTE means that 

    -foo arg1 -bar arg2 arg3

is equivalent to

    -foo -bar arg1 arg2 arg3

If a non-option call-back routine is specified, @ARGV will always be
empty upon succesful return of GetOptions since all options have been
processed, except when B<--> is used:

    -foo arg1 -bar arg2 -- arg3

will call the call-back routine for arg1 and arg2, and terminate
leaving arg2 in @ARGV.

If $Getopt::Long::order is $REQUIRE_ORDER, options processing
terminates when the first non-option is encountered.

    -foo arg1 -bar arg2 arg3

is equivalent to

    -foo -- arg1 -bar arg2 arg3

$RETURN_IN_ORDER is not supported by GetOptions().

=item $Getopt::Long::bundling

Setting this variable to a non-zero value will allow single-character
options to be bundled. To distinguish bundles from long option names,
long options must be introduced with B<--> and single-character
options (and bundles) with B<->. For example,

    ps -vax --vax

would be equivalent to

    ps -v -a -x --vax

provided "vax", "v", "a" and "x" have been defined to be valid
options. 

Bundled options can also include a value in the bundle; this value has
to be the last part of the bundle, e.g.

    scale -h24 -w80

is equivalent to

    scale -h 24 -w 80

B<Note:> Using option bundling can easily lead to unexpected results,
especially when mixing long options and bundles. Caveat emptor.

=item $Getopt::Long::ignorecase

Ignore case when matching options. Default is 1. When bundling is in
effect, case is ignored on single-character options only if
$Getopt::Long::ignorecase is greater than 1.

=item $Getopt::Long::VERSION

The version number of this Getopt::Long implementation in the format
C<major>.C<minor>. This can be used to have Exporter check the
version, e.g.

    use Getopt::Long 2.00;

You can inspect $Getopt::Long::major_version and
$Getopt::Long::minor_version for the individual components.

=item $Getopt::Long::error

Internal error flag. May be incremented from a call-back routine to
cause options parsing to fail.

=item $Getopt::Long::debug           

Enable copious debugging output. Default is 0.

=back

=cut

################ Introduction ################
#
# This program is Copyright 1990,1996 by Johan Vromans.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# If you do not have a copy of the GNU General Public License write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
# MA 02139, USA.

################ Configuration Section ################

# Values for $order. See GNU getopt.c for details.
($REQUIRE_ORDER, $PERMUTE, $RETURN_IN_ORDER) = (0..2);

my $gen_prefix;			# generic prefix (option starters)

# Handle POSIX compliancy.
if ( defined $ENV{"POSIXLY_CORRECT"} ) {
    $gen_prefix = "--|-";
    $autoabbrev = 0;		# no automatic abbrev of options
    $bundling = 0;		# no bundling of single letter switches
    $getopt_compat = 0;		# disallow '+' to start options
    $order = $REQUIRE_ORDER;
}
else {
    $gen_prefix = "--|-|\\+";
    $autoabbrev = 1;		# automatic abbrev of options
    $bundling = 0;		# bundling off by default
    $getopt_compat = 1;		# allow '+' to start options
    $order = $PERMUTE;
}

# Other configurable settings.
$debug = 0;			# for debugging
$error = 0;			# error tally
$ignorecase = 1;		# ignore case when matching options
($major_version, $minor_version) = $VERSION =~ /^(\d+)\.(\d+)/;

################ Subroutines ################

sub GetOptions {

    my @optionlist = @_;	# local copy of the option descriptions
    my $argend = '--';		# option list terminator
    my %opctl;			# table of arg.specs (long and abbrevs)
    my %bopctl;			# table of arg.specs (bundles)
    my $pkg = (caller)[0];	# current context
				# Needed if linkage is omitted.
    my %aliases;		# alias table
    my @ret = ();		# accum for non-options
    my %linkage;		# linkage
    my $userlinkage;		# user supplied HASH
    my $genprefix = $gen_prefix; # so we can call the same module more 
				# than once in differing environments
    $error = 0;

    print STDERR ('GetOptions $Revision: 2.3 $ ',
		  "[GetOpt::Long $Getopt::Long::VERSION] -- ",
		  "called from package \"$pkg\".\n",
		  "  autoabbrev=$autoabbrev".
		  ",bundling=$bundling",
		  ",getopt_compat=$getopt_compat",
		  ",genprefix=\"$genprefix\"",
		  ",order=$order",
		  ",ignorecase=$ignorecase",
		  ".\n")
	if $debug;

    # Check for ref HASH as first argument. 
    $userlinkage = undef;
    if ( ref($optionlist[0]) && ref($optionlist[0]) eq 'HASH' ) {
	$userlinkage = shift (@optionlist);
    }

    # See if the first element of the optionlist contains option
    # starter characters.
    if ( $optionlist[0] =~ /^\W+$/ ) {
	$genprefix = shift (@optionlist);
	# Turn into regexp.
	$genprefix =~ s/(\W)/\\$1/g;
	$genprefix = "[" . $genprefix . "]";
    }

    # Verify correctness of optionlist.
    %opctl = ();
    %bopctl = ();
    while ( @optionlist > 0 ) {
	my $opt = shift (@optionlist);

	# Strip leading prefix so people can specify "-foo=i" if they like.
	$opt = $2 if $opt =~ /^($genprefix)+([\x00-\xff]*)/;

	if ( $opt eq '<>' ) {
	    if ( (defined $userlinkage)
		&& !(@optionlist > 0 && ref($optionlist[0]))
		&& (exists $userlinkage->{$opt})
		&& ref($userlinkage->{$opt}) ) {
		unshift (@optionlist, $userlinkage->{$opt});
	    }
	    unless ( @optionlist > 0 
		    && ref($optionlist[0]) && ref($optionlist[0]) eq 'CODE' ) {
		warn ("Option spec <> requires a reference to a subroutine\n");
		$error++;
		next;
	    }
	    $linkage{'<>'} = shift (@optionlist);
	    next;
	}

	if ( $opt !~ /^(\w+[-\w|]*)?(!|[=:][infse]@?)?$/ ) {
	    warn ("Error in option spec: \"", $opt, "\"\n");
	    $error++;
	    next;
	}
	my ($o, $c, $a) = ($1, $2);
	$c = '' unless defined $c;

	if ( ! defined $o ) {
	    # empty -> '-' option
	    $opctl{$o = ''} = $c;
	}
	else {
	    # Handle alias names
	    my @o =  split (/\|/, $o);
	    $o = $o[0];
	    $o = lc ($o)
		if $ignorecase > 1 
		    || ($ignorecase
			&& ($bundling ? length($o) > 1  : 1));

	    foreach ( @o ) {
		if ( $bundling && length($_) == 1 ) {
		    $_ = lc ($_) if $ignorecase > 1;
		    if ( $c eq '!' ) {
			$opctl{"no$_"} = $c;
			warn ("Ignoring '!' modifier for short option $_\n");
			$c = '';
		    }
		    $bopctl{$_} = $c;
		}
		else {
		    $_ = lc ($_) if $ignorecase;
		    if ( $c eq '!' ) {
			$opctl{"no$_"} = $c;
			$c = '';
		    }
		    $opctl{$_} = $c;
		}
		if ( defined $a ) {
		    # Note alias.
		    $aliases{$_} = $a;
		}
		else {
		    # Set primary name.
		    $a = $_;
		}
	    }
	}

	# If no linkage is supplied in the @optionlist, copy it from
	# the userlinkage if available.
	if ( defined $userlinkage ) {
	    unless ( @optionlist > 0 && ref($optionlist[0]) ) {
		if ( exists $userlinkage->{$o} && ref($userlinkage->{$o}) ) {
		    print STDERR ("=> found userlinkage for \"$o\": ",
				  "$userlinkage->{$o}\n")
			if $debug;
		    unshift (@optionlist, $userlinkage->{$o});
		}
		else {
		    # Do nothing. Being undefined will be handled later.
		    next;
		}
	    }
	}

	# Copy the linkage. If omitted, link to global variable.
	if ( @optionlist > 0 && ref($optionlist[0]) ) {
	    print STDERR ("=> link \"$o\" to $optionlist[0]\n")
		if $debug;
	    if ( ref($optionlist[0]) =~ /^(SCALAR|ARRAY|CODE)$/ ) {
		$linkage{$o} = shift (@optionlist);
	    }
	    else {
		warn ("Invalid option linkage for \"", $opt, "\"\n");
		$error++;
	    }
	}
	else {
	    # Link to global $opt_XXX variable.
	    # Make sure a valid perl identifier results.
	    my $ov = $o;
	    $ov =~ s/\W/_/g;
	    if ( defined($c) && $c =~ /@/ ) {
		print STDERR ("=> link \"$o\" to \@$pkg","::opt_$ov\n")
		    if $debug;
		eval ("\$linkage{\$o} = \\\@".$pkg."::opt_$ov;");
	    }
	    else {
		print STDERR ("=> link \"$o\" to \$$pkg","::opt_$ov\n")
		    if $debug;
		eval ("\$linkage{\$o} = \\\$".$pkg."::opt_$ov;");
	    }
	}
    }

    # Bail out if errors found.
    return 0 if $error;

    # Sort the possible long option names.
    my @opctl = sort(keys (%opctl)) if $autoabbrev;

    # Show the options tables if debugging.
    if ( $debug ) {
	my ($arrow, $k, $v);
	$arrow = "=> ";
	while ( ($k,$v) = each(%opctl) ) {
	    print STDERR ($arrow, "\$opctl{\"$k\"} = \"$v\"\n");
	    $arrow = "   ";
	}
	$arrow = "=> ";
	while ( ($k,$v) = each(%bopctl) ) {
	    print STDERR ($arrow, "\$bopctl{\"$k\"} = \"$v\"\n");
	    $arrow = "   ";
	}
    }

    my $opt;			# current option
    my $arg;			# current option value, if any
    my $array;			# current option is array typed

    # Process argument list
    while ( @ARGV > 0 ) {

	# >>> See also the continue block <<<

	#### Get next argument ####

	my $starter;		# option starter string, e.g. '-' or '--'
	my $rest = undef;	# remainder from unbundling
	my $optarg = undef;	# value supplied with --opt=value

	$opt = shift (@ARGV);
	$arg = undef;
	$array = 0;
	print STDERR ("=> option \"", $opt, "\"\n") if $debug;

	#### Determine what we have ####

	# Double dash is option list terminator.
	if ( $opt eq $argend ) {
	    # Finish. Push back accumulated arguments and return.
	    unshift (@ARGV, @ret) 
		if $order == $PERMUTE;
	    return ($error == 0);
	}

	if ( $opt =~ /^($genprefix)([\x00-\xff]*)/ ) {
	    # Looks like an option.
	    $opt = $2;		# option name (w/o prefix)
	    $starter = $1;	# option starter

	    # If it is a long option, it may include the value.
	    if (($starter eq "--" 
		 || ($getopt_compat && $starter eq "+"))
		&& $opt =~ /^([^=]+)=([\x00-\xff]*)/ ) {
		$opt = $1;
		$optarg = $2;
		print STDERR ("=> option \"", $opt, 
			      "\", optarg = \"$optarg\"\n") if $debug;
	    }

	}

	# Not an option. Save it if we $PERMUTE and don't have a <>.
	elsif ( $order == $PERMUTE ) {
	    # Try non-options call-back.
	    my $cb;
	    if ( (defined ($cb = $linkage{'<>'})) ) {
		&$cb($opt);
	    }
	    else {
		print STDERR ("=> saving \"$opt\" ",
			      "(not an option, may permute)\n") if $debug;
		push (@ret, $opt);
	    }
	    next;
	}

	# ...otherwise, terminate.
	else {
	    # Push this one back and exit.
	    unshift (@ARGV, $opt);
	    return ($error == 0);
	}

	#### Look it up ###

	my $tryopt = $opt;	# option to try
	my $optbl = \%opctl;	# table to look it up (long names)

	if ( $bundling && $starter eq '-' ) {
	    # Unbundle single letter option.
	    $rest = substr ($tryopt, 1);
	    $tryopt = substr ($tryopt, 0, 1);
	    $tryopt = lc ($tryopt) if $ignorecase > 1;
	    print STDERR ("=> $starter$tryopt unbundled from ",
			  "$starter$tryopt$rest\n") if $debug;
	    $rest = undef unless $rest ne '';
	    $optbl = \%bopctl;	# look it up in the short names table
	} 

	# Try auto-abbreviation.
	elsif ( $autoabbrev ) {
	    # Downcase if allowed.
	    $tryopt = $opt = lc ($opt) if $ignorecase;
	    # Turn option name into pattern.
	    my $pat = quotemeta ($opt);
	    # Look up in option names.
	    my @hits = grep (/^$pat/, @opctl);
	    print STDERR ("=> ", scalar(@hits), " hits (@hits) with \"$pat\" ",
			  "out of ", scalar(@opctl), "\n") if $debug;

	    # Check for ambiguous results.
	    unless ( (@hits <= 1) || (grep ($_ eq $opt, @hits) == 1) ) {
		print STDERR ("Option ", $opt, " is ambiguous (",
			      join(", ", @hits), ")\n");
		$error++;
		next;
	    }

	    # Complete the option name, if appropriate.
	    if ( @hits == 1 && $hits[0] ne $opt ) {
		$tryopt = $hits[0];
		print STDERR ("=> option \"$opt\" -> \"$tryopt\"\n")
		    if $debug;
	    }
	}

	# Check validity by fetching the info.
	my $type = $optbl->{$tryopt};
	unless  ( defined $type ) {
	    warn ("Unknown option: ", $opt, "\n");
	    $error++;
	    next;
	}
	# Apparently valid.
	$opt = $tryopt;
	print STDERR ("=> found \"$type\" for ", $opt, "\n") if $debug;

	#### Determine argument status ####

	# If it is an option w/o argument, we're almost finished with it.
	if ( $type eq '' || $type eq '!' ) {
	    if ( defined $optarg ) {
		print STDERR ("Option ", $opt, " does not take an argument\n");
		$error++;
	    }
	    elsif ( $type eq '' ) {
		$arg = 1;		# supply explicit value
	    }
	    else {
		substr ($opt, 0, 2) = ''; # strip NO prefix
		$arg = 0;		# supply explicit value
	    }
	    # When unbundling, unshift the rest with the starter.
	    unshift (@ARGV, $starter.$rest) if defined $rest;
	    next;
	}

	# Get mandatory status and type info.
	my $mand;
	($mand, $type, $array) = $type =~ /^(.)(.)(@?)$/;

	# Check if there is an option argument available.
	if ( defined $optarg ? ($optarg eq '') 
	     : !(defined $rest || @ARGV > 0) ) {
	    # Complain if this option needs an argument.
	    if ( $mand eq "=" ) {
		print STDERR ("Option ", $opt, " requires an argument\n");
		$error++;
	    }
	    if ( $mand eq ":" ) {
		$arg = $type eq "s" ? '' : 0;
	    }
	    next;
	}

	# Get (possibly optional) argument.
	$arg = (defined $rest ? $rest
		: (defined $optarg ? $optarg : shift (@ARGV)));

	#### Check if the argument is valid for this option ####

	if ( $type eq "s" ) {	# string
	    # A mandatory string takes anything. 
	    next if $mand eq "=";

	    # An optional string takes almost anything. 
	    next if defined $optarg || defined $rest;
	    next if $arg eq "-"; # ??

	    # Check for option or option list terminator.
	    if ($arg eq $argend ||
		$arg =~ /^$genprefix.+/) {
		# Push back.
		unshift (@ARGV, $arg);
		# Supply empty value.
		$arg = '';
	    }
	    next;
	}

	if ( $type eq "n" || $type eq "i" ) { # numeric/integer
	    if ( $arg !~ /^-?[0-9]+$/ ) {
		if ( defined $optarg || $mand eq "=" ) {
		    print STDERR ("Value \"", $arg, "\" invalid for option ",
				  $opt, " (number expected)\n");
		    $error++;
		    undef $arg;	# don't assign it
		    # Push back.
		    unshift (@ARGV, $starter.$rest) if defined $rest;
		}
		else {
		    # Push back.
		    unshift (@ARGV, defined $rest ? $starter.$rest : $arg);
		    # Supply default value.
		    $arg = 0;
		}
	    }
	    next;
	}

	if ( $type eq "f" ) { # fixed real number, int is also ok
	    if ( $arg !~ /^-?[0-9.]+$/ ) {
		if ( defined $optarg || $mand eq "=" ) {
		    print STDERR ("Value \"", $arg, "\" invalid for option ",
				  $opt, " (real number expected)\n");
		    $error++;
		    undef $arg;	# don't assign it
		    # Push back.
		    unshift (@ARGV, $starter.$rest) if defined $rest;
		}
		else {
		    # Push back.
		    unshift (@ARGV, defined $rest ? $starter.$rest : $arg);
		    # Supply default value.
		    $arg = 0.0;
		}
	    }
	    next;
	}

	die ("GetOpt::Long internal error (Can't happen)\n");
    }

    continue {
	if ( defined $arg ) {
	    $opt = $aliases{$opt} if defined $aliases{$opt};

	    if ( defined $linkage{$opt} ) {
		print STDERR ("=> ref(\$L{$opt}) -> ",
			      ref($linkage{$opt}), "\n") if $debug;

		if ( ref($linkage{$opt}) eq 'SCALAR' ) {
		    print STDERR ("=> \$\$L{$opt} = \"$arg\"\n") if $debug;
		    ${$linkage{$opt}} = $arg;
		}
		elsif ( ref($linkage{$opt}) eq 'ARRAY' ) {
		    print STDERR ("=> push(\@{\$L{$opt}, \"$arg\")\n")
			if $debug;
		    push (@{$linkage{$opt}}, $arg);
		}
		elsif ( ref($linkage{$opt}) eq 'CODE' ) {
		    print STDERR ("=> &L{$opt}(\"$opt\", \"$arg\")\n")
			if $debug;
		    &{$linkage{$opt}}($opt, $arg);
		}
		else {
		    print STDERR ("Invalid REF type \"", ref($linkage{$opt}),
				  "\" in linkage\n");
		    die ("Getopt::Long -- internal error!\n");
		}
	    }
	    # No entry in linkage means entry in userlinkage.
	    elsif ( $array ) {
		if ( defined $userlinkage->{$opt} ) {
		    print STDERR ("=> push(\@{\$L{$opt}}, \"$arg\")\n")
			if $debug;
		    push (@{$userlinkage->{$opt}}, $arg);
		}
		else {
		    print STDERR ("=>\$L{$opt} = [\"$arg\"]\n")
			if $debug;
		    $userlinkage->{$opt} = [$arg];
		}
	    }
	    else {
		print STDERR ("=>\$L{$opt} = \"$arg\"\n") if $debug;
		$userlinkage->{$opt} = $arg;
	    }
	}
    }

    # Finish.
    if ( $order == $PERMUTE ) {
	#  Push back accumulated arguments
	print STDERR ("=> restoring \"", join('" "', @ret), "\"\n")
	    if $debug && @ret > 0;
	unshift (@ARGV, @ret) if @ret > 0;
    }

    return ($error == 0);
}

################ Package return ################

1;
