package MARC::MIR::Template;
use Modern::Perl;
use YAML ();

# ABSTRACT: templating system for marc records

sub _data_control {
    my $k = shift;
    sub {
        my ( $out, $content ) = @_;
        ref $content and die "trying to load a ref in $k";
        $$out{ $k } = $content;
    }
}

sub _data_data {
    my ( $field, $tag ) = @_;
    sub {
        my ( $out, $content ) = @_;
        push @{ $$out{$field}[0] }, [ $tag, $content ];
    }
}

sub _data_prepare_data {
    my ( $template, $k, $v ) = @_;
    while ( my ( $subk, $subv ) = each %$v ) {
        $$template{data}{ $subv } = _data_data $k, $subk;
    }
}

sub _data_mvalued {
    my ( $k, $rspec ) = @_;
    my %spec = map { $$rspec{$_} => $_  } keys %$rspec;
    sub {
        my ( $out, $v ) = @_;
        push @{ $$out{$k} }
        , map { 
            my $item = $_;
            # TODO: optimize by not sorting every subfield ?
            # (it's 2am, sorry) 
            [ sort { $$a[0] cmp $$b[0] } map {  
                my $tag = $spec{$_} or die;
                map {
                    if ( ref ) {  map [ $tag, $_], @$_ }
                    else { [ $tag, $_ ] }
                } $$item{$_} 
            } keys %$item ]
        } @$v 
    }
}

sub new {
    my ( $pkg, $spec ) = @_;
    my %template;
    while ( my ( $k, $v ) = each %$spec ) {
        given ( ref $v ) {
            when ('')     { $template{data}{ $v } = _data_control $k }
            when ('HASH') { _data_prepare_data \%template, $k, $v }
            when ('ARRAY') {
                my ( $mvalued, $fieldspec ) = @$v;
                $template{data}{ $mvalued } = _data_mvalued $k, $fieldspec;
            }
        }
    }
    bless \%template, __PACKAGE__;
}

sub data {
    my ( $template, $source ) = @_;
    my $out = {};
    while ( my ( $k, $v ) = each %$source ) {
        my $cb = $$template{data}{ $k } or next;
        $cb->( $out, $v );
    }
    [ map {
        my $field = $_;
        my $data = $$out{$field};
        if ( ref $data ) { map { [$field, $_ ] } @$data }
        else { [ $field, $data ] }
      } sort keys %$out ]

}

1;
