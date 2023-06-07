//Flutter imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatView extends StatefulWidget {
  ChatView({required this.receiver, required this.chatRoomId});

  final receiver;
  final chatRoomId;

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final user = FirebaseAuth.instance.currentUser;
  TextEditingController controller = TextEditingController();
  var messageslist = [];

  @override
  void initState() {
    super.initState();
    print(widget.receiver);
    //TODO: Complete the below functions.
    //checkUser();
    //scrollToBottom();
  }

  checkUser() async {
    var condition;
    await FirebaseFirestore.instance
        .collection('/ChatRoom/${widget.chatRoomId}/messages')
        .where('isRead', isEqualTo: false)
        .get()
        .then((QuerySnapshot snapshot) => snapshot.docs.forEach((element) {
              setState(() {
                if (element['sender'] != user!.uid) {
                  condition = true;
                }
                messageslist.add(element['sender']);
              });
            }));
    if (condition) {
      await FirebaseFirestore.instance
          .doc('/messages/${user!.uid}/recent/${widget.receiver['UID']}')
          .update({
        "isRead": true as bool,
      });
      await FirebaseFirestore.instance
          .doc('/messages/${widget.receiver['UID']}/recent/${user!.uid}')
          .update({
        "isRead": true as bool,
      });
    }
  }

  ScrollController _scrollController = ScrollController();

  scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  sendMessages(text) async {
    var message = text;
    controller.clear();
    DateTime? date = DateTime.now();
    await FirebaseFirestore.instance
        .collection('/ChatRoom/${widget.chatRoomId}/messages')
        .add({
      "message": message as String,
      "Time": date,
      "sender": user!.uid,
    });
    date = null;
    scrollToBottom();
    await FirebaseFirestore.instance
        .doc('/messages/${user!.uid}/recent/${widget.receiver['UID']}')
        .update({
      "UID": widget.receiver['UID'],
      "Email": widget.receiver['Email'] as String,
      "lastmessage": message,
      "isRead": false as bool,
    });
    await FirebaseFirestore.instance
        .doc('/messages/${widget.receiver['UID']}/recent/${user!.uid}')
        .update({
      "UID": user!.uid,
      "Email": user!.email as String,
      "lastmessage": message,
      "isRead": false as bool,
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Color(0xFFAFE0BD),
      appBar: AppBar(
        titleSpacing: 0,
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            maxRadius: 20,
            backgroundImage: NetworkImage(
              widget.receiver['Photo'],
            ),
          ),
          title: Text(
            widget.receiver['Name'],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            DateFormat('jm').format(widget.receiver['lastseen'].toDate()),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
      body: Stack(children: [
        loadMessages(widget.chatRoomId),
        Container(
          alignment: Alignment.bottomCenter,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    width: totalWidth * 0.85,
                    decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black12,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                          ),
                        ]),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Send a message...',
                        border: InputBorder.none,
                      ),
                    )),
              ),
              SizedBox(
                width: 5,
              ),
              Container(
                width: totalWidth * 0.10,
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                child: IconButton(
                  onPressed: () {
                    if (controller.text.trim() != '') {
                      sendMessages(controller.text);
                    } else {
                      controller.clear();
                    }
                  },
                  icon: Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget loadMessages(chatRoomId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 70),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('/ChatRoom/$chatRoomId/messages')
            .orderBy("Time", descending: false)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          return snapshot.data!.docs.isEmpty
              ? Center(
                  child: Text('Say Hai'),
                )
              : ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  reverse: false,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return MessageBox(
                      list: snapshot.data!.docs[index],
                    );
                  },
                );
        },
      ),
    );
  }
}

class MessageBox extends StatelessWidget {
  MessageBox({required this.list});

  final list;
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: list['sender'] == user!.uid ? 0 : 10,
          right: list['sender'] == user!.uid ? 10 : 0),
      alignment: list['sender'] == user!.uid
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: list['sender'] == user!.uid
            ? EdgeInsets.only(left: 30)
            : EdgeInsets.only(right: 30),
        padding: EdgeInsets.only(top: 5, bottom: 5, left: 15, right: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: list['sender'] == user!.uid
                ? [Colors.white, Colors.white]
                : [Color(0xFF7DE38E), Color(0xFF7DE38E)],
          ),
          borderRadius: list['sender'] == user!.uid
              ? BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                )
              : BorderRadius.only(
                  bottomRight: Radius.circular(15),
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: list['sender'] == user!.uid
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              list['message'],
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('jm').format(list['Time'].toDate()),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(
                    width: 3,
                  ),
                  Icon(
                    Icons.done_all_rounded,
                    size: 13,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
