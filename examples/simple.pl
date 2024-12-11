#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use Try::Tiny;
use Safe::Isa;

use BuyLibs::MDB qw(-compat);

# Register if you have full-feature license key
# BuyLibs::MDB::registration('BuyLibs::MDB Linux. Licensed to ORGANIZATION NAME. N Developer(s) Only.', '0123456789ABCDEF0123456789ABCDEF...');

my $client = MongoDB->connect($ENV{MONGOD} || 'mongodb://localhost');
my $db     = $client->get_database('test_db_for_mdb');

my $collection = $db->get_collection('sample');
$collection->drop;

# Create a unique index on the 'name' field and insert multiple documents
$collection->indexes->create_one({ name => 1 }, { unique => 1 });

my @docs = (
    { name => 'Example1', type => 'Normal' },
    { name => 'Example2', type => 'Normal' },
    { name => 'Example3', type => 'Normal' },
);

for my $doc (@docs) {
    $collection->insert_one($doc);
    print "Inserted document with name: $doc->{name}\n";
}

# Insert a document with a duplicate name to trigger the error
try {
    $collection->insert_one({ name => 'Example1', type => 'DuplicateTest' });
} catch {
    if ($_->$_isa('MongoDB::DuplicateKeyError')) {
        if (   $_->code == 11000
            && $_->message =~ /E11000 duplicate key error collection:/
            && $_->message =~ /test_db_for_mdb.sample index: name_1 dup key/
            && $_->result->$_isa('BuyLibs::MDB::InsertOneResult')
            && !defined $_->result->inserted_id
            && $_->result->write_errors->[0]->{code} == 11000
            && $_->result->write_errors->[0]->{keyPattern}{name} == 1
            && $_->result->write_errors->[0]->{keyValue}{name} eq 'Example1')
        {
            print "Duplicate key error (as expected): 'name' already exists.\n";
        } else {
            print "Unexpected duplicate key: ", Dumper($_), "\n";
        }
    } else {
        die "Error inserting document: $@";
    }
};

# Find documents and iterate using a cursor
my $cursor = $collection->find();
while (my $doc = $cursor->next) {
    print "Found document: name = $doc->{name}, type = $doc->{type}\n";
}

$db->drop;
