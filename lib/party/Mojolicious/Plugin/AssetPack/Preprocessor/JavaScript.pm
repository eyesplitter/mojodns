package Mojolicious::Plugin::AssetPack::Preprocessor::JavaScript;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AssetPack::Preprocessor::JavaScript - Preprocessor for JavaScript

=head1 DESCRIPTION

L<Mojolicious::Plugin::AssetPack::Preprocessor::JavaScript> is a preprocessor for
C<.js> files.

JavaScript is minified using L<JavaScript::Minifier::XS>. This module is
optional and must be installed manually.

NOTE! L<JavaScript::Minifier::XS> might be replaced with something better.

=cut

use Mojo::Base 'Mojolicious::Plugin::AssetPack::Preprocessor';
use JavaScript::Minifier::XS;
use constant MINIFIED_LINE_LENGTH => $ENV{JAVASCRIPT_MINIFIED_LINE_LENGTH} || 300;    # might change

my $COMMENT_RE = do {
  my $re = sprintf '^\s*(%s)', join '|', map {quotemeta} qw( /* */ // );
  $re = qr{$re};
  $re;
};

=head1 METHODS

=head2 minify

  $self = $self->minify($text);

Used to minify C<$text>, which is a scalar reference to a chunk of JavaScript
code.

=cut

sub minify {
  my ($self, $text) = @_;

  # Guess if the input text is already minified
  while ($$text =~ /^(.+)$/mg) {
    my $line = $1;
    next if $line =~ $COMMENT_RE;                          # comments /*, */ and //
    return $self if MINIFIED_LINE_LENGTH < length $line;
  }

  $$text = JavaScript::Minifier::XS::minify($$text) if length $$text;
  $self;
}

=head2 process

This method use L<JavaScript::Minifier::XS> to process C<$text>.

See L<Mojolicious::Plugin::AssetPack::Preprocessor/process>.

=cut

sub process {
  my ($self, $assetpack, $text, $path) = @_;

  $self->minify($text) if $assetpack->minify;
  $$text .= "\n" if length $$text and $$text !~ /[\n\r]+$/;

  return $self;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
