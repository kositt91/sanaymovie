import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:propertychannel/video_player.dart';

class MovieDetailPage extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String actors;
  final String detailUrl;

  const MovieDetailPage({
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.actors,
    required this.detailUrl,
  }) : super(key: key);

  @override
  _MovieDetailPageState createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  String description = '';
  String m3u8Url = ''; // Placeholder for the .m3u8 URL
  String directors = '';
  String scriptwriters = '';
  String actors = '';
  String type = '';
  String area = '';
  String year = '';
  String grade = '';

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();
  }

  void fetchMovieDetails() async {
    final response = await http.get(Uri.parse(widget.detailUrl));

    if (response.statusCode == 200) {
      BeautifulSoup bs = BeautifulSoup(response.body);

      var descriptionElement = bs.find('div', class_: 'hidden-xs hidden-sm');
      description =
          descriptionElement?.text.trim() ?? 'No description available.';

      var mediaBody = bs.find('div', class_: 'media-body');
      if (mediaBody != null) {
        // Extracting Starring
        var actorsElement = mediaBody.find('dd', class_: 'text-mr-1');
        var actorss =
            actorsElement?.findAll('a').map((a) => a.text).join(', ') ??
                'Unknown';

        // Extracting Director
        var directorElement = mediaBody.findAll('dd', class_: 'text-mr-1')[1];
        directors =
            directorElement?.findAll('a').map((a) => a.text).join(', ') ??
                'Unknown';

        // Extracting Scriptwriter
        var scriptwriterElement =
            mediaBody.find('dd', class_: 'text-mr-1 hidden-xs hidden-sm');
        scriptwriters = scriptwriterElement?.text.trim() ?? 'Unknown';

        // Extracting Type
        var typeElement = mediaBody.findAll('dd', class_: 'text-mr-1')[2];
        type = typeElement?.findAll('a').map((a) => a.text).join(', ') ??
            'Unknown';

        // Extracting Area
        var areaElement =
            mediaBody.findAll('dd', class_: 'text-mr-1 hidden-xs hidden-sm')[1];
        area = areaElement?.find('a')?.text ?? 'Unknown';

        // Extracting Year
        var yearElement = mediaBody.findAll('dd', class_: 'text-mr-1')[3];
        year = yearElement?.find('a')?.text ?? 'Unknown';

        // Extracting Grade
        var gradeElement = mediaBody.find('sup', class_: 'ff-score-val');
        grade = gradeElement?.text.trim() ?? '0.0';

        // Update the description if available
        var geassElement = mediaBody.find('div', class_: 'hidden-xs hidden-sm');
        if (geassElement != null) {
          description = geassElement.text.trim();
        }
      }

      var videoPageElement = bs.find('a',
          class_: 'btn btn-default btn-block btn-sm text-ellipsis');
      var videoPageUrl = videoPageElement?.attributes['href'] ?? '';

      if (videoPageUrl.isNotEmpty) {
        if (!videoPageUrl.startsWith('http')) {
          videoPageUrl = 'http://www.zegomovie.com' + videoPageUrl;
        }
        print('Video Page URL: $videoPageUrl');

        // Fetch the video page to extract the .m3u8 URL
        final videoResponse = await http.get(Uri.parse(videoPageUrl));

        if (videoResponse.statusCode == 200) {
          BeautifulSoup videoBs = BeautifulSoup(videoResponse.body);

          // Extract the .m3u8 URL
          var scriptElements = videoBs.findAll('script');
          String scriptContent = '';
          for (var script in scriptElements) {
            if (script.text.contains('cms_player')) {
              scriptContent = script.text;
              break;
            }
          }

          var urlPattern = RegExp(r'url":"(http[^"]+)');
          var match = urlPattern.firstMatch(scriptContent);
          var extractedUrl = match?.group(1) ?? '';

          // Format the URL if necessary
          if (extractedUrl.isNotEmpty) {
            extractedUrl = extractedUrl.replaceAll(r'\/', '/');
            print('M3U8 URL: $extractedUrl');
            setState(() {
              m3u8Url = extractedUrl;
            });
          } else {
            print('M3U8 URL not found');
          }
        } else {
          print('Failed to load video page');
        }
      } else {
        print('Video Page URL not found');
      }

      setState(() {
        // Update state with fetched data
      });
    } else {
      print('Failed to load movie details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white), // Title color
        ),
        backgroundColor: Colors.grey[900], // Dark theme color
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  height: 300, // Adjusted image height
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.error,
                        color: Colors.grey); // Error icon color
                  },
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              "Directors: ${directors.isNotEmpty ? directors : 'Unknown'}",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[300],
              ),
            ),
            Text(
              "Area: ${area.isNotEmpty ? area : 'Unknown'}",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[300],
              ),
            ),
            Text(
              "Description",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (m3u8Url.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoScreen(
                          videoUrl: m3u8Url,
                        ),
                      ),
                    );
                  } else {
                    print('M3U8 URL is empty');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent, // New button color
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Watch Video',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black, // Background color
    );
  }
}
