import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_module_2/signup_screen.dart';
import 'package:flutter_module_2/home_screen.dart';

class LoginPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const LoginPage(),
      );
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  GlobalKey formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUserWithEmailAndPassword() async {
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DiceGame()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage(errorCode) {
        switch (errorCode) {
          case 'invalid-email':
            return "The email address is not valid. Please try again.";
          case 'user-disabled':
            return "This user account has been disabled.";
          case 'user-not-found':
            return "No user found with this email. Please sign up first.";
          case 'wrong-password':
            return "Incorrect password. Please try again.";
          case 'network-request-failed':
            return "Network error! Please check your internet connection.";
          default:
            return "An unknown error occurred. Please try again.";
        }
      }

      String errorLog = errorMessage(e.code);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorLog),
        duration: Duration(seconds: 2),
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4EDD3),
      body: Padding(
        padding: EdgeInsets.all(15.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome\nBack!',
                  style: TextStyle(
                    color: Color(0xFF222831),
                    fontSize: 50,
                    fontFamily: 'Quicksand-Medium.ttf',
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                ),
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  hintText: 'Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF222831),)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF222831),
                      ),
                      onPressed: () async {
                        await loginUserWithEmailAndPassword();
                      },
                      child: const Text(
                        'LOG IN',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFA5BFCC),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, SignUpPage.route());
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Don\'t have an account? ',
                    style: Theme.of(context).textTheme.titleMedium,
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
