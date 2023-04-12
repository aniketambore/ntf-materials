import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:noost_client/component_library/component_library.dart';
import 'package:noost_client/domain_models/domain_models.dart';
import 'package:noost_client/helpers/helpers.dart';
import 'package:noost_client/screens/feed_screen.dart/widgets/widgets.dart';
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
  late Stream<Event> _stream;
  final _controller = StreamController<Event>();

  // TODO: Initialize an instance of FlutterSecureStorage
  // TODO: Initialize two empty String variables to hold the private and public keys
  // TODO: Initialize a boolean variable to track whether keys exist or not

  // TODO: Declare and initialize instances of TextEditingController, GlobalKey, KeyApi, and Nip19
  // TODO: Initialize a boolean variable to track if note publishing is in progress

  @override
  void initState() {
    // TODO: Call _getKeysFromStorage()
    _initStream();
    super.initState();
  }

  @override
  void dispose() {
    _relay.close();
    super.dispose();
  }

  // TODO: Implement the _getKeysFromStorage() method to retrieve keys from secure storage

  // TODO: Implement the _addKeysToStorage() method to add keys to secure storage

  // TODO: Implement the _deleteKeysFromStorage() method to delete keys from secure storage

  // TODO: Implement the _generateNewKeys() method to generate new keys and add them to secure storage

  Future<Stream<Event>> _connectToRelay() async {
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

    return stream
        .where((message) => message.type == 'EVENT')
        .map((message) => message.message);
  }

  void _initStream() async {
    _stream = await _connectToRelay();
    _stream.listen((message) {
      final event = message;
      if (event.kind == 1) {
        setState(() => _events.add(event));
        _relay.sub([
          Filter(kinds: [0], authors: [event.pubkey])
        ]);
      } else if (event.kind == 0) {
        final metadata = Metadata.fromJson(jsonDecode(event.content));
        setState(() => _metaDatas[event.pubkey] = metadata);
      }
      _controller.add(event);
    });
  }

  // TODO: Implement the `_resubscribeStream` method to initialize a stream.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// TODO: Update the NoostAppBar widget with appropriate keysDialog, and deleteKeysDialog parameters.
      appBar: NoostAppBar(
        title: 'Noost',
        isConnected: _isConnected,
      ),

      /// TODO: Implement the RefreshIndicator widget and its onRefresh callback to handle refreshing of the page.
      body: StreamBuilder(
        stream: _controller.stream,
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

      /// TODO: Implement the CreatePostFAB widget to enable users to create new Noosts.
    );
  }

  void modalBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return KeysOptionModalBottomSheet(
          generateNewKeyPressed: () {
            /// TODO: Implement logic to generate new keys
            /// After keys are generated, show a SnackBar with the message "Congratulations! Keys Generated!"
            /// and dismiss the bottom sheet using Navigator.pop(context)
          },
          inputPrivateKeyPressed: () {
            /// TODO: Implement logic to handle input of private key
            /// After private key is input, dismiss the bottom sheet using Navigator.pop(context)
            /// and show the pastePrivateKeyDialog() to handle the input
          },
        );
      },
    );
  }

  void pastePrivateKeyDialog() {
    // TODO: Showing PastePrivateKeyDialog to handle the input
  }

  void keysExistDialog(String npubEncode, String nsecEncode) async {
    await showDialog(
      context: context,
      builder: ((context) {
        return KeysExistDialog(
          npubEncoded: npubEncode,
          nsecEncoded: nsecEncode,
          // TODO: Replace hexPriv and hexPub values
          hexPriv: '',
          hexPub: '',
        );
      }),
    );
  }

  void deleteKeysDialog() async {
    await showDialog(
      context: context,
      builder: ((context) {
        return DeleteKeysDialog(
          onNoPressed: () {
            Navigator.pop(context);
          },
          onYesPressed: () {
            // TODO: Implement the logic to delete keys from storage

            Navigator.pop(context);
          },
        );
      }),
    );
  }
}
