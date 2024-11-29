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

    // If it's an album, fetch and add its songs
    if (item['type'] == 'album') {
      final albumId = item['id'];
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/albums/$albumId/tracks'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final songs = data['items'] as List<dynamic>;

        for (var song in songs) {
          final songItem = {
            'id': song['id'],
            'type': 'track',
            'name': song['name'],
            'artist': song['artists'][0]['name'],
            'image': item['image'],
            'parentId': albumId,
          };

          await dbHelper.insertItem(songItem);
        }
      }
    }

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
                        ? Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover)
                        : Icon(
                            item['type'] == 'track'
                                ? Icons.music_note
                                : item['type'] == 'artist'
                                    ? Icons.person
                                    : Icons.album,
                            color: Colors.white70,
                          ),
                    title: Text(
                      item['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Row(
                      children: [
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            item['type'].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.0,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        if (item['type'] == 'track' || item['type'] == 'album')
                          Flexible(
                            child: Text(
                              'by ${item['artist']}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12.0),
                              overflow: TextOverflow.ellipsis, // Truncate overflow text
                              maxLines: 1,
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
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

    final albums = items.where((item) => item['type'] == 'album').toList();
    final songs = items.where((item) => item['type'] == 'track').toList();

    // Build the new list
    List<Map<String, dynamic>> newList = [];
    for (var album in albums) {
      newList.add(album);
      final albumSongs = songs.where((song) => song['parentId'] == album['id']).toList();
      newList.addAll(albumSongs);
    }

    newList.addAll(items.where((item) => item['type'] != 'album' && item['parentId'] == null));

    setState(() {
      _myList = newList;
    });
  }

  Future<void> _deleteItem(String id, String type) async {
    final dbHelper = DatabaseHelper();

    if (type == 'album') {
      // Delete album and associated songs
      await dbHelper.deleteItem(id);
      await dbHelper.deleteItemsByParentId(id);
    } else {
      // Delete individual item
    await dbHelper.deleteItem(id);
    }

    await _loadMyList();
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
            return Padding(
              padding: EdgeInsets.only(left: item['parentId'] != null ? 32.0 : 0.0), // Indent songs
              child: ListTile(
                leading: item['image'] != null
                    ? Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover)
                    : Icon(
                        item['type'] == 'track'
                            ? Icons.music_note
                            : item['type'] == 'artist'
                                ? Icons.person
                                : Icons.album,
                        color: Colors.white70,
                      ),
                title: Text(
                  item['name'],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        item['type'].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10.0,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    if (item['type'] == 'track' || item['type'] == 'album')
                      Flexible(
                        child: Text(
                          'by ${item['artist']}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12.0),
                          overflow: TextOverflow.ellipsis, // Truncate overflow text
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
                trailing: item['parentId'] == null
                    ? IconButton( // Show bin icon for standalone items
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await _showConfirmationDialog(
                            'Delete ${item['type']}',
                            'Are you sure you want to delete this ${item['type']}?',
                          );
                          if (confirmed) {
                            _deleteItem(item['id'], item['type']);
                          }
                        },
                      )
                    : Checkbox( // Show checkbox for songs inside albums
                        value: false, // Placeholder for now
                        onChanged: (value) async {
                          _deleteItem(item['id'], item['type']);
                        },
                      ),
              ),
            );
          },
        );
  }
}