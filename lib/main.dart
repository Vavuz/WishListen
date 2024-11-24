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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SearchPage(),
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSpotifyToken(); // Fetch token when the app starts
  }

  Future<void> _fetchSpotifyToken() async {
    setState(() {
      _isLoading = true;
    });

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('WishListen'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
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
            ] else ...[
              const Text('No results found.'),
            ],
          ],
        ),
      ),
    );
  }
}