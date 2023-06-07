//Flutter imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

//Local imports
import './chatveiw.dart';
import './search.dart';
import '../utils/google_sign_in.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var userIdList = [];
  var index = 0;
  final user = FirebaseAuth.instance.currentUser;
  late PageController pageController = PageController(
    initialPage: index,
  );
  final userProfilelist = [];
  final userRecentlist = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  loadUsers() async {
    await FirebaseFirestore.instance
        .collection('/messages/${user!.uid}/recent/')
        .get()
        .then((QuerySnapshot snapshot) {
      snapshot.docs.forEach((element) {
        userRecentlist.add(element.data());
        userIdList.add(element.id);
      });
    });
    for (int i = 0; i < userIdList.length; i++) {
      await FirebaseFirestore.instance
          .doc('/users/${userIdList[i]}')
          .get()
          .then((DocumentSnapshot snapshot) {
        setState(() {
          userProfilelist.add(snapshot.data());
        });
      });
    }
  }

  Widget oldView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatBot'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                final provider =
                    Provider.of<GoogleSignInProvider>(context, listen: false);
                provider.logout();
              },
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          userProfilelist.clear();
          userIdList.clear();
          userRecentlist.clear();
          return loadUsers();
        },
        child: userIdList.isNotEmpty
            ? userProfilelist.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    itemCount: userProfilelist.length,
                    itemBuilder: (BuildContext context, index) {
                      try {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatView(
                                  receiver: userProfilelist[index],
                                  chatRoomId: userRecentlist[index]
                                      ['ChatRoomId'],
                                ),
                              ),
                            );
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              maxRadius: 30,
                              backgroundImage: NetworkImage(
                                userProfilelist[index]['Photo'],
                              ),
                            ),
                            title: Text(
                              userProfilelist[index]['Name'],
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              userRecentlist[index]['lastmessage'],
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: Text(
                              DateFormat('jm').format(
                                userProfilelist[index]['lastseen'].toDate(),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      } catch (e) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    })
            : const Center(
                child: Text('No Recent Chats'),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchChats(
                  recentList: userRecentlist,
                ),
              ));
        },
        child: const Icon(Icons.search_rounded),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() {
            index = i;
            // pageController.jumpToPage(i);
          });
        },
        animationDuration: const Duration(
          milliseconds: 500,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.message_rounded),
            selectedIcon: Icon(Icons.message),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRecent = FirebaseFirestore.instance
        .collection('/messages/${user!.uid}/recent/')
        .snapshots();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('ChatBot'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                final provider =
                    Provider.of<GoogleSignInProvider>(context, listen: false);
                provider.logout();
              },
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: StreamBuilder(
          stream: userRecent,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasData) {
              List<QueryDocumentSnapshot> recent = snapshot.data?.docs ?? [];
              return ListView.builder(
                itemCount: recent.length,
                itemBuilder: (context, index) {
                  final receiver = FirebaseFirestore.instance.doc('/users/${recent[index].id}').snapshots();
                  return StreamBuilder(
                    stream: receiver,
                    builder: (context, snap) {
                      if(snapshot.hasData) {
                        Map<String, dynamic>? data = snap.data?.data();
                        if(data != null){
                          return InkWell(
                            onTap: () {
                              if (kDebugMode) {
                                print(data);
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatView(
                                    receiver: data,
                                    chatRoomId: recent[index]['ChatRoomId'],
                                  ),
                                ),
                              );
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                maxRadius: 30,
                                backgroundImage: NetworkImage(
                                  data['Photo'],
                                ),
                              ),
                              title: Text(
                                data['Name'],
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                recent[index]['lastmessage'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: Text(
                                DateFormat('jm').format(
                                  data['lastseen'].toDate(),
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox(height: 0,);
                        }
                      } else {
                        return const SizedBox(height: 0,);
                      }
                    },
                  );
                },
              );
            }

            return const Center(
              child: Text('Something Went Wrong!!'),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchChats(
                  recentList: userRecentlist,
                ),
              ));
        },
        child: const Icon(Icons.search_rounded),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() {
            index = i;
            // pageController.jumpToPage(i);
          });
        },
        animationDuration: const Duration(
          milliseconds: 500,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.message_rounded),
            selectedIcon: Icon(Icons.message),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}
