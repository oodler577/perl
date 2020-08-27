#!./perl
#
# Tests for Perl run-time environment variable settings
#
# $PERL5OPT, $PERL5LIB, etc.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
    require Config; Config->import;
    skip_all_without_config('d_fork');
}

plan tests =>   6;

my $STDOUT = tempfile();
my $STDERR = tempfile();
my $PERL = './perl';
my $FAILURE_CODE = 119;

delete $ENV{PERLLIB};
delete $ENV{PERL5LIB};
delete $ENV{PERL5OPT};
delete $ENV{PERL_USE_UNSAFE_INC};


# Run perl with specified environment and arguments, return (STDOUT, STDERR)
sub runperl_and_capture {
  local *F;
  my ($env, $args) = @_;

  local %ENV = %ENV;
  delete $ENV{PERLLIB};
  delete $ENV{PERL5LIB};
  delete $ENV{PERL5OPT};
  delete $ENV{PERL_USE_UNSAFE_INC};
  my $pid = fork;
  return (0, "Couldn't fork: $!") unless defined $pid;   # failure
  if ($pid) {                   # parent
    wait;
    return (0, "Failure in child.\n") if ($?>>8) == $FAILURE_CODE;

    open my $stdout, '<', $STDOUT
	or return (0, "Couldn't read $STDOUT file: $!");
    open my $stderr, '<', $STDERR
	or return (0, "Couldn't read $STDERR file: $!");
    local $/;
    # Empty file with <$stderr> returns nothing in list context
    # (because there are no lines) Use scalar to force it to ''
    return (scalar <$stdout>, scalar <$stderr>);
  } else {                      # child
    for my $k (keys %$env) {
      $ENV{$k} = $env->{$k};
    }
    open STDOUT, '>', $STDOUT or exit $FAILURE_CODE;
    open STDERR, '>', $STDERR and do { exec $PERL, @$args };
    # it did not work:
    print STDOUT "IWHCWJIHCI\cNHJWCJQWKJQJWCQW\n";
    exit $FAILURE_CODE;
  }
}

SKIP:
{
    #skip "NO_PERL_HASH_ENV or NO_PERL_HASH_SEED_DEBUG set", 16
    skip "NO_PERL_HASH_ENV or NO_PERL_HASH_SEED_DEBUG set",  6
      if $Config{ccflags} =~ /-DNO_PERL_HASH_ENV\b/ ||
         $Config{ccflags} =~ /-DNO_PERL_HASH_SEED_DEBUG\b/;

    # Test that PERL_PERTURB_KEYS works as expected.  We check that we get the same
    # results if we use PERL_PERTURB_KEYS = 0 or 2 and we reuse the seed from previous run.
    my @print_keys = ( '-e', 'my %h; @h{"A".."Z"}=(); print keys %h');
    for my $mode ( qw{NO RANDOM DETERMINISTIC} ) { # 0, 1 and 2 respectively
        my %base_opts;
        %base_opts = ( PERL_PERTURB_KEYS => $mode, PERL_HASH_SEED_DEBUG => 1 ),
          my ($out, $err) = runperl_and_capture( { %base_opts }, [ @print_keys ]);
        if ($err=~/HASH_SEED = (0x[a-f0-9]+)/) {
            my $seed = $1;
            my($out2, $err2) = runperl_and_capture( { %base_opts, PERL_HASH_SEED => $seed }, [ @print_keys ]);
            if ( $mode eq 'RANDOM' ) {
                isnt ($out,$out2,"PERL_PERTURB_KEYS = $mode results in different key order with the same key");
            } else {
                is ($out,$out2,"PERL_PERTURB_KEYS = $mode allows one to recreate a random hash");
            }
            is ($err,$err2,"Got the same debug output when we set PERL_HASH_SEED and PERL_PERTURB_KEYS");
        }
    }
}

