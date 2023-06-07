//Flutter imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//Local imports
import 'chatveiw.dart';

class SearchChats extends StatefulWidget {
  SearchChats({required this.recentList});

  final recentList;

  @override
  _SearchChatsState createState() => _SearchChatsState();
}

class _SearchChatsState extends State<SearchChats> {
  TextEditingController controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  String text = 'Something went Wrong!';

  @override
  void initState(){
    super.initState();
    setUserList();
  }

  var userlist = [];
  var recentList = [];
  var chatRoomId;
  
  createChatRoom(receiver,context) async{
    recentList = widget.recentList;
    bool isExist = false;
    for(int i = 0; i < recentList.length; i++){
      if (recentList[i]['UID'] == receiver['UID']) {
        isExist = true;
        setState(() {
          chatRoomId = recentList[i][''];
          Navigator.push(context, MaterialPageRoute(builder: (context) =>
              ChatView(receiver: receiver,chatRoomId: chatRoomId,)));
        });
      }
    }
    if(!isExist) {
      var prefixCharacterList = user!.displayName.toString().split('').toList();
      var prefix = '${prefixCharacterList[0] + prefixCharacterList[1] +
          prefixCharacterList[2] + prefixCharacterList[3]}';
      var suffix = receiver['Name'].toString().split('')[0] +
          receiver['Name'].toString().split('')[1];
      var generatedCRID = '${prefix + DateTime.now().toString() + suffix}';
      await FirebaseFirestore.instance.doc('/ChatRoom/$generatedCRID').set({
        'CreatedOn': DateTime.now() as DateTime,
      });
      setState(() {
        chatRoomId = generatedCRID;
        Navigator.push(context, MaterialPageRoute(builder: (context) =>
            ChatView(receiver: receiver,chatRoomId: chatRoomId,)));
      });
      await FirebaseFirestore.instance.doc('/messages/${user!.uid}/recent/${receiver['UID']}').set(
          {
            "UID" : receiver['UID'],
            "Email" : receiver['Email'] as String,
            "lastmessage" : ' ',
            "ChatRoomId" : generatedCRID,
          }
      );
      await FirebaseFirestore.instance.doc('/messages/${receiver['UID']}/recent/${user!.uid}').set(
          {
            "UID" : user!.uid,
            "Email" : user!.email as String,
            "lastmessage" : ' ',
            "ChatRoomId" : generatedCRID,
          }
      );
    }
  }
  
  setUserList() async{
    await FirebaseFirestore.instance.collection('/users').get().then(
            (QuerySnapshot snapshot) {
                  userlist.clear();
                  snapshot.docs.forEach((element) { 
                    setState(() {
                      if(element.id == user!.uid) {
                        text = 'You are the only one Here!';
                      } else{
                        userlist.add(element.data());
                      }
                    });
                  });
            });
    print(userlist);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        title: Text('User List'),
      ),
      body: userlist.isNotEmpty ? ListView.builder(
          physics: BouncingScrollPhysics(),
          itemCount: userlist.length,
          itemBuilder: (context, int index){
            return InkWell(
              onTap: (){
                Navigator.pop(context);
                createChatRoom(userlist[index],context);
              },
              child: Container(
                child: ListTile(
                  onTap: (){
                    createChatRoom(userlist[index],context);
                  },
                      leading: CircleAvatar(maxRadius: 30, backgroundImage: NetworkImage(userlist[index]['Photo']),),
                      title: Text(userlist[index]['Name'],style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold),),
                      subtitle: Text(userlist[index]['Email'], style: TextStyle(fontSize: 15,color: Colors.grey),),
                ),
              ),
            );
          }
      ) : Center(
        child: Text(text),
      ),
    );
  }
}
