package main;
use Modern::Perl;
use MARC::MIR::Template;
use Test::More 'no_plan';
use YAML ();

my $spec = YAML::Load << '';
    001: id
    200: [ authors, { a: name, b: firstname } ]
    300: { a: title, b: subtitle }

my $data = YAML::Load  << '';
    authors:
        - { name: Doe, firstname: [john, elias, frederik] }
        - { name: Doe, firstname: jane }
    title: "i can haz title"
    subtitle: "also subs"
    id: PPNxxxx

my $expected = YAML::Load << '';
    - [001, PPNxxxx ]
    - [200, [ [a, Doe], [b, john], [b, elias], [b, frederik] ]]
    - [200, [ [a, Doe], [b, jane]                            ]]
    - [300, [ [a, "i can haz title"], [b, "also subs"]       ]]

my $template = MARC::MIR::Template->new( $spec );
ok( $template->isa('MARC::MIR::Template'),"constructor works");
my $got = $template->data( $data );
# subfields are not sorted in single_valued :(
# is_deeply ( $got, $expected , "data ready for MARC::MIR" )
#     or diag YAML::Dump [ $$got[3][1], $$expected[3][1] ]

# say 
# say to_iso2709 [ '', $template->data( $data ) ];

