import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class Authenticationpage extends StatefulWidget {
  const Authenticationpage({super.key});

  @override
  State<Authenticationpage> createState() => _AuthenticationpageState();
}

class _AuthenticationpageState extends State<Authenticationpage> {

  late final LocalAuthentication auth;
  bool _supportState = false;

  @override
  void initState(){
    super.initState();
    auth = LocalAuthentication();
    auth.isDeviceSupported().then(
        (bool isSupported) => setState(() {
          _supportState = isSupported;
        }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          if(_supportState)
            const Text('This Device is Supported')
          else
            const Text('This device is not supported'),


          const Divider(height: 100,),
          ElevatedButton(onPressed: _authenticate, child: Text("Authenticate"))
        ],
      ),
    );
  }

  Future<void> _authenticate () async {
    try {
      bool authenticated = await auth.authenticate(
          localizedReason: 'nothing for now',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false
        )
      );
      print("Authenticated: $authenticated");
    }
    on PlatformException catch (e) {
      print(e);
    }
  }

  Future<void> _getAvailableBiometrics() async {
    List<BiometricType> availableBiometrics =
        await auth.getAvailableBiometrics();

    print("List of availableBiometrics: $availableBiometrics");

    if (!mounted) {
      return;
    }
  }
}
