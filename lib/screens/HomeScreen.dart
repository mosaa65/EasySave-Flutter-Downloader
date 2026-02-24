import 'package:easysave3/services/VideoDownloaderPlas.dart';
import 'package:easysave3/services/VideoDownloaderpro.dart';
import 'package:flutter/material.dart';
import '../services/InstagramDownloader.dart';
import '../services/SnapchatDownloader.dart';
import '../services/VideoDownloaderbaisc.dart';
import '../services/ad_manager.dart';
import 'ActiveDownloadsPage.dart';
import 'DownloadedFilesPage.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/';   // ← أضف هذا

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  final AdManager _adManager = AdManager();
  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.video_library, 'label': 'YouTube'},
    {'icon': Icons.photo_camera, 'label': 'Instagram'},
    {'icon': Icons.star, 'label': 'Pro Download'},
    {'icon': Icons.snapchat, 'label': 'Snapchat'},
  ];

  final List<Map<String, dynamic>> services = [
    {
      'image': Icons.video_library,
      'name': 'YouTube Basic',
      'price': 'Free',
      'action': '_navigateToVideoDownloader',
    },
    {
      'image': Icons.video_library,
      'name': 'YouTube Pro',
      'price': 'Premium',
      'action': '_navigateToVideoDownloaderpro',
    },
    {
      'image': Icons.video_library,
      'name': 'YouTube plas',
      'price': 'Premium',
      'action': '_navigateToVideoDownloaderPlas',
    },
    {
      'image': Icons.video_library,
      'name': 'YouTube  🎗️',
      'price': 'Premium',
      'action': '_navigateToInstagramDownloader1',
    },
    {
      'image': Icons.photo_camera,
      'name': 'Instagram',
      'price': 'Free',
      'action': '_navigateToInstagramDownloader',
    },
    {
      'image': Icons.snapchat,
      'name': 'Snapchat',
      'price': 'Free',
      'action': '_navigateToSnapchatDownloader',
    },
  ];

  @override
  void initState() {
    super.initState();
    _adManager.initialize();
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }

  void _navigateToVideoDownloader() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoDownloader()),
    );
  }

  void _navigateToVideoDownloaderpro() {
    // تعرض إعلان ثم تنتقل
    _adManager.showInterstitialAd(() {
      // Navigator.pushNamed(context, DownloadPage.routeName);
    });
  }


  void _navigateToInstagramDownloader() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InstagramDownloader()),
    );
  }
  void _navigateToInstagramDownloader1() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoDownloaderPro()),
    );
  }
  void _navigateToInstagramDownloaderplas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoDownloaderPlas()),
    );
  }

  void _navigateToSnapchatDownloader() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SnapchatDownloader()),
    );
  }

  void _handleServiceAction(String action) {
    switch (action) {
      case '_navigateToVideoDownloader':
        _adManager.showInterstitialAd(_navigateToVideoDownloader);
        break;
      case '_navigateToVideoDownloaderpro':
        _adManager.showInterstitialAd(_navigateToVideoDownloaderpro);
        break;
      case '_navigateToInstagramDownloader1':
        _adManager.showInterstitialAd(_navigateToInstagramDownloader1);
        break;
      case '_navigateToVideoDownloaderPlas':
        _adManager.showInterstitialAd(_navigateToInstagramDownloaderplas);
        break;
      case '_navigateToInstagramDownloader':
        _navigateToInstagramDownloader();
        break;
      case '_navigateToSnapchatDownloader':
        _navigateToSnapchatDownloader();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(245, 249, 250, 1),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              SizedBox(height: 20),
              Text(
                "Download Services",
                style: TextStyle(fontSize: 24, fontFamily: 'PoetsenOne', fontWeight: FontWeight.bold,color: Colors.redAccent),
              ),
              SizedBox(height: 12),
              _buildCategoryChips(),
              SizedBox(height: 12),
              _buildPromoBanner(),
              SizedBox(height: 12),
              _adManager.topBanner,
              SizedBox(height: 12),
              _buildServiceGrid(),
              _adManager.bottomBanner,
            ],
          ),
        ),

      ),
      bottomNavigationBar: _buildElegantNavBar(),

    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.settings),
          color:Colors.teal.withOpacity(0.9),

          onPressed: () => AdManager.openSettings(context),
        ),
        CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage("assets/img.png"),
        )
      ],
    );
  }
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return GestureDetector(
            onTap: () => _handleServiceAction('_navigateTo${cat['label']}'),
            child: Container(
              margin: EdgeInsets.only(right: 10),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(cat['icon'], size: 16),
                  SizedBox(width: 6),
                  Text(
                    cat['label'],
                    style: TextStyle(
                      color:Colors.teal.withOpacity(0.9),
                      fontFamily: 'PoetsenOne',
                      fontSize: 14, // يمكنك تعديل حجم الخط حسب الحاجة
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget _buildPromoBanner() {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        image: DecorationImage(
          image: AssetImage("assets/banner.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        ),
      ),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.all(20),
      child: Text(
        "Discount 50%\nlearn more...",
        style: TextStyle(fontFamily: 'Pacifico',  fontSize: 16, color:Colors.teal.withOpacity(0.9)),
      ),
    );
  }

  Widget _buildServiceGrid() {
    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.only(top: 12),
        itemCount: services.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 4 / 3.5,
        ),
        itemBuilder: (context, index) {
          final service = services[index];
          return GestureDetector(
            onTap: () => _handleServiceAction(service['action']),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.star_border, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Icon(service['image'], size: 50,color:Colors.teal.withOpacity(0.9)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      service['name'],
                      style: TextStyle(fontWeight: FontWeight.bold,fontFamily: 'ElMessiri', ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(service['price']),
                        Row(
                          children: [
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildElegantNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.teal.withOpacity(0.9),
                Colors.greenAccent.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentNavIndex,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedIconTheme: IconThemeData(size: 30, color: Colors.white),
            unselectedIconTheme: IconThemeData(size: 24, color: Colors.white70),

            onTap: (index) {
              setState(() => _currentNavIndex = index);
              switch (index) {
                case 0:
                // Home - نفس الصفحة
                  break;
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DownloadedFilesPage()),
                  );
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ActiveDownloadsPage()),
                  );
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.save_outlined),
                label: 'محول',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.save_alt),
                label: 'الزوج',
              ),
            ],
          ),
        ),
      ),
    );
  }
}