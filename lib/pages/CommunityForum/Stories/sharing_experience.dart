import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'other_users_stories.dart';

class SharingExperience extends StatefulWidget {
  @override
  _SharingExperienceState createState() => _SharingExperienceState();
}

class _SharingExperienceState extends State<SharingExperience> {
  final TextEditingController _storyController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  List<Map<String, dynamic>> _userStories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadUserStories();
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  void _loadUserStories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_currentUser != null) {
        QuerySnapshot querySnapshot =
            await _firestore
                .collection('stories')
                .where('userId', isEqualTo: _currentUser!.uid)
                .get();

        List<Map<String, dynamic>> stories =
            querySnapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'story': data['story'] ?? 'No content',
                'timestamp': data['timestamp'] ?? Timestamp.now(),
                'userId': data['userId'] ?? '',
                'userEmail': data['userEmail'] ?? 'Anonymous',
              };
            }).toList();

        stories.sort((a, b) {
          Timestamp timestampA = a['timestamp'] as Timestamp;
          Timestamp timestampB = b['timestamp'] as Timestamp;
          return timestampB.compareTo(timestampA);
        });

        setState(() {
          _userStories = stories;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "No user logged in.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error loading stories: $e";
      });
    }
  }

  void _postStory() async {
    if (_currentUser != null && _storyController.text.trim().isNotEmpty) {
      try {
        await _firestore.collection('stories').add({
          'story': _storyController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'userId': _currentUser!.uid,
          'userEmail': _currentUser!.email ?? 'Anonymous',
        });
        _storyController.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Story posted successfully!")));
        _loadUserStories();
      } catch (e) {
        setState(() {
          _errorMessage = "Error posting story: $e";
        });
      }
    }
  }

  void _deleteStory(String storyId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Story"),
          content: Text("Are you sure you want to delete this story?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete) {
      try {
        await _firestore.collection('stories').doc(storyId).delete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Story deleted successfully!")));
        _loadUserStories();
      } catch (e) {
        setState(() {
          _errorMessage = "Error deleting story: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share Your Experience'),
        actions: [
          IconButton(
            icon: Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OtherUsersStories()),
              );
            },
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadUserStories),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _storyController,
              decoration: InputDecoration(
                hintText: 'Write your story...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ),
          ElevatedButton(onPressed: _postStory, child: Text('Post Story')),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            ),
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _userStories.isEmpty
                    ? Center(child: Text('No stories posted yet.'))
                    : ListView.builder(
                      itemCount: _userStories.length,
                      itemBuilder: (context, index) {
                        var story = _userStories[index];
                        return Card(
                          margin: EdgeInsets.all(10),
                          child: ListTile(
                            title: Text(story['story']),
                            subtitle: Text("Posted by: ${story['userEmail']}"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteStory(story['id']),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
