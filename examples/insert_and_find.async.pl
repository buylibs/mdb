#!/usr/bin/env perl
use strict;
use warnings;
use AnyEvent;

use BuyLibs::MDB qw(-compat);

my $uri = $ENV{MONGOD} || 'mongodb://localhost:27017';

print "Connecting to MongoDB server at '$uri'...\n";
my $conn = MongoDB->async_connect($uri);

$conn->pool->max_size(50);

my $db_name = 'test_db_name_' . int(rand(2**31));
my $db      = $conn->get_database($db_name);
my $coll    = $db->get_collection('test_collection');
my @join;

my $cv = AE::cv;
$cv->begin;
printf "\nInserting 10 documents into collection '%s'...\n", $coll->name;
for my $i (0 .. 9) {
    my $doc = { x => $i, y => $i * 2 };
    $cv->begin;
    $coll->insert_one(
        $doc,
        sub {
            my ($res) = @_;
            printf "\tDocument inserted with ID: %s\n", $res->inserted_id;
            $cv->end;
        }
    );
}

$cv->end;
$cv->recv;

$cv = AE::cv;
printf "\nIterating over documents in collection '%s'...\n", $coll->name;
my $cursor = $coll->find;
my $cb_next;
$cb_next = sub {
    my ($doc) = @_;
    $cv->send, return unless $doc;
    printf("\tDocument ID: %-24s | x: %-3d | y: %-3d\n",
        $doc->{_id}, $doc->{x}, $doc->{y});
    $cursor->next($cb_next);
};
$cursor->next($cb_next);
$cv->recv;

$cv = AE::cv;
print "\nFinding and sorting documents by 'y' in descending order...\n";
$coll->find->sort({ y => -1 })->all(
    sub {
        $cv->send(@_);
    }
);
my @docs = $cv->recv;
printf "\tFound %d documents sorted by 'y'.\n", scalar @docs;

$cv = AE::cv;
print "\nFinding documents with projection (only 'y' field)...\n";
my $cursor_proj = $coll->find({}, { projection => { y => 1, _id => 0 } });
$cb_next = sub {
    my ($doc) = @_;
    $cv->send, return unless $doc;
    printf "\tDocument with y = %-3d\n", $doc->{y};
    $cursor_proj->next($cb_next);
};
$cursor_proj->next($cb_next);
$cv->recv;

$cv = AE::cv;
print "\nRetrieving a specific document using sort, skip, and limit...\n";
my $cursor_pag = $coll->find->sort({ y => 1 })->skip(1)->limit(1)
    ->fields({ y => 1, _id => 0 });

$cursor_pag->all(
    sub {
        my @result = @_;
        if (@result) {
            printf "\tFound 1 document after skipping 1; y = %-3d\n",
                $result[0]{y};
        } else {
            print "\tNo documents found matching the criteria.\n";
        }
        $cv->send;
    }
);
$cv->recv;

# Cleanup: Drop the database when done
END {
    if ($db) {
        $db->drop(
            sub {
                if (length $@) {
                    warn "ERROR: Failed to drop database '$db_name': $@\n";
                } else {
                    print
                        "\nDatabase '$db_name' has been dropped successfully.\n";
                }
            }
        );
    }
}