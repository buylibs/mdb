#!/usr/bin/env perl
use strict;
use warnings;
use BuyLibs::MDB qw(-compat);

my $info = BuyLibs::MDB::info;

print "$_ = $info->{$_}\n" for sort keys %$info;
