import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceLibraryPage extends StatelessWidget {
  final List<ResourceCategory> categories = [
    ResourceCategory(
      title: 'E-books',
      imagePath: 'lib/images/school.png',
      color: const Color.fromARGB(255, 40, 39, 26),
      description:
          'Explore a collection of e-books that provide guidance on autism awareness, therapy, and daily care strategies.',
      resources: [
        ResourceItem(
          title: 'Understanding Autism: A Guide for Parents and Teachers',
          url:
              'https://notionpress.com/in/read/understanding-autism-a-guide-for-parents-and-teachers',
        ),
        ResourceItem(
          title: 'Ido in Autismland: Climbing Out of Autism’s Silent Prison',
          url:
              'https://www.readingrockets.org/books-and-authors/books/ido-autismland-climbing-out-autisms-silent-prison',
        ),
        ResourceItem(
          title:
              'The Reason I Jump: The Inner Voice of a 13-Year Old Boy with Autism',
          url:
              'https://www.penguinrandomhouse.ca/books/227014/the-reason-i-jump-by-naoki-higashida/9780345807823',
        ),
        ResourceItem(
          title: 'Uniquely Human',
          url:
              'https://books.google.co.in/books/about/Uniquely_Human.html?id=yyFICgAAQBAJ&redir_esc=y',
        ),
      ],
    ),
    ResourceCategory(
      title: 'Articles',
      imagePath: 'lib/images/blog.png',
      color: const Color.fromARGB(255, 9, 65, 11),
      description:
          'Stay updated with the latest research, parenting tips, and expert insights on autism and related topics.',
      resources: [
        ResourceItem(
          title:
              'Advances in Supporting Parents in Interventions for Autism Spectrum Disorder',
          url: 'https://pubmed.ncbi.nlm.nih.gov/35934491/',
        ),
        ResourceItem(
          title:
              'Advancing Robot-Assisted Autism Therapy: A Novel Algorithm for Enhancing Joint Attention Interventions',
          url: 'https://arxiv.org/abs/2406.10392?utm_source=chatgpt.com',
        ),
        ResourceItem(
          title: 'Paths to Common Ground in ASD',
          url: 'https://onlinelibrary.wiley.com/doi/full/10.1002/aur.70006',
        ),
      ],
    ),
    ResourceCategory(
      title: 'Autism-Friendly Learning Apps',
      imagePath: 'lib/images/app.png',
      color: const Color.fromARGB(255, 6, 50, 87),
      description:
          'Discover apps designed to support learning and sensory development for individuals with autism.',
      resources: [
        ResourceItem(
          title: 'Proloquo2Go',
          url: 'https://assistive.co.nz/product/proloquo2go/',
        ),
        ResourceItem(
          title: 'BASICS: Speech | Autism | ADHD:',
          url:
              'https://play.google.com/store/apps/details?hl=en_US&id=in.mywellnesshub.autismbasicsunity&utm_source=chatgpt.com',
        ),
        ResourceItem(
          title: 'Autism iHelp – Sounds V1.0.1',
          url: 'https://autism-ihelp-sounds.soft112.com/',
        ),
      ],
    ),
    ResourceCategory(
      title: 'Best Therapy Techniques',
      imagePath: 'lib/images/occupational-therapy.png',
      color: const Color.fromARGB(255, 75, 10, 87),
      description:
          'Find effective therapy techniques, including speech and behavioral therapies, to aid autism treatment.',
      resources: [
        ResourceItem(
          title: 'Autism Speaks',
          url:
              'https://www.autismspeaks.org/speech-therapy?utm_source=chatgpt.com',
        ),
        ResourceItem(
          title: 'Speech therapy',
          url:
              'https://www.autism360.com/autism-speech-therapy-strategies/?utm_source=chatgpt.com',
        ),
        ResourceItem(
          title: 'Exercise for speech therapy',
          url:
              'https://www.expressable.com/learning-center/tips-and-resources/15-speech-therapy-strategies-for-parents-to-use-at-home',
        ),
        ResourceItem(
          title: 'Sensory Integration Therapy',
          url: 'https://autism.org/sensory-integration/',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Library'),
        backgroundColor: Colors.blue[900],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return ResourceCategoryWidget(category: categories[index]);
        },
      ),
    );
  }
}

class ResourceCategory {
  final String title;
  final String imagePath;
  final Color color;
  final String description;
  final List<ResourceItem> resources;

  ResourceCategory({
    required this.title,
    required this.imagePath,
    required this.color,
    required this.description,
    required this.resources,
  });
}

class ResourceItem {
  final String title;
  final String url;

  ResourceItem({required this.title, required this.url});
}

class ResourceCategoryWidget extends StatelessWidget {
  final ResourceCategory category;

  const ResourceCategoryWidget({Key? key, required this.category})
    : super(key: key);

  Future<void> _launchUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the link')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: category.color.withOpacity(0.15),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        leading: Image.asset(category.imagePath, width: 40, height: 40),
        title: Text(
          category.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: category.color,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            category.description,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        children:
            category.resources
                .map(
                  (resource) => ListTile(
                    leading: const Icon(Icons.link, color: Colors.blue),
                    title: Text(
                      resource.title,
                      style: const TextStyle(fontSize: 18),
                    ),
                    trailing: const Icon(Icons.open_in_new, color: Colors.blue),
                    onTap: () => _launchUrl(resource.url, context),
                  ),
                )
                .toList(),
      ),
    );
  }
}
