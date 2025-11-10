import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:wish_listen/theme.dart';
import 'database_helper.dart';
import 'preferences_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wish_listen/generated/l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final isDark = await PreferencesHelper.getDarkMode();
  appThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'WishListen',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('it'), // Italian
            Locale('es'), // Spanish
          ],
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: mode,
          home: const MainPage(),
        );
      },
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
  bool isDarkModeEnabled = true;

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

  void _loadDarkMode() async {
    bool value = await PreferencesHelper.getDarkMode();
    setState(() {
      isDarkModeEnabled = value;
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
                    PopupMenuItem(
                        value: 'sort_name', child: Text(AppLocalizations.of(context)!.sortName)),
                    PopupMenuItem(
                        value: 'sort_artist', child: Text(AppLocalizations.of(context)!.sortArtist)),
                    PopupMenuItem(
                        value: 'sort_type', child: Text(AppLocalizations.of(context)!.sortType)),
                    PopupMenuItem(
                        value: 'filter_songs', child: Text(AppLocalizations.of(context)!.showSongs)),
                    PopupMenuItem(
                        value: 'filter_artists',
                        child: Text(AppLocalizations.of(context)!.showArtists)),
                    PopupMenuItem(
                        value: 'filter_albums',
                        child: Text(AppLocalizations.of(context)!.showAlbums)),
                    PopupMenuItem(
                        value: 'filter_all', child: Text(AppLocalizations.of(context)!.showAll)),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.search),
            Tab(text: AppLocalizations.of(context)!.myList),
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
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {
                Navigator.of(context).pop();
                _showSettingsDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(AppLocalizations.of(context)!.about),
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
    bool isDarkModeEnabled =
        await PreferencesHelper.getDarkMode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              title: Text(
                AppLocalizations.of(context)!.settings,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.askDeleteConfirmationSwitch,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.darkModeSwitch,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                          maxLines: null,
                        ),
                      ),
                      Switch(
                        value: isDarkModeEnabled,
                        onChanged: (bool newValue) async {
                          await PreferencesHelper.setDarkMode(newValue);
                          appThemeMode.value = newValue ? ThemeMode.dark : ThemeMode.light;
                          setState(() => isDarkModeEnabled = newValue);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Close',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: Text(
            AppLocalizations.of(context)!.aboutTitle,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          content: Text(AppLocalizations.of(context)!.aboutText,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14.0),
            textAlign: TextAlign.justify,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppLocalizations.of(context)!.close,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',    // test ad
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
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
    _bannerAd.dispose();
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
      SnackBar(
        content: Text(
          '${item['name']} ${AppLocalizations.of(context)!.added} ${AppLocalizations.of(context)!.myList}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              focusNode: widget.focusNode,
              onChanged: _searchSpotify,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16.0),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_hasSearched && _searchResults.isEmpty)
              Text(AppLocalizations.of(context)!.notFound)
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
                        color: Theme.of(context).cardColor,
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                  size: 40,
                                ),
                          title: Text(
                            item['name'],
                            style: Theme.of(context).textTheme.bodyLarge,
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
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              if (item['type'] == 'track' ||
                                  item['type'] == 'album')
                                Flexible(
                                  child: Text(
                                    '${AppLocalizations.of(context)!.by} ${item['artist']}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                      fontSize: 12.0,
                                    ),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                            onPressed: _myListIds.contains(item['id'])
                                ? null
                                : () async {
                                    await addToMyList(item);
                                    setState(() =>
                                        _myListIds.add(item['id']));
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
      ),
      bottomNavigationBar: _isBannerAdReady
          ? Container(
              alignment: Alignment.center,
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            )
          : null,
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
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)!.confirm),
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
    Widget buildFiltersHeader() {
      final hasFilter = _currentFilter != 'filter_all';
      final hasSort = _currentSort.isNotEmpty;

      if (!hasFilter && !hasSort) return const SizedBox.shrink();

      String filterLabel = '';
      if (hasFilter) {
        switch (_currentFilter) {
          case 'filter_track':
            filterLabel = 'Songs';
            break;
          case 'filter_artist':
            filterLabel = 'Artists';
            break;
          case 'filter_album':
            filterLabel = 'Albums';
            break;
        }
      }

      String sortLabel = '';
      if (hasSort) {
        switch (_currentSort) {
          case 'name':
            sortLabel = 'Name';
            break;
          case 'artist':
            sortLabel = 'Artist';
            break;
          case 'type':
            sortLabel = 'Type';
            break;
        }
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasFilter)
                Chip(
                  label: Text('${AppLocalizations.of(context)!.filter}: $filterLabel',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _currentFilter = 'filter_all';
                    });
                    _applyFiltersAndSorts();
                  },
                ),

              if (hasSort)
                Chip(
                  label: Text('${AppLocalizations.of(context)!.sort}: $sortLabel',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _currentSort = '';
                    });
                    _applyFiltersAndSorts();
                  },
                ),

              // Clear all button
              if (hasFilter || hasSort)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    setState(() {
                      _currentFilter = 'filter_all';
                      _currentSort = '';
                    });
                    _applyFiltersAndSorts();
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: Text(AppLocalizations.of(context)!.clear),
                ),
            ],
          ),
        ),
      );
    }

    if (_myList.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.emptyList,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        ),
      );
    }

    return ListView.builder(
      itemCount: _myList.length + 1, // +1 for the header row
      itemBuilder: (context, index) {
        if (index == 0) return buildFiltersHeader();

        final item = _myList[index - 1];

        final badgeColor = item['type'] == 'track'
            ? Colors.green[700]
            : item['type'] == 'album'
                ? Colors.blue[700]
                : Colors.amber[700];

        // Albums
        if (item['type'] == 'album') {
          final isExpanded = item['isExpanded'] == 1;

          return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12.0),
              color: Theme.of(context).cardColor,
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
                          : Icon(Icons.album,
                              size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                      title: Text(
                        item['name'],
                        style: Theme.of(context).textTheme.bodyLarge,
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
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Flexible(
                            child: Text(
                              '${AppLocalizations.of(context)!.by} ${item['artist']}',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12.0),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ]
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
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      onPressed: () async {
                              await _toggleAlbumExpanded(
                                  item['id'], !isExpanded);
                      },
                    ),
                    // Delete Icon
                    IconButton(
                            icon: Icon(Icons.delete,
                                color: Theme.of(context).colorScheme.error),
                      onPressed: () async {
                              final askConfirmation = await PreferencesHelper
                                  .getAskDeleteConfirmation();

                        if (askConfirmation) {
                          final confirmed = await _showConfirmationDialog(
                            '${AppLocalizations.of(context)!.delete} ${item['type']}',
                            '${AppLocalizations.of(context)!.askDeleteConfirmation} ${item['type']}?',
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
            color: Theme.of(context).cardColor,
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      size: 40,
                    ),
                    title: Text(
                      item['name'],
                      style: Theme.of(context).textTheme.bodyLarge,
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
                            style: TextStyle(
                              fontSize: 10.0,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  if (item['type'] == 'track' || item['type'] == 'album')
                    Flexible(
                      child: Text(
                        '${AppLocalizations.of(context)!.by} ${item['artist']}',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12.0),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
              trailing: item['parentId'] == null
                  ? IconButton(
                            icon: Icon(Icons.delete,
                                color: Theme.of(context).colorScheme.error),
                      onPressed: () async {
                              final askConfirmation = await PreferencesHelper
                                  .getAskDeleteConfirmation();

                        if (askConfirmation) {
                          final confirmed = await _showConfirmationDialog(
                            '${AppLocalizations.of(context)!.delete} ${item['type']}',
                            '${AppLocalizations.of(context)!.askDeleteConfirmation} ${item['type']}?',
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
                          final updated =
                              Map<String, dynamic>.from(item)..['isChecked'] = newVal ? 1 : 0;
                          _myList[index - 1] = updated; // adjust for header

                          final idx = _originalList.indexWhere((e) => e['id'] == item['id']);
                          if (idx != -1) {
                                _originalList[idx] = Map<String, dynamic>.from(_originalList[idx])
                                  ..['isChecked'] = newVal ? 1 : 0;
                          }
                        });
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}