# BuyLibs::MDB v8.x: BuyLibs Perl Driver for MongoDB®

## Introduction

BuyLibs::MDB is a BuyLibs' Perl driver for MongoDB. This commercially supported
software is made available by BuyLibs Team for interaction with MongoDB
databases using Perl. This driver is designed to provide robust,
high-performance access to MongoDB, enabling you to leverage the power of this
NoSQL database in your Perl applications.

Please note that this driver is not an official MongoDB product.

## Overview

This guide provides instructions on how to integrate and use the MongoDB Perl
Driver. This includes the necessary files, licensing details, examples, and
dependencies.

## Features

- Easy-to-use interface for MongoDB operations, for database up to v8 version.
- High-performance queries and data manipulation.
- Support for MongoDB's latest capabilities.

## Supported platforms

The driver requires Perl v5.16 or later for most Unix-like platforms.

## Configuring and testing

Most tests will be skipped unless a MongoDB database is accessible, either at
the default `localhost:27017` or at a custom `host:port` defined by the `MONGOD`
environment variable.

        $ export MONGOD=localhosts:31017

You can download the free, community edition of MongoDB server from the [MongoDB
Downloads page](https://www.mongodb.com/try/download/community).

To configure, test, and install BuyLibs::MDB:

```bash

# Sample distro
cd BuyLibs-MDB-v7.0.9-perl-v5.30-x86_64-ubuntu-thread-multi-64int

# Install dependencies if not found
cpanm --installdeps --skip-satisfied --verbose .
# --> Working on .
# ...
# <== Installed dependencies for .. Finishing.

# Standard way to test and install
perl Makefile.PL
make
make test
make install

```

## License key registration

To use the functions, you must register your license key in your Perl code.

If you have purchased a full-featured version of BuyLibs::MDB, you should have
received a `Product Name` and `License Key`.

If you don't have a valid license key, BuyLibs::MDB includes a default,
hardcoded trial license key for use with the trial version of the software. This
trial key is the same as the one provided below.

Examples of registration in Perl.

```perl

# ---------------------------------------------------------
# Method 1: Set the key before using BuyLibs::MDB.
# ---------------------------------------------------------

BEGIN {
    $BuyLibs::MDB::PRODUCT_NAME = "BuyLibs::MDB v8.0 Linux Trial ID-266f68b1 for MongoDB Database - Demo (Feature-Limited)";
    $BuyLibs::MDB::LICENSE_KEY  = "9A3248A1B11EB06F8F850D29D37445BB655C27A4FC0778D1EF857CA3B0DDC458F6DCD939E0B53A4790C3E0C48896096351998F1FD0B18657C0945E6FAD3F0403";
}
use BuyLibs::MDB qw(-compat);

# ---------------------------------------------------------
# Method 2: Activate explicitly after `use BuyLibs::MDB`.
# ---------------------------------------------------------

use BuyLibs::MDB qw(-compat);
BuyLibs::MDB::registration('BuyLibs::MDB Linux. Licensed to ORGANIZATION NAME. N Developer(s) Only.', '0123456789ABCDEF0123456789ABCDEF...');

# ---------------------------------------------------------
# Method 3: Activate via environment variables.
# ---------------------------------------------------------

BEGIN {
    $ENV{BUYLIBS_MDB_PRODUCT_NAME} = "BuyLibs::MDB v8.0 Linux Trial ID-266f68b1 for MongoDB Database - Demo (Feature-Limited)";
    $ENV{BUYLIBS_MDB_LICENSE_KEY}  = "9A3248A1B11EB06F8F850D29D37445BB655C27A4FC0778D1EF857CA3B0DDC458F6DCD939E0B53A4790C3E0C48896096351998F1FD0B18657C0945E6FAD3F0403";
}
use BuyLibs::MDB qw(-compat);

```

## Usage

Here's a simple example to get you started:

```perl
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

```

Output:

```
Inserted document with name: Example1
Inserted document with name: Example2
Inserted document with name: Example3
Duplicate key error (as expected): 'name' already exists.
Found document: name = Example1, type = Normal
Found document: name = Example2, type = Normal
Found document: name = Example3, type = Normal
```

## Documentation

The BuyLibs::MDB API structure is designed to align with original MongoDB Perl
driver as closely as possible. Please refer to the [MongoDB
Documentation](https://metacpan.org/pod/MongoDB).

## Examples

Examples are located in the `./examples/` directory of the distribution.

## Version

To check the version of the module and its dependencies, run the following
command:

        $ examples/show_info.pl

        libbson bundled version = 1.28.1
        libmongoc SASL = disabled
        libmongoc SRV = enabled
        libmongoc SSL = enabled
        libmongoc SSL library = OpenSSL
        libmongoc bundled version = 1.28.1
        libmongoc compression = enabled
        libmongoc compression snappy = disabled
        libmongoc compression zlib = enabled
        libmongoc compression zstd = disabled
        libmongoc crypto = enabled
        libmongoc crypto library = libcrypto
        libmongoc crypto system profile = enabled
        libmongocrypt bundled version = 1.12.0
        libmongocrypt crypto = enabled
        libmongocrypt crypto library = libcrypto
        module trial build = enabled
        module version = v8.0.4-trial
        mongodb compatible versions = 8.0, 7.0, 6.0, 5.0, 4.4, 4.2, 4.0
        openssl bundled version = 3.4.0
        openssl bundled version text = OpenSSL 3.4.0 22 Oct 2024
        perl compilation version = 5.30.0
        perl compilation version with use64bitall = enabled
        perl compilation version with use64bitint = enabled
        perl compilation version with uselongdouble = disabled
        perl compilation version with usemultiplicity = enabled
        perl compilation version with usethreads = enabled
        perl execution version = 5.30.0

## License

Use of the BuyLibs Perl Driver for MongoDB (BuyLibs::MDB) is governed by the
BuyLibs End User License Agreement (EULA).

The software is proprietary and not entirely free, as it includes components
derived from open-source licenses that allow for commercial distribution,
thereby clarifying the basis for its proprietary status. For details on these
components and their respective licenses, please consult the NOTICE.md file.

Please note that BuyLibs::MDB is a client-side software designed to connect to
your MongoDB database server(s). BUYLIBS::MDB DOES NOT INCLUDE, DISTRIBUTE,
INSTALL, OR PROVIDE ANY MONGODB SERVER SOFTWARE OR INSTANCE. IT IS YOUR
RESPONSIBILITY TO PREPARE AND LAUNCH YOUR MONGODB SERVER. BUYLIBS::MDB SOLELY
FACILITATES INTERACTIONS WITH YOUR EXISTING DATABASE, WITHOUT MANAGING OR
ADMINISTERING THE DATABASE DIRECTLY: ANY ACTIONS TAKEN WITH BUYLIBS::MDB REQUIRE
EXPLICIT COMMANDS FROM THE DEVELOPER—DEFINED AS A PERSON INVOLVED IN
IMPLEMENTING A PERL SOFTWARE THAT UTILIZES BUYLIBS::MDB, A PERL DRIVER FOR
MONGODB.

**MongoDB Licensing Note**: Users are responsible for complying with the
licensing terms of the MongoDB® server software, as MDB does not include or
address those terms.

## Trial Conditions

If you have obtained a trial version of BuyLibs::MDB, you must comply with the
trial conditions outlined in the [TRIAL_CONDITIONS.md](TRIAL_CONDITIONS.md)
file. These conditions apply to the use of the trial version and may include
limitations on functionality, duration, and other restrictions.

Please ensure that you review both the [LICENSE.md](LICENSE.md) and
[TRIAL_CONDITIONS.md](TRIAL_CONDITIONS.md) files to fully understand your rights
and obligations when using this software.

## Copyright

Copyright © 2024 BuyLibs Team. All rights reserved.

Portions of the software are under different copyright and license, as outlined
in the [NOTICE.md](NOTICE.md) file.

## Trademarks

"MONGODB," "MONGO," "MONGODB CERTIFIED DEVELOPER," and the leaf logo are
registered trademarks of MongoDB, Inc. For more information, please refer to the
[MongoDB Trademark Usage
Guidelines](https://www.mongodb.com/legal/trademark-usage-guidelines).

Other trademarks are the property of their respective owners. BuyLibs is not
sponsored, endorsed, or affiliated with MongoDB, Inc.

## Contact

For more information, please visit our website at
[buylibs.com](https://buylibs.com) or reach out to us via email at
support@buylibs.com.
