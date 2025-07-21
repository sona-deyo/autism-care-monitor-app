import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DiscussionBoardPage extends StatefulWidget {
  const DiscussionBoardPage({super.key});

  @override
  _DiscussionBoardPageState createState() => _DiscussionBoardPageState();
}

class _DiscussionBoardPageState extends State<DiscussionBoardPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();
  String _selectedCategory = 'General';

  final List<String> categories = [
    'General',
    'Parenting Tips',
    'Education',
    'Health',
  ];

  Future<void> _addDiscussion() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty)
      return;

    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'Anonymous';
    String username = 'Anonymous';

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      username = userDoc['username'] ?? 'Anonymous';
    }

    await FirebaseFirestore.instance.collection('discussions').add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'category': _selectedCategory,
      'categoryStyled': _selectedCategory,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': userId,
      'username': username,
    });

    _titleController.clear();
    _descriptionController.clear();
    _selectedCategory = 'General';
    Navigator.pop(context);
  }

  Future<void> _addComment(String discussionId) async {
    if (_commentController.text.isEmpty) return;

    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'Anonymous';
    String username = 'Anonymous';

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      username = userDoc['username'] ?? 'Anonymous';
    }

    await FirebaseFirestore.instance
        .collection('discussions')
        .doc(discussionId)
        .collection('comments')
        .add({
          'text': _commentController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': userId,
          'username': username,
        });

    _commentController.clear();
  }

  Future<void> _deleteDiscussion(String discussionId) async {
    await FirebaseFirestore.instance
        .collection('discussions')
        .doc(discussionId)
        .delete();
  }

  void _showAddDiscussionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('New Discussion'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  onChanged:
                      (value) => setState(
                        () => _selectedCategory = value ?? 'General',
                      ),
                  items:
                      categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _addDiscussion,
                child: const Text('Post'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Discussion Board')),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance
                .collection('discussions')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(
              child: Text('No discussions yet. Be the first to post!'),
            );

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children:
                snapshot.data!.docs.map((discussion) {
                  String formattedDate =
                      discussion['timestamp'] != null
                          ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(discussion['timestamp'].toDate())
                          : 'Unknown date';

                  bool isAuthor =
                      currentUserId != null &&
                      discussion['userId'] == currentUserId;

                  return Card(
                    color: const Color.fromARGB(255, 231, 230, 230),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${discussion['title']}\n-${discussion['username']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isAuthor)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDiscussion(discussion.id),
                              tooltip: 'Delete discussion',
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 7,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color.fromARGB(255, 239, 237, 237),
                            ),
                            child: Text(
                              'Category: ${discussion['category']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${discussion['description']}',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text('$formattedDate'),
                        ],
                      ),
                      children: [
                        StreamBuilder(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('discussions')
                                  .doc(discussion.id)
                                  .collection('comments')
                                  .snapshots(),
                          builder: (
                            context,
                            AsyncSnapshot<QuerySnapshot> commentSnapshot,
                          ) {
                            if (!commentSnapshot.hasData)
                              return const Text('Loading comments...');
                            return Column(
                              children:
                                  commentSnapshot.data!.docs
                                      .map(
                                        (comment) => ListTile(
                                          title: Text(
                                            comment['username'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            comment['text'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          trailing: Text(
                                            comment['timestamp'] != null
                                                ? DateFormat(
                                                  'dd/MM/yyyy',
                                                ).format(
                                                  comment['timestamp'].toDate(),
                                                )
                                                : 'Unknown date',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  decoration: const InputDecoration(
                                    labelText: 'Add a comment',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () => _addComment(discussion.id),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDiscussionDialog,
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue[900],
      ),
    );
  }
}
