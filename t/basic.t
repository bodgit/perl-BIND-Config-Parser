#! /usr/bin/env perl
#
# $Id$

use strict;
use warnings;

use Test::More qw( no_plan );

BEGIN { use_ok( 'BIND::Config::Parser' ) };	# test 1

my $parser;
eval {
	$parser = BIND::Config::Parser->new();
};

ok( ref $parser eq 'BIND::Config::Parser' );	# test 2
