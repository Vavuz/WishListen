import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';

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
      final tokenResponse = await http.get(
        Uri.parse('https://wishlistenbackend.onrender.com/get-spotify-token'),
        headers: {
          'x-api-key': 'follettifollettisiamdeigeniperfetti',
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = json.decode(tokenResponse.body);
        setState(() {
          _accessToken = tokenData['accessToken'];
        });
      } else {
        _showError('Failed to fetch Spotify token.');
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
          if (data['tracks'] != null && data['tracks']['items'] != null) {
            for (var track in data['tracks']['items']) {
              _searchResults.add({
                'id': track['id'],
                'type': 'track',
                'name': track['name'],
                'artist': track['artists'][0]['name'],
                'image': track['album']['images'].isNotEmpty
                    ? track['album']['images'][0]['url']
                    : null,
              });
            }
          }

          // Parse albums
          if (data['albums'] != null && data['albums']['items'] != null) {
            for (var album in data['albums']['items']) {
              _searchResults.add({
                'id': album['id'],
                'type': 'album',
                'name': album['name'],
                'artist': album['artists'][0]['name'],
                'image': album['images'].isNotEmpty ? album['images'][0]['url'] : null,
              });
            }
          }

          // Parse artists
          if (data['artists'] != null && data['artists']['items'] != null) {
            for (var artist in data['artists']['items']) {
              _searchResults.add({
                'id': artist['id'],
                'type': 'artist',
                'name': artist['name'],
                'artist': 'Artist',
                'image': artist['images'].isNotEmpty ? artist['images'][0]['url'] : null,
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

  Future<void> addToMyList(Map<String, dynamic> item) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.insertItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} added to My List')),
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
            onSubmitted: _searchSpotify,
          ),
          const SizedBox(height: 16.0),
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_hasSearched && _searchResults.isEmpty)
            const Text('No results found.')
          else if (_searchResults.isNotEmpty)
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
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => addToMyList(item),
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

class MyListPage extends StatefulWidget {
  const MyListPage({super.key});

  @override
  State<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends State<MyListPage> {
  List<Map<String, dynamic>> _myList = [];

  @override
  void initState() {
    super.initState();
    _loadMyList();
  }

  Future<void> _loadMyList() async {
    final dbHelper = DatabaseHelper();
    final items = await dbHelper.getItems();
    setState(() {
      _myList = items;
    });
  }

  Future<void> _deleteItem(String id) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteItem(id);
    _loadMyList();
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  ) ?? false;
}

@override
Widget build(BuildContext context) {
  return _myList.isEmpty
      ? const Center(
          child: Text(
            'No items in your list.',
            style: TextStyle(color: Colors.white70),
          ),
        )
      : ListView.builder(
          itemCount: _myList.length,
          itemBuilder: (context, index) {
            final item = _myList[index];
            return ListTile(
              leading: item['image'] != null
                  ? Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.music_note),
              title: Text(
                item['name'],
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                item['type'].toUpperCase(),
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Checkbox(
                value: false,
                onChanged: (value) async {
                  if (value == true) {
                    final confirmed = await _showConfirmationDialog(
                      'Delete Item',
                      'Are you sure you want to delete this item?',
                    );
                    if (confirmed) {
                      _deleteItem(item['id']);
                    }
                  }
                },
              ),
            );
          },
        );
  }
}