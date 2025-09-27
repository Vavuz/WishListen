import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'preferences_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
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

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FocusNode _searchFocusNode = FocusNode();
  bool isAskConfirmationEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index != 0) {
        _searchFocusNode.unfocus();
      }
    });

    _loadAskDeleteConfirmation();
  }

  void _loadAskDeleteConfirmation() async {
    bool value = await PreferencesHelper.getAskDeleteConfirmation();
    setState(() {
      isAskConfirmationEnabled = value;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showOptionsDialog(context);
          },
        ),
        title: const Text('WishListen'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 1) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    MyListPage.menuCallback?.call(value);
                  },
                  icon: const Icon(Icons.filter_list),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'sort_name', child: Text('Sort by Name')),
                    const PopupMenuItem(
                        value: 'sort_artist', child: Text('Sort by Artist')),
                    const PopupMenuItem(
                        value: 'sort_type', child: Text('Sort by Type')),
                    const PopupMenuItem(
                        value: 'filter_songs', child: Text('Show Only Songs')),
                    const PopupMenuItem(
                        value: 'filter_artists',
                        child: Text('Show Only Artists')),
                    const PopupMenuItem(
                        value: 'filter_albums',
                        child: Text('Show Only Albums')),
                    const PopupMenuItem(
                        value: 'filter_all', child: Text('Show All')),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Search'),
            Tab(text: 'My List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SearchPage(focusNode: _searchFocusNode),
          const MyListPage(),
        ],
      ),
    );
  }

  void _showOptionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                _showSettingsDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.of(context).pop();
                _showAboutDialog(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    bool isAskConfirmationEnabled =
        await PreferencesHelper.getAskDeleteConfirmation();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF191414),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Ask for confirmation before deleting an item',
                          style: TextStyle(color: Colors.white70),
                          maxLines: null,
                        ),
                      ),
                      Switch(
                        value: isAskConfirmationEnabled,
                        onChanged: (bool newValue) async {
                          await PreferencesHelper.setAskDeleteConfirmation(
                              newValue);
                          setState(() {
                            isAskConfirmationEnabled = newValue;
                          });
                        },
                        activeColor: const Color(0xFF1DB954),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Color(0xFF1DB954)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191414),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: const Text(
            'About WishListen',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Hi from Vavuz, the developer of WishListen!\n\n'
            'I hope you enjoy this app. Here’s how to use it:\n'
            '- Search for songs, albums, or artists in the Search tab.\n'
            '- Add them to your list by clicking the "+" icon.\n'
            '- Manage your list in the My List tab using filters and sorting options.\n\n'
            'If the search doesn’t work, give it a minute for the keys to be fetched.\n\n'
            'Thanks for trying WishListen!',
            style: TextStyle(color: Colors.white70, fontSize: 14.0),
            textAlign: TextAlign.left,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF1DB954)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SearchPage extends StatefulWidget {
  final FocusNode focusNode;

  const SearchPage({super.key, required this.focusNode});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? _accessToken;
  List<dynamic> _searchResults = [];
  Set<String> _myListIds = {};
  bool _isLoading = false;
  bool _hasSearched = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSpotifyToken();
    _loadMyListIds();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.focusNode.requestFocus();
    });
  }

  Future<void> _loadMyListIds() async {
    final dbHelper = DatabaseHelper();
    final items = await dbHelper.getItems();
    setState(() {
      _myListIds = items.map((item) => item['id'] as String).toSet();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      // _showError('Spotify token not available. Try again later.');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/search?q=$query&type=track,artist,album&limit=10'),
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
                'image': album['images'].isNotEmpty
                    ? album['images'][0]['url']
                    : null,
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
                'artist': artist['name'],
                'image': artist['images'].isNotEmpty
                    ? artist['images'][0]['url']
                    : null,
              });
            }
          }
        });
      } else {
        // _showError('Failed to search Spotify.');
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
            focusNode: widget.focusNode,
            onChanged: _searchSpotify,
            decoration: InputDecoration(
              hintText: 'Search for artists, songs, or albums',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16.0),
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_hasSearched && _searchResults.isEmpty)
            const Text('No results found.')
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];

                  final badgeColor = item['type'] == 'track'
                      ? Colors.green[700]
                      : item['type'] == 'album'
                          ? Colors.blue[700]
                          : Colors.amber[700];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(
                          item['type'] == 'artist' ? 50.0 : 12.0),
                      child: ListTile(
                        leading: item['image'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  item['type'] == 'artist'
                                      ? 50.0
                                      : (item['type'] == 'album' ? 12.0 : 0.0),
                                ),
                                child: Image.network(
                                  item['image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                item['type'] == 'track'
                                    ? Icons.music_note
                                    : item['type'] == 'artist'
                                        ? Icons.person
                                        : Icons.album,
                                color: Colors.white70,
                                size: 40,
                              ),
                        title: Text(
                          item['name'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                item['type'].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            if (item['type'] == 'track' ||
                                item['type'] == 'album')
                              Flexible(
                                child: Text(
                                  'by ${item['artist']}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12.0),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            _myListIds.contains(item['id'])
                                ? Icons.check
                                : Icons.add,
                            color: Colors.white,
                          ),
                          onPressed: _myListIds.contains(item['id'])
                              ? null // Disable the button if already added
                              : () async {
                                  await addToMyList(item);
                                  setState(() => _myListIds.add(item[
                                      'id']));
                                },
                        ),
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

class MyListPage extends StatefulWidget {
  const MyListPage({super.key});

  static Function(String)? menuCallback;

  @override
  State<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends State<MyListPage> {
  List<Map<String, dynamic>> _originalList = [];
  List<Map<String, dynamic>> _myList = [];
  List<Map<String, dynamic>> _allTracks = [];
  String _currentFilter = 'filter_all';
  String _currentSort = '';

  @override
  void initState() {
    super.initState();
    _loadMyList();
    MyListPage.menuCallback = _handleMenuSelection;
  }

  @override
  void dispose() {
    MyListPage.menuCallback = null;
    super.dispose();
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'sort_name':
        _currentSort = 'name';
        break;
      case 'sort_artist':
        _currentSort = 'artist';
        break;
      case 'sort_type':
        _currentSort = 'type';
        break;
      case 'filter_songs':
        _currentFilter = 'filter_track';
        break;
      case 'filter_artists':
        _currentFilter = 'filter_artist';
        break;
      case 'filter_albums':
        _currentFilter = 'filter_album';
        break;
      case 'filter_all':
        _currentFilter = 'filter_all';
        break;
    }

    _applyFiltersAndSorts();
  }

  void _sortListBy(String field) {
    setState(() {
      _currentSort = field;
      _myList.sort((a, b) {
        final aValue = (a[field] ?? '').toString().toLowerCase();
        final bValue = (b[field] ?? '').toString().toLowerCase();
        return aValue.compareTo(bValue);
      });
    });
  }

  void _applyFiltersAndSorts() {
    setState(() {
      _myList = List.from(_originalList);

      final noFilter = _currentFilter.isEmpty || _currentFilter == 'filter_all';

      if (!noFilter) {
        if (_currentFilter == 'filter_track') {
          _myList = List.from(_allTracks);
        } else {
        final filterType = _currentFilter.replaceFirst('filter_', '');
        _myList = _myList.where((item) => item['type'] == filterType).toList();
        }
      }

      if (_currentSort.isNotEmpty) {
        _sortListBy(_currentSort);
      }
    });
  }

  Future<void> _loadMyList() async {
    final dbHelper = DatabaseHelper();
    final items = await dbHelper.getItems();
    List<Map<String, dynamic>> newList = [];

    // Reverse the items list to display the most recently added first
    final reversedItems = items.reversed.toList();

    _allTracks = reversedItems.where((it) => it['type'] == 'track').toList();
    final songs = reversedItems.where((item) => item['type'] == 'track').toList();

    for (var item in reversedItems) {
      if (item['type'] == 'album') {
        newList.add(item);
        if (item['isExpanded'] == 1) {
          final albumSongs =
              songs.where((song) => song['parentId'] == item['id']).toList();
          newList.addAll(albumSongs);
        }
      } else if (item['parentId'] == null) {
        newList.add(item);
      }
    }

    setState(() {
      _originalList = List.from(newList); // Save the unfiltered, unsorted list
      _myList = List.from(_originalList);

      // Apply current filter and sort
      _applyFiltersAndSorts();
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
        ) ??
        false;
  }

  Future<void> _toggleAlbumExpanded(String albumId, bool isExpanded) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateItemExpanded(albumId, isExpanded);
    await _loadMyList();
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

              final badgeColor = item['type'] == 'track'
                  ? Colors.green[700]
                  : item['type'] == 'album'
                      ? const Color.fromARGB(255, 15, 19, 22)
                      : Colors.amber[700];

              if (item['type'] == 'album') {
                final isExpanded = item['isExpanded'] == 1;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12.0),
                    child: ListTile(
                      leading: item['image'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.network(
                                item['image'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.album,
                              size: 40, color: Colors.white70),
                      title: Text(
                        item['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'by ${item['artist']}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Expand/Collapse Icon
                          IconButton(
                            icon: Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              await _toggleAlbumExpanded(
                                  item['id'], !isExpanded);
                            },
                          ),
                          // Delete Icon
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Color.fromARGB(255, 211, 22, 8)),
                            onPressed: () async {
                              final askConfirmation = await PreferencesHelper
                                  .getAskDeleteConfirmation();

                              if (askConfirmation) {
                                final confirmed = await _showConfirmationDialog(
                                  'Delete Album',
                                  'Are you sure you want to delete this album?',
                                );
                                if (confirmed) {
                                  _deleteItem(item['id'], item['type']);
                                }
                              } else {
                                _deleteItem(item['id'], item['type']);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

        // Tracks / artists
        final bool songsOnly = _currentFilter == 'filter_track';
              return Padding(
                padding: EdgeInsets.only(
            left: songsOnly
                ? 8.0
                : (item['parentId'] != null ? 32.0 : 8.0),
                  right: 8.0,
                  top: 4.0,
                  bottom: 4.0,
                ),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(
                      item['type'] == 'artist' ? 50.0 : 12.0),
                  child: ListTile(
                    leading: item['image'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              item['type'] == 'artist'
                                  ? 50.0
                                  : (item['type'] == 'album' ? 12.0 : 0.0),
                            ),
                            child: Image.network(
                              item['image'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            item['type'] == 'track'
                                ? Icons.music_note
                                : item['type'] == 'artist'
                                    ? Icons.person
                                    : Icons.album,
                            color: Colors.white70,
                            size: 40,
                          ),
                    title: Text(
                      item['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            item['type'].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        if (item['type'] == 'track' || item['type'] == 'album')
                          Flexible(
                            child: Text(
                              'by ${item['artist']}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12.0),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                      ],
                    ),
                    trailing: item['parentId'] == null
                        ? IconButton(
                            icon: const Icon(Icons.delete,
                                color: Color.fromARGB(255, 211, 22, 8)),
                            onPressed: () async {
                              final askConfirmation = await PreferencesHelper
                                  .getAskDeleteConfirmation();

                              if (askConfirmation) {
                                final confirmed = await _showConfirmationDialog(
                                  'Delete ${item['type']}',
                                  'Are you sure you want to delete this ${item['type']}?',
                                );
                                if (confirmed) {
                                  _deleteItem(item['id'], item['type']);
                                }
                              } else {
                                _deleteItem(item['id'], item['type']);
                              }
                            },
                          )
                        : Checkbox(
                          value: (item['isChecked'] ?? 0) == 1,
                          onChanged: (v) async {
                            final newVal = v ?? false;
                            await DatabaseHelper().updateItemChecked(item['id'], newVal);

                            setState(() {
                              final updated = Map<String, dynamic>.from(item)..['isChecked'] = newVal ? 1 : 0;
                              _myList[index] = updated;

                              final idx = _originalList.indexWhere((e) => e['id'] == item['id']);
                              if (idx != -1) {
                                _originalList[idx] = Map<String, dynamic>.from(_originalList[idx])
                                  ..['isChecked'] = newVal ? 1 : 0;
                              }
                            });
                          },
                        )
                  ),
                ),
              );
            },
          );
  }
}