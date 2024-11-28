import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WishListen',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF191414),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          secondary: Color(0xFF1DB954),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          bodySmall: TextStyle(color: Colors.white54),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF191414),
          foregroundColor: Colors.white,
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF1DB954), width: 2),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFF1DB954)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1DB954), width: 2),
          ),
          hintStyle: const TextStyle(color: Colors.white54),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WishListen'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Search'),
              Tab(text: 'My List'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SearchPage(),
            MyListPage(),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? _accessToken;
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSpotifyToken();
  }

  Future<void> _fetchSpotifyToken() async {
    try {
      // Fetch token
      final tokenResponse = await http.get(
        Uri.parse('https://wishlistenbackend.onrender.com/get-spotify-token'),
        headers: {
          'x-api-key': 'follettifollettisiamdeigeniperfetti',
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = json.decode(tokenResponse.body);

        setState(() {
          _accessToken = tokenData['accessToken']; // Extract token from response
        });
      } else {
        _showError(
          'Failed to fetch Spotify token: ${tokenResponse.statusCode} - ${tokenResponse.body}',
        );
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchSpotify(String query) async {
  if (_accessToken == null) {
    _showError('Spotify token not available. Try again later.');
    return;
  }

  setState(() {
    _isLoading = true;
    _hasSearched = true;
  });

  try {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/search?q=$query&type=track,artist,album&limit=10'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        _searchResults = [];
        // Parse tracks
        if (data['tracks'] != null) {
          for (var track in data['tracks']['items']) {
            _searchResults.add({
              'type': 'track',
              'name': track['name'],
              'artist': track['artists'][0]['name'],
              'image': track['album']['images'][0]['url'],
            });
          }
        }
        // Parse albums
        if (data['albums'] != null) {
          for (var album in data['albums']['items']) {
            _searchResults.add({
              'type': 'album',
              'name': album['name'],
              'artist': album['artists'][0]['name'],
              'image': album['images'][0]['url'],
            });
          }
        }
        // Parse artists
        if (data['artists'] != null) {
          for (var artist in data['artists']['items']) {
            _searchResults.add({
              'type': 'artist',
              'name': artist['name'],
              'artist': 'Artist',
              'image': artist['images'].isNotEmpty ? artist['images'][0]['url'] : null, // Artist image
            });
          }
        }
      });
    } else {
      _showError('Failed to search Spotify.');
    }
  } catch (e) {
    _showError('An error occurred: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for artists, songs, or albums',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              prefixIcon: const Icon(Icons.search),
            ),
            onSubmitted: _searchSpotify, // Triggers search
          ),
          const SizedBox(height: 16.0),
          if (_isLoading) ...[
            const CircularProgressIndicator(),
          ] else if (_hasSearched && _searchResults.isEmpty) ...[
            const Text('No results found.'),
          ] else if (_searchResults.isNotEmpty) ...[
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return ListTile(
                    leading: item['image'] != null
                        ? Image.network(
                            item['image'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.music_note),
                    title: Text(item['name'] ?? 'Unknown'),
                    subtitle: Text(item['artist'] ?? 'Unknown Artist'),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MyListPage extends StatelessWidget {
  const MyListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Hello'),
    );
  }
}