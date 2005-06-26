package BIND::Config::Parser;

# $Id$

use warnings;
use strict;

use Parse::RecDescent;

use vars qw( $VERSION );

$VERSION = '0.01';

$::RD_AUTOACTION = q{ $item[1] };

my $grammar = q{

	program:
		  <skip: qr{\s*
		            (?:(?://|\#)[^\n]*\n\s*|/\*(?:[^*]+|\*(?!/))*\*/\s*)*
		           }x> statement(s) eofile { $item[2] }

	statement:
		  simple | nested

	simple:
		  value(s) ';'

	nested:
		  value value(s?) '{' statement(s?) '}' ';'
		  { [ $item[1], $item[2], $item[4] ] }

	value:
		  /[\w.\/=-]+/ | /"[\w.\/ =-]+"/

	eofile:
		  /^\Z/
};

sub new {
	my $class = shift;

	my $self = {
		'_open_block'  => \&_handle_open_block,
		'_close_block' => \&_handle_close_block,
		'_statement'   => \&_handle_statement,
	};

	$self->{ '_parser' } = new Parse::RecDescent( $grammar )
		|| die "Bad grammar\n";

	bless $self, $class;

	return $self;
}

sub parse_conf
{
	my $self = shift;

	my $namedconf = shift || '/etc/named.conf';

	open NAMEDCONF, $namedconf
		|| die "Can't open '$namedconf': $!\n";
	my $text = join( "", <NAMEDCONF> );
	close NAMEDCONF;

	defined( my $tree = $self->{ '_parser' }->program( $text ) )
		|| die "Bad text\n";

	$self->_recurse( $tree );
}

sub open_block_handler
{
	my $self = shift;

	return $self->{ '_open_block' };
}

sub set_open_block_handler
{
	my $self = shift;

	$self->{ '_open_block' } = shift;
}

sub close_block_handler
{
	my $self = shift;

	return $self->{ '_close_block' };
}

sub set_close_block_handler
{
	my $self = shift;

	$self->{ '_close_block' } = shift;
}

sub statement_handler
{
	my $self = shift;

	return $self->{ '_statement' };
}

sub set_statement_handler
{
	my $self = shift;

	$self->{ '_statement' } = shift;
}

sub _recurse
{
	my $self = shift;
	my $tree = shift;

	ref( $tree ) eq 'ARRAY'
		|| die "Rethink!\n";

	foreach my $node ( @{ $tree } ) {
		if ( ref( $node->[-1] ) eq 'ARRAY' ) {

			# If the last child of the node is an array then the
			# node must be a nested statement, so handle the
			# opening line, recurse through the contents and
			# close with the curly brace

			$self->open_block_handler->( $node->[0], @{ $node->[1] } );
			$self->_recurse( $node->[-1] );
			$self->close_block_handler->();
		} else {

			# Normal single-line statement

			$self->statement_handler->( @{ $node } );
		}
	}
}

sub _handle_open_block {}
sub _handle_close_block {}
sub _handle_statement {}

1;

__END__

=head1 NAME

BIND::Config::Parser - Parse BIND Config file

=head1 SYNOPSIS

 use BIND::Config::Parser;

 my $parser = new BIND::Config::Parser;

=head1 DESCRIPTION

This class does something, what exactly, I don't yet know.
