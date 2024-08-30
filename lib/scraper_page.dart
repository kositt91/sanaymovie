import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'movie_detail_page.dart'; // Import the MovieDetailPage

class MovieListPage extends StatefulWidget {
  @override
  _MovieListPageState createState() => _MovieListPageState();
}

class _MovieListPageState extends State<MovieListPage> {
  List<Map<String, dynamic>> movies = [];
  List<Map<String, dynamic>> filteredMovies = [];
  String searchQuery = '';
  int currentPage = 1; // Track the current page
  bool isLoading = false; // Track loading state

  @override
  void initState() {
    super.initState();
    fetchMovies(currentPage);
  }

  void fetchMovies(int page) async {
    setState(() {
      isLoading = true; // Start loading
    });

    final response = await http.get(Uri.parse(
        'http://www.zegomovie.com/index.php?s=/list-select-id-1-type--area--year--star--state--order-addtime-p-$page.html'));

    if (response.statusCode == 200) {
      BeautifulSoup bs = BeautifulSoup(response.body);

      var movieElements = bs.findAll('li', class_: 'col-sm-3 col-xs-4');
      movies = movieElements.map((element) {
        var titleElement = element.find('h2');
        var title = titleElement?.find('a')?.text.trim() ?? 'No Title';

        var imageElement = element.find('img');
        var imageUrl = imageElement?.attributes['data-original'] ?? '';

        // If image URL is relative, prepend the base URL
        if (!imageUrl.startsWith('http')) {
          imageUrl = 'http://www.zegomovie.com' + imageUrl;
        }

        // Extract the detail URL from the <a> tag within the <h2> tag
        var detailUrl = titleElement?.find('a')?.attributes['href'] ?? '';
        if (!detailUrl.startsWith('http')) {
          detailUrl = 'http://www.zegomovie.com' + detailUrl;
        }

        return {
          'title': title,
          'imageUrl': imageUrl,
          'detailUrl': detailUrl,
        };
      }).toList();

      setState(() {
        filteredMovies = movies;
        isLoading = false; // Stop loading
      });
    } else {
      print('Failed to load movies');
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  void _filterMovies(String query) {
    setState(() {
      searchQuery = query;
      filteredMovies = movies.where((movie) {
        return movie['title'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _goToFirstPage() {
    setState(() {
      currentPage = 1;
      fetchMovies(currentPage);
    });
  }

  void _goToPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
        fetchMovies(currentPage);
      });
    }
  }

  void _goToNextPage() {
    setState(() {
      currentPage++;
      fetchMovies(currentPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sanay Mg Mg Movie Collection',
          style: TextStyle(color: Colors.white), // Title color
        ),
        backgroundColor: Colors.grey[900], // Dark theme color
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.0),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterMovies,
              style: TextStyle(color: Colors.white), // Text color for search
              decoration: InputDecoration(
                labelText: 'Search Movies',
                labelStyle: TextStyle(color: Colors.white), // Label color
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // Border color
                ),
                prefixIcon:
                    Icon(Icons.search, color: Colors.white), // Icon color
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.black, // Dark theme background color
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : filteredMovies.isEmpty
                    ? Center(
                        child: Text('No movies found',
                            style:
                                TextStyle(color: Colors.white))) // Text color
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        padding: EdgeInsets.all(8.0),
                        itemCount: filteredMovies.length,
                        itemBuilder: (context, index) {
                          var movie = filteredMovies[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 6.0,
                            color: Colors.grey[850], // Card background color
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: Image.network(
                                    movie['imageUrl'],
                                    fit: BoxFit.cover,
                                    height: 200,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                          child: Icon(Icons.error,
                                              color:
                                                  Colors.white)); // Icon color
                                    },
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.7),
                                        Colors.transparent
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          movie['title'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4.0),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    MovieDetailPage(
                                                  title: movie['title'],
                                                  imageUrl: movie['imageUrl'],
                                                  actors:
                                                      '', // You may want to fetch actors as well
                                                  detailUrl: movie['detailUrl'],
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors
                                                .blueGrey[800], // Button color
                                          ),
                                          child: Text(
                                            'View Details',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 1 ? _goToFirstPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800], // Button color
                  ),
                  child: Text('First Page'),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: currentPage > 1 ? _goToPreviousPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800], // Button color
                  ),
                  child: Text('Previous'),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: filteredMovies.isNotEmpty ? _goToNextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800], // Button color
                  ),
                  child: Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
