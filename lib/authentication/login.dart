import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telenant/authentication/register.dart';
import 'package:telenant/home/admin/landingpage.dart';
import 'package:telenant/home/homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool loading = false;
  String emailValidation = '';
  String passwordValidation = '';
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void setLoginPersistent(String email) async {
    print('olahhhh');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userEmail', email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              bottom: -45,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Image.asset(
                  'assets/images/login.png',
                  fit: BoxFit.contain,
                ),
              )),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Telenant',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Baguio City transient reservation',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                        labelText: 'Email',
                        errorText:
                            emailValidation == '' ? null : emailValidation,
                        border: const OutlineInputBorder(
                            borderSide: BorderSide(width: 1.0))),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.5),
                        labelText: 'Password',
                        errorText: passwordValidation == ''
                            ? null
                            : passwordValidation,
                        helperText: 'Enter password maximum of 6 characters',
                        hintStyle: const TextStyle(color: Colors.black87),
                        border: const OutlineInputBorder(
                            borderSide: BorderSide(width: 1.0))),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          fixedSize: const Size(double.maxFinite, 40)),
                      onPressed: () async {
                        setState(() {
                          loading = true;
                        });
                        if (_usernameController.text.isEmpty ||
                            _passwordController.text.isEmpty) {
                          setState(() {
                            loading = false;
                            emailValidation = 'Email cannot be empty';
                            passwordValidation = 'Password cannot be empty';
                          });
                        } else {
                          setState(() {
                            emailValidation = '';
                            passwordValidation = '';
                          });
                          try {
                            final credential = await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                    email: _usernameController.text,
                                    password: _passwordController.text)
                                .then((value) async {
                              if (value.user != null) {
                                setLoginPersistent(
                                    value.user!.email.toString());
                                if (_usernameController.text
                                    .contains('telenant.admin.com')) {
                                  Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: ((context) =>
                                              const AdminHomeView())));
                                } else {
                                  Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: ((context) =>
                                              const HomePage())));
                                }
                              }
                              setState(() {
                                loading = false;
                              });
                            });
                          } on FirebaseAuthException catch (e) {
                            if (e.code == 'user-not-found') {
                              print('No user found for that email.');
                              setState(() {
                                emailValidation =
                                    'No user found for that email.';
                              });
                              setState(() {
                                loading = false;
                              });
                            } else if (e.code == 'wrong-password') {
                              setState(() {
                                emailValidation = '';
                                passwordValidation = 'Wrong-password';
                              });
                              setState(() {
                                loading = false;
                              });
                              print('Wrong password provided for that user.');
                            }
                          }
                        }
                      },
                      child: loading
                          ? const SizedBox(
                              height: 25,
                              width: 25,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text('Login')),
                  // const SizedBox(
                  //   height: 50,
                  // ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('''Don't have an account yet?'''),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) => const RegisterPage())));
                          },
                          child: const Text('Register'))
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
