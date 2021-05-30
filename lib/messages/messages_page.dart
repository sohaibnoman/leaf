import 'package:flutter/material.dart';
import 'package:leaf/presence/widgets/presence_bubble.dart';
import 'package:leaf/profile/profile_page.dart';
import 'package:provider/provider.dart';

import 'messages_provider.dart';
import 'widgets/message_bar.dart';
import 'widgets/messages_list.dart';
import '../global/widgets/leaf_error.dart';

class MessagesPage extends StatefulWidget {
  static const routeName = '/chat';
  final String rid;
  final String receiverName;
  final String receiverImage;

  const MessagesPage({@required this.rid, this.receiverName, this.receiverImage});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  MessagesProvider messagesProvider;

  @override
  void initState() {
    super.initState();
    context.read<MessagesProvider>().unsubscribeFromChatNotifications();
    context.read<MessagesProvider>().fetchMessages(widget.rid);
    messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
    messagesProvider.subscribeToChatNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<MessagesProvider>().isLoading;
    final isError = context.watch<MessagesProvider>().isError;
    return Scaffold(
      appBar: AppBar(
          title: ListTile(
            contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
            onTap: () {
              Navigator.of(context, rootNavigator: true).pushNamed(
                ProfilePage.routeName,
                arguments: widget.rid,
              );
            },
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(widget.receiverImage),
                  ),
                ),
                PresenceBubble(widget.rid, 18)
              ],
            ),
            title: Text(widget.receiverName),
          ),
          elevation: 0),
      body: isError
          ? Center(
              child: LeafError(
                  context.read<MessagesProvider>().refetchMessages, widget.rid))
          : isLoading
              ? Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(child: MessagesList()),
                      MessageBar(
                        rid: widget.rid,
                        receiverName: widget.receiverName,
                        receiverImage: widget.receiverImage,
                      )
                    ],
                  ),
                ),
    );
  }
}
