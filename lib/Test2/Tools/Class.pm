package Test2::Tools::Class;
use strict;
use warnings;

our $VERSION = '0.000025';

use Test2::API qw/context/;
use Test2::Util::Ref qw/render_ref/;

use Scalar::Util qw/blessed/;

our @EXPORT = qw/can_ok isa_ok DOES_ok/;
use base 'Exporter';

# For easier grepping
# sub isa_ok  is defined here
# sub can_ok  is defined here
# sub DOES_ok is defined here
BEGIN {
    for my $op (qw/isa can DOES/) {
        my $sub = sub($;@) {
            my ($thing, @items) = @_;
            my $ctx = context();

            my $name = ref($thing) ? render_ref($thing) : defined($thing) ? "$thing" : "<undef>";
            $name =~ s/\n/\\n/g;
            $name =~ s/#//g;
            $name =~ s/\(0x[a-f0-9]+\)//gi;

            unless ($thing && (blessed($thing) || !ref($thing))) {
                my $thing = defined($thing)
                    ? ref($thing) || "'$thing'"
                    : '<undef>';

                $ctx->ok(0, "$name\->$op(...)", ["$thing is neither a blessed reference or a package name."]);

                $ctx->release;
                return 0;
            }

            unless(UNIVERSAL->can($op) || $thing->can($op)) {
                $ctx->skip("$name\->$op(...)", "'$op' is not supported on this platform");
                $ctx->release;
                return 1;
            }

            my $file = $ctx->trace->file;
            my $line = $ctx->trace->line;

            my @bad;
            for my $item (@items) {
                my ($bool, $ok, $err);

                {
                    local ($@, $!);
                    $ok = eval qq/#line $line "$file"\n\$bool = \$thing->$op(\$item); 1/;
                    $err = $@;
                }

                die $err unless $ok;
                next if $bool;

                push @bad => $item;
            }

            $ctx->ok(
                !@bad,
                @items == 1 ? "$name\->$op('$items[0]')" : "$name\->$op(...)",
                [map { "Failed: $name\->$op('$_')" } @bad],
            );

            $ctx->release;

            return !@bad;
        };

        no strict 'refs';
        *{$op . "_ok"} = $sub;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::Class - Test2 implementation of the tools for testing classes.

=head1 DESCRIPTION

L<Test2> based tools for validating classes and objects. These are similar to
some tools from L<Test::More>, but they have a more consistent interface.

=head1 SYNOPSIS

    use Test2::Tools::Class;

    isa_ok($CLASS_OR_INSTANCE, $PARENT_CLASS1, $PARENT_CLASS2, ...);

    can_ok($CLASS_OR_INSTANCE, $METHOD1, $METHOD2, ...);

    DOES_ok($CLASS_OR_INSTANCE, $ROLE1, $ROLE2, ...);

=head1 EXPORTS

All subs are exported by default.

=over 4

=item can_ok($thing, @methods)

This checks that C<$thing> (either a class name, or a blessed instance) has the
specified methods.

=item isa_ok($thing, @classes)

This checks that C<$thing> (either a class name, or a blessed instance) is or
subclasses the specified classes.

=item DOES_ok($thing, @roles)

This checks that C<$thing> (either a class name, or a blessed instance) does
the specified roles.

B<Note 1:> This uses the C<< $class->DOES(...) >> method, not the C<does()>
method Moose provides.

B<Note 2:> Not all perls have the C<DOES()> method, if you use this on those
perls the test will be skipped.

=back

=head1 SOURCE

The source code repository for Test2-Suite can be found at
F<http://github.com/Test-More/Test2-Suite/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
