#!/usr/bin/env perl
use strict;
use warnings;
use Mojo::Base -strict;
use Mojo::Base -async_await;

use BuyLibs::MDB qw(-compat);

my $uri = $ENV{MONGOD} || 'mongodb://localhost:27017';

print "Connecting to MongoDB server at '$uri'...\n";
my $conn = MongoDB->mojo_connect($uri);

$conn->pool->max_size(50);

my $db_name = 'test_db_name_' . int(rand(2**31));
my $db      = $conn->get_database($db_name);
my $coll    = $db->get_collection('test_collection');

printf "\nInserting 10 documents into collection '%s'...\n", $coll->name;
for my $i (0 .. 9) {
    my $doc = { x => $i, y => $i * 2 };
    my $res = await $coll->insert_one($doc);
    printf "\tDocument inserted with ID: %s\n", $res->inserted_id;
}

printf "\nIterating over documents in collection '%s'...\n", $coll->name;
my $cursor = $coll->find;
while (my $doc = await $cursor->next) {
    printf("\tDocument ID: %-24s | x: %-3d | y: %-3d\n",
        $doc->{_id}, $doc->{x}, $doc->{y});
}

print "\nFinding and sorting documents by 'y' in descending order...\n";
my @docs = await $coll->find->sort({ y => -1 })->all;
printf "\tFound %d documents sorted by 'y'.\n", scalar @docs;

print "\nFinding documents with projection (only 'y' field)...\n";
my $cursor_proj = $coll->find({}, { projection => { y => 1, _id => 0 } });
while (my $doc = await $cursor_proj->next) {
    printf "\tDocument with y = %-3d\n", $doc->{y};
}

print "\nRetrieving a specific document using sort, skip, and limit...\n";
my $cursor_pag = $coll->find->sort({ y => 1 })->skip(1)->limit(1)
    ->fields({ y => 1, _id => 0 });

my @result = await $cursor_pag->all;
if (@result) {
    printf "\tFound 1 document after skipping 1; y = %-3d\n", $result[0]{y};
} else {
    print "\tNo documents found matching the criteria.\n";
}

# Cleanup: Drop the database when done
END {
    eval {
        if ($db) {

            # `await` is available in `async sub { ... }`.
            # END is not async. Use promise instead.
            my $promise = $db->drop;
            $promise->wait;
        }
        print "\nDatabase '$db_name' has been dropped successfully.\n";
        1;
    } or do {
        warn "ERROR: Failed to drop database '$db_name': $@\n";
    }
}
