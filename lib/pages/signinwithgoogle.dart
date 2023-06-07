//Flutter imports
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//Local imports
import '../utils/backgroundpainter.dart';
import '../utils/google_sign_in.dart';

class SignUp extends StatefulWidget {
  SignUp({Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  @override
  void initState(){
    super.initState();
    networkStatus();
  }

  final snackBar = SnackBar(
    content: Text('No Internet! Check your connection'),
    backgroundColor: Colors.red,
    duration: Duration(seconds: 4),
    behavior: SnackBarBehavior.floating,
  );


  networkStatus() async{
    var connectionStatus = await Connectivity().checkConnectivity();
    if(connectionStatus == ConnectivityResult.none){
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            body: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: BackgroundPainter(),
                  ),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Spacer(),
                      Container(
                        padding:const EdgeInsets.only(bottom: 40),
                        child: Column(
                          children: [
                            const Text(
                              'Sign in to ChatBot using',
                              style: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            const Text(
                              'your Gmail ID',
                              style: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.only(bottom: 20),
                        height: 60,
                        width: 223,
                        child: ElevatedButton(
                          child: Text("Sign in with Google"),
                          onPressed:   () {
                              final provider = Provider.of<GoogleSignInProvider>(context, listen: false);
                              provider.login();
                          },
                        ),
                      ),
                      SizedBox(
                        height: 150,
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          );
  }
}
