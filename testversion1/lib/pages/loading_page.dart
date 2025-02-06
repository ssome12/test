import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadingPage extends StatefulWidget {
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSubscribed = prefs.getBool('subscribed') ?? false;
    });
    if (_isSubscribed) {
      Navigator.pushReplacementNamed(context, '/chat');
    }
  }

  Future<void> _subscribe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('subscribed', true);
    Navigator.pushReplacementNamed(context, '/chat');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("3일 무료 체험 후 주당 \$3 결제"),
            ElevatedButton(
              onPressed: _subscribe,
              child: const Text("무료 체험 시작"),
            ),
            ElevatedButton(
              onPressed: () {
                // 결제 시스템 연동 필요 (Stripe, in_app_purchase 등)
              },
              child: const Text("구독 결제"),
            ),
          ],
        ),
      ),
    );
  }
}
