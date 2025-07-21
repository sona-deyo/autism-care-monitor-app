import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtherUsersStories extends StatefulWidget {
  @override
  _OtherUsersStoriesState createState() => _OtherUsersStoriesState();
}

class _OtherUsersStoriesState extends State<OtherUsersStories> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _otherUserStories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOtherUserStories();
  }

  void _loadOtherUserStories() async {
    setState(() {
      _isLoading = true;
    });

    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      try {
        QuerySnapshot querySnapshot =
            await _firestore
                .collection('stories')
                .where('userId', isNotEqualTo: currentUser.uid)
                .get();

        List<Map<String, dynamic>> stories =
            querySnapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return {
                'story': data['story'] ?? 'No content',
                'timestamp': data['timestamp'] ?? Timestamp.now(),
                'userEmail':
                    data.containsKey('userEmail')
                        ? data['userEmail']
                        : 'Anonymous',
              };
            }).toList();

        setState(() {
          _otherUserStories = stories;
          _isLoading = false;
        });
      } catch (e) {
        print("Error loading other users' stories: $e");
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Other Users\' Stories')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _otherUserStories.isEmpty
              ? Center(child: Text('No stories from other users.'))
              : ListView.builder(
                itemCount: _otherUserStories.length,
                itemBuilder: (context, index) {
                  var story = _otherUserStories[index];
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(story['story']),
                      subtitle: Text("Posted by: ${story['userEmail']}"),
                    ),
                  );
                },
              ),
    );
  }
}
