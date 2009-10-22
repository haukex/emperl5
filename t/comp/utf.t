#!./perl -w

print "1..76\n";
my $test = 0;

my %templates = (
		 utf8 => 'C0U',
		 utf16be => 'n',
		 utf16le => 'v',
		);

sub bytes_to_utf {
    my ($enc, $content, $do_bom) = @_;
    my $template = $templates{$enc};
    die "Unsupported encoding $enc" unless $template;
    return pack "$template*", ($do_bom ? 0xFEFF : ()), unpack "U*", $content;
}

sub test {
    my ($enc, $write, $expect, $bom, $nl, $name) = @_;
    open my $fh, ">", "utf$$.pl" or die "utf.pl: $!";
    binmode $fh;
    print $fh bytes_to_utf($enc, $write . ($nl ? "\n" : ''), $bom);
    close $fh or die $!;
    my $got = do "./utf$$.pl";
    $test = $test + 1;
    if (!defined $got) {
	print "not ok $test # $enc $bom $nl $name; got undef\n";
    } elsif ($got ne $expect) {
	print "not ok $test # $enc $bom $nl $name; got '$got'\n";
    } else {
	print "ok $test # $enc $bom $nl $name\n";
    }
}

for my $bom (0, 1) {
    for my $enc (qw(utf16le utf16be utf8)) {
	for my $nl (1, 0) {
	    for my $value (123, 1234, 12345) {
		test($enc, $value, $value, $bom, $nl, $value);
	    }
	    next if $enc eq 'utf8';
	    # Arguably a bug that currently string literals from UTF-8 file
	    # handles are not implicitly "use utf8", but don't FIXME that
	    # right now, as here we're testing the input filter itself.

	    for my $expect ("N", "\xFF", "\x{100}", "\x{010a}", "\x{0a23}",
			   ) {
		# A space so that the UTF-16 heuristc triggers - " '" gives two
		# characters of ASCII.
		my $write = " '$expect'";
		my $name = 'chrs ' . join ', ', map {ord $_} split '', $expect;
		test($enc, $write, $expect, $bom, $nl, $name);
	    }
	}
    }
}

END {
    1 while unlink "utf$$.pl";
}
