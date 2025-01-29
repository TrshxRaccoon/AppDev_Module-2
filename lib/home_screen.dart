import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:flutter_module_2/login_screen.dart';

class DiceGame extends StatefulWidget {
  const DiceGame({super.key});

  @override
  State<DiceGame> createState() => _DiceGameState();
}

class _DiceGameState extends State<DiceGame> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController wagerController = TextEditingController();

  int wagerAmount = 0;
  int multiplier = 2;
  int walletBalance = 10;
  bool isBalanceFetched = false;

  @override
  void initState() {
    super.initState();
    if (!isBalanceFetched) {
      fetchWalletBalance();
    }
  }

  Future<void> fetchWalletBalance() async {
    final userId = auth.currentUser?.uid;

    try {
      QuerySnapshot snapshot = await firestore
          .collection('gameHistory')
          .where('UserID', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final latestRecord = snapshot.docs.first;
        setState(() {
          walletBalance = latestRecord['updatedBalance'];
          isBalanceFetched = true;
        });
      }
    } catch (e) {
      setState(() {
        walletBalance = 10;
        isBalanceFetched = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to fetch wallet balance! Using default of 10§'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool isValidWager(int wagerAmount) {
    if (wagerAmount == 0 || wagerAmount > walletBalance) {
      return false;
    }
    int maxPossibleWager = walletBalance ~/ multiplier;
    return wagerAmount <= maxPossibleWager;
  }

  void rollDice() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Random random = Random();

    List<int> diceRoll = [];
    for (int i = 0; i < 4; i++) {
      int diceRollValue = random.nextInt(6) + 1;
      diceRoll.add(diceRollValue);
    }

    int wagerAmount = int.tryParse(wagerController.text) ?? 0;

    if (!isValidWager(wagerAmount)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Invalid wager for $multiplier alike!'),
        duration: Duration(seconds: 1),
      ));
      return;
    }

    //The list containing counts of what number appeared in the 4 rolls (eg. diceRoll = [1,3,4,1] => rollFrequencyDistribution = [2,0,1,1,0,0])
    List<int> rollFrequencyDistribution = [0, 0, 0, 0, 0, 0];

    for (var roll in diceRoll) {
      rollFrequencyDistribution[roll - 1]++;
    }

    int maxFreqCount = rollFrequencyDistribution.reduce(max);
    String result;

    if (maxFreqCount >= multiplier) {
      walletBalance += wagerAmount * multiplier;
      result = 'Win';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Dice: $diceRoll\nYou won ${wagerAmount * multiplier}§!'),
        duration: Duration(seconds: 2),
      ));
    } else {
      walletBalance -= wagerAmount * multiplier;
      result = 'Lose';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Dice: $diceRoll\nYou lost ${wagerAmount * multiplier}§.'),
        duration: Duration(seconds: 2),
      ));
    }

    try {
      await firestore.collection('gameHistory').add({
        'UserID': auth.currentUser?.uid,
        'wager': wagerAmount,
        'diceRoll': diceRoll,
        'outcome': result,
        'updatedBalance': walletBalance,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save game history. [$e]'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    wagerController.clear();
    setState(() {});
  }

  void reset() {
    walletBalance = 10;
    wagerController.clear();
    setState(() {});
  }

  FirebaseAuth auth = FirebaseAuth.instance;
  void signOut() async {
    await auth.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  Future<void> clearHistory() async {
    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await firestore
          .collection('gameHistory')
          .where('UserID', isEqualTo: userId)
          .get();

      final batch = firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Game history cleared successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear history. [$e]'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> deleteOldRecords() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('gameHistory')
        .where('UserID', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    if (snapshot.docs.length > 100) {
      for (int i = 100; i < snapshot.docs.length; i++) {
        await snapshot.docs[i].reference.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4EDD3),
      appBar: AppBar(
        backgroundColor: Color(0xFFA5BFCC),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.dehaze, color: Color(0xFF31363F)),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(
          'Stake\'s Dice Game',
          style: TextStyle(
            color: Color(0xFF31363F),
            fontFamily: 'Quicksand-Regular',
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      drawer: Drawer(
        backgroundColor: Color(0xFFF4EDD3),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFFA5BFCC),
              ),
              child: Center(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.access_time_rounded, color: Color(0xFF4C585B)),
                    SizedBox(width: 5),
                    Text(
                      'History',
                      style: TextStyle(
                        fontSize: 24,
                        color: Color(0xFF4C585B),
                        fontFamily: 'Quicksand-Medium.ttf',
                      ),
                    ),
                  ])),
            ),
            Expanded(
              child: StreamBuilder(
                stream: auth.currentUser == null
                    ? null
                    : firestore
                        .collection('gameHistory')
                        .where('UserID', isEqualTo: auth.currentUser?.uid)
                        .orderBy('timestamp', descending: true)
                        .limit(20)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                      color: Color(0xFF222831),
                    ));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Text('No history found!'),
                          Text('Try playing your first round.')
                        ]));
                  }
                  final history = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final historyRecord = history[index];
                      return ListTile(
                        title: Text(
                            'Wager: ${historyRecord['wager']}§ Dice: ${historyRecord['diceRoll'].join(', ')}'),
                        subtitle: Text(
                            'Outcome: ${historyRecord['outcome']} Balance: ${historyRecord['updatedBalance']}§'),
                        trailing: Text(
                          historyRecord['timestamp'] != null
                              ? (historyRecord['timestamp'] as Timestamp)
                                  .toDate()
                                  .toString()
                              : 'N/A',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.refresh_outlined,
                  color: Color.fromARGB(255, 155, 71, 71)),
              title: Text(
                'Reset Wallet Balance',
                style: TextStyle(color: Color.fromARGB(255, 155, 71, 71)),
              ),
              onTap: reset,
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Color.fromARGB(255, 155, 71, 71)),
              title: Text('Clear History',
                  style: TextStyle(color: Color.fromARGB(255, 155, 71, 71))),
              onTap: () async {
                await clearHistory();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.logout, color: Color.fromARGB(255, 155, 71, 71)),
              title: Text('Sign Out',
                  style: TextStyle(color: Color.fromARGB(255, 155, 71, 71))),
              onTap: signOut,
            ),
            SizedBox(
              height: 30,
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        //I added SingleChildScrollView because when I opened the keypad to enter a wager, there would be a render overflow error
        padding: EdgeInsets.fromLTRB(20.0, 200.0, 20.0, 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Wallet: $walletBalance§',
              style: TextStyle(
                color: Color(0xFF222831),
                fontSize: 28,
              ),
            ),
            SizedBox(height: 40),
            TextField(
              controller: wagerController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Enter your wager',
              ),
              onChanged: (value) {
                setState(() {
                  wagerAmount = int.tryParse(value) ?? 0;
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              'Choose a multiplier:',
              style: TextStyle(fontSize: 14, color: Color(0xFF4C585B)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [2, 3, 4].map((multiplierOption) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      multiplier = multiplierOption;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: multiplier == multiplierOption ? 5 : 0,
                    backgroundColor: multiplier == multiplierOption
                        ? Color(0xFF4C585B)
                        : Color(0xFFA5BFCC),
                    foregroundColor: multiplier == multiplierOption
                        ? Color(0xFFA5BFCC)
                        : Color(0xFF222831),
                  ),
                  child: Text('$multiplierOption Alike'),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            SizedBox(
              child: ElevatedButton(
                onPressed: rollDice,
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(100, 55),
                    backgroundColor: Color(0xFFA5BFCC),
                    foregroundColor: Color(0xFF222831)),
                child: Row(
                  spacing: 10.0,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/dice.png'),
                    Text(
                      'Place Bet',
                      style: TextStyle(
                        color: Color(0xFF222831),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Bro wtf was this module
