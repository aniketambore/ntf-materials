import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:noost_client/component_library/component_library.dart';
import 'package:noost_client/domain_models/domain_models.dart';
import 'package:noost_client/helpers/helpers.dart';
import 'package:nostr_tools/nostr_tools.dart';

class NoostFeedScreen extends StatefulWidget {
  const NoostFeedScreen({super.key});

  @override
  State<NoostFeedScreen> createState() => _NoostFeedScreenState();
}

class _NoostFeedScreenState extends State<NoostFeedScreen> {
  bool _isConnected = false;
  final _relay = RelayApi(relayUrl: 'wss://relay.damus.io');
  final List<Event> _events = [];
  final Map<String, Metadata> _metaDatas = {};

  @override
  void dispose() {
    _relay.close();
    super.dispose();
  }

  Stream get relayStream async* {
    final stream = await _relay.connect();

    _relay.on((event) {
      if (event == RelayEvent.connect) {
        setState(() => _isConnected = true);
      } else if (event == RelayEvent.error) {
        setState(() => _isConnected = false);
      }
    });

    _relay.sub([
      Filter(
        kinds: [1],
        limit: 100,
        t: ["nostr"],
      )
    ]);

    await for (var message in stream) {
      if (message.type == 'EVENT') {
        Event event = message.message;

        if (event.kind == 1) {
          _events.add(event);
          _relay.sub([
            Filter(kinds: [0], authors: [event.pubkey])
          ]);
        } else if (event.kind == 0) {
          Metadata metadata = Metadata.fromJson(jsonDecode(event.content));
          _metaDatas[event.pubkey] = metadata;
        }
      }
      yield message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NoostAppBar(
        title: 'Noost',
        isConnected: _isConnected,
      ),
      body: StreamBuilder(
        stream: relayStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                final metadata = _metaDatas[event.pubkey];
                final noost = Noost(
                  noteId: event.id,
                  avatarUrl: metadata?.picture ??
                      'https://robohash.org/${event.pubkey}',
                  name: metadata?.name ?? 'Anon',
                  username: metadata?.displayName ??
                      (metadata?.display_name ?? 'Anon'),
                  time: TimeAgo.format(event.created_at),
                  content: event.content,
                  pubkey: event.pubkey,
                );
                return NoostCard(noost: noost);
              },
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text('Loading....'));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return const CenteredCircularProgressIndicator();
        },
      ),
    );
  }
}
