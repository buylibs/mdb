#!/usr/bin/env perl
# This is a Mojolicious application that demonstrates the use of BuyLibs
# asynchronous MongoDB operations for building a chat application.
# The application utilizes Mojo's built-in async/await functionality to interact
# with MongoDB in a non-blocking, high-performance manner.
#
# Benefits of BuyLibs asynchronous MongoDB usage with Mojo:
#
# 1. NON-BLOCKING I/O OPERATIONS: By using BuyLibs asynchronous MongoDB
#    connections, the application avoids blocking the event loop while
#    performing database operations. This enables the server to handle many
#    requests concurrently, improving overall performance and scalability,
#    especially in chat applications with frequent, small updates like message
#    sending/receiving.
#
# 2. BUILT-IN SUPPORT FOR PROMISES: Mojo's async/await syntax makes it easy to
#    manage asynchronous operations. The syntax is simple and readable, allowing
#    developers to write non-blocking code that looks and behaves like
#    synchronous code, reducing complexity.
#
# 3. PARALLEL EXECUTION: BuyLibs asynchronous MongoDB usage helps to parallelize
#    I/O-bound tasks (e.g., fetching messages from the database) without waiting
#    for one task to finish before starting the next, leading to faster response
#    times.
#

use Mojolicious::Lite -signatures;
use Mojo::EventEmitter;
use Mojo::Base -async_await;
use BuyLibs::MDB qw(-compat);   # The "-compat" option allows creating and using
                                # the new MongoDB client in the same way as the
                                # original MongoDB:: module.

$ARGV[0] //= 'daemon';

# Initialize the MongoDB connection and database, with specific connection
# pooling settings that enable parallel, non-blocking operations.
helper mongodb => sub {
    state $cli = MongoDB->mojo_connect($ENV{MONGOD} || 'mongodb://localhost');

    # Increase the default connection pool size from 100 to 150 if needed.
    $cli->pool->max_size(150);
    state $db = $cli->db('buylibs_mdb_examples_chatapp');
};

helper events => sub { state $events = Mojo::EventEmitter->new };

async sub load_messages ($c) {

    # Load the latest chat messages asynchronously from MongoDB, in the same way
    # as the MongoDB:: module, but using "await" for non-blocking IO.
    my @messages =
        await $c->mongodb->coll('messages')->find({})->sort({ '_id' => -1 })
        ->limit(20)->all;
    return reverse @messages;
}

get '/' => async sub ($c) {

    # Asynchronously fetch previous chat messages from MongoDB to display
    # on the web page.
    my @messages = await load_messages($c);

    # Render the previous messages on the frontend.
    $c->render(template => 'chat', messages => \@messages);
};

websocket '/channel' => sub ($c) {
    $c->inactivity_timeout(3600);

    # Handle incoming messages.
    $c->on(
        message => async sub ($c, $msg) {

            # Save the new message asynchronously to MongoDB.
            await $c->mongodb->coll('messages')
                ->insert_one({ message => $msg, timestamp => time });

            # Broadcast the message to all connected clients.
            $c->events->emit(mojochat => $msg);
        }
    );

    # Send the message to the client.
    my $cb = $c->events->on(mojochat => sub { $c->send(pop) });

    # Unsubscribe when the connection is finished.
    $c->on(
        finish => sub ($c, $code, $reason = undef) {
            $c->events->unsubscribe(mojochat => $cb);
        }
    );
};

app->start;

__DATA__

@@ chat.html.ep
<form onsubmit="sendMessage(this.children[0]); return false"><input></form>
<div id="history">
    <% for my $message (@$messages) { %>
        <p><%= $message->{message} %></p>
    <% } %>
</div>
<script>
    const ws = new WebSocket('<%= url_for('channel')->to_abs %>');
    ws.onmessage = function (e) {
        document.getElementById('history').innerHTML += '<p>' + e.data + '</p>';
    };
    function sendMessage(input) { ws.send(input.value); input.value = '' }
</script>
