package Mojolicious::Plugin::AssetPack::Preprocessor::Sass;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AssetPack::Preprocessor::Sass - Preprocessor for sass

=head1 DESCRIPTION

L<Mojolicious::Plugin::AssetPack::Preprocessor::Sass> is a preprocessor for
C<.sass> files.

Sass makes CSS fun again. Sass is an extension of CSS3, adding nested rules,
variables, mixins, selector inheritance, and more. See L<http://sass-lang.com>
for more information. Supports both F<*.scss> and F<*.sass> syntax variants.

You need either the "sass" executable or the cpan module L<CSS::Sass> to make
this module work:

  $ sudo apt-get install rubygems
  $ sudo gem install sass

  ...

  $ sudo cpanm CSS::Sass

=cut

use Mojo::Base 'Mojolicious::Plugin::AssetPack::Preprocessor::Scss';
use File::Basename 'dirname';
use constant LIBSASS_BINDINGS => defined $ENV{ENABLE_LIBSASS_BINDINGS}
  ? $ENV{ENABLE_LIBSASS_BINDINGS}
  : eval 'require CSS::Sass;1';

sub _extension {'sass'}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
