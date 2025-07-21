import 'package:flutter/material.dart';
import 'package:carebridge/pages/CommunityForum/DiscussionBoard/discussion_board.dart';
import 'package:carebridge/pages/CommunityForum/Events/events.dart';
import 'package:carebridge/pages/CommunityForum/Stories/sharing_experience.dart';
import 'package:carebridge/pages/CommunityForum/ResourceLib/resource_library.dart';

class CommunityForumPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Forum'),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ForumTile(
              title: 'Discussion Board',
              imagePath: 'lib/images/discussion-forum.png',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DiscussionBoardPage(),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            ForumTile(
              title: 'Events',
              imagePath: 'lib/images/planner.png',
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => EventsPage()));
              },
            ),
            SizedBox(height: 20),
            ForumTile(
              title: 'User Stories',
              imagePath: 'lib/images/story.png',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SharingExperience()),
                );
              },
            ),
            SizedBox(height: 20),
            ForumTile(
              title: 'Resource Library',
              imagePath: 'lib/images/book.png',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ResourceLibraryPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ForumTile extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  ForumTile({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 60,
      leading: Image.asset(imagePath, height: 35),
      title: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      tileColor: const Color.fromARGB(255, 133, 164, 189),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
    );
  }
}
