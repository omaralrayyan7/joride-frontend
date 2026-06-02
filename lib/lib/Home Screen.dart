import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

// استيراد الصفحات الخاصة بالمشروع
import 'CarDetailsScreen.dart';
import 'ProfileScreen.dart';
import 'SettingsScreen.dart';
import 'WalletScreen.dart';
import 'MyReservationsScreen.dart';
import 'DigitalKeyScreen.dart';
import 'NotificationsScreen.dart';
import 'AdminDashboardScreen.dart';
import 'l10n/app_localizations.dart';
import 'login_screen.dart';
import 'widgets/car_image.dart';
import 'models/vehicle_model.dart';
import 'models/auth_models.dart';
import 'services/api_service.dart';

class HomeScreen extends StatefulWidget {
  // استقبال بيانات الحجز عند العودة من صفحة الدفع
  final Map<String, dynamic>? bookedCar;
  final int initialIndex;
  final int? bookingDuration; // المدة (مثلاً 15)
  final String? bookingType;   // النوع (min, hour, day)
  final String? tripId;        // معرّف الرحلة في الـ backend

  const HomeScreen({
    super.key,
    this.bookedCar,
    this.initialIndex = 0,
    this.bookingDuration,
    this.bookingType,
    this.tripId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color joRideAccent = Color(0xFF13366B);
  static const Color scaffoldBg = Color(0xFFF8F9FD);

  late int _currentNavIndex;
  Map<String, dynamic>? _currentBookedCar;
  String? _currentTripId;
  int? _currentBookingDuration;
  String? _currentBookingType;

  // مفتاح الـ Scaffold للتحكم في الـ Drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // بيانات المستخدم للـ Drawer
  String _drawerUserName = 'Guest';
  String _drawerUserEmail = '';
  bool _isAdmin = false;

  // عدد الإشعارات غير المقروءة
  int _unreadCount = 0;

  // لوحة الإشعارات المنسدلة
  bool _notifPanelOpen = false;
  List<AppNotification> _notifList = [];

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(32.0252, 35.8850),
    zoom: 14.5,
  );

  String selectedCategory = "All";
  Map<String, dynamic>? activeCar;

  final PageController _adController = PageController();
  final List<String> ads = [
    "PROMO: Get 20% off your first ride!",
    "New SUV Fleet available in Amman!",
    "Eco-Friendly? Try our new Electric cars.",
    "Rent by hour and save more with joRide."
  ];
  int _currentAdIndex = 0;
  late Timer _adTimer;

  List<Map<String, dynamic>> _vehicles = [];
  bool _vehiclesLoading = true;
  String? _vehiclesError;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialIndex;
    _currentBookedCar = widget.bookedCar;
    _currentTripId = widget.tripId;
    _currentBookingDuration = widget.bookingDuration;
    _currentBookingType = widget.bookingType;
    _restoreActiveRental();
    _loadVehicles();
    _loadUserInfo();
    _loadUnreadCount();

    _adTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_adController.hasClients) {
        _currentAdIndex++;
        if (_currentAdIndex >= ads.length) _currentAdIndex = 0;
        _adController.animateToPage(
          _currentAdIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }


  Future<void> _restoreActiveRental() async {
    final saved = await ApiService.getSavedActiveRental();
    if (saved == null || !mounted) return;
    try {
      setState(() {
        _currentBookedCar = Map<String, dynamic>.from(saved['car'] as Map);
        _currentTripId = saved['tripId']?.toString();
        _currentBookingDuration = (saved['duration'] as num?)?.toInt();
        _currentBookingType = saved['durationType'] as String?;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _adTimer.cancel();
    _adController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final name = await ApiService.getUserName();
    final email = await ApiService.getUserEmail();
    final isAdmin = await ApiService.getIsAdmin();
    if (mounted) {
      setState(() {
        _drawerUserName = name ?? 'Guest';
        _drawerUserEmail = email ?? '';
        _isAdmin = isAdmin;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await ApiService.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // نتجاهل الخطأ — الـ badge لن يظهر
    }
  }

  Future<void> _loadVehicles() async {
    setState(() { _vehiclesLoading = true; _vehiclesError = null; });
    try {
      final list = await ApiService.getAvailableVehicles();
      if (mounted) setState(() => _vehicles = list.map((v) => v.toMap()).toList());
    } catch (e) {
      if (mounted) setState(() => _vehiclesError = e.toString());
    } finally {
      if (mounted) setState(() => _vehiclesLoading = false);
    }
  }

  List<Map<String, dynamic>> _filterCars(List<Map<String, dynamic>> cars) {
    if (selectedCategory == "All") return cars;
    return cars.where((c) => c['category'] == selectedCategory).toList();
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    // إعادة تحميل عدد الإشعارات بعد العودة
    _loadUnreadCount();
  }

  Future<void> _toggleNotifPanel() async {
    if (!_notifPanelOpen) {
      try {
        final list = await ApiService.getNotifications();
        if (mounted) {
          setState(() {
            _notifList = list;
            _notifPanelOpen = true;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _notifPanelOpen = true);
      }
    } else {
      setState(() => _notifPanelOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyPage = _currentNavIndex == 2;

    final List<Widget> pages = [
      _buildMainMapStack(),          // Index 0
      MyReservationsScreen(          // Index 1 (ممرر له بيانات العد التنازلي)
        bookedCar: _currentBookedCar,
        duration: _currentBookingDuration,
        type: _currentBookingType,
        tripId: _currentTripId,
      ),
      DigitalKeyScreen(              // Index 2
        car: _currentBookedCar,
        tripId: _currentTripId,
      ),
      const WalletScreen(),         // Index 3
      const SettingsScreen(),       // Index 4
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scaffoldBg,
      drawer: isKeyPage ? null : _buildDrawer(),
      appBar: isKeyPage ? null : _buildAppBar(),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentNavIndex,
            children: pages,
          ),
          if (_notifPanelOpen) _buildNotifPanel(),
        ],
      ),
      bottomNavigationBar: isKeyPage ? null : _buildBottomNav(),
    );
  }

  // ─── Drawer ───────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    final l            = AppLocalizations.of(context);
    final colorScheme  = Theme.of(context).colorScheme;
    final onBackground = colorScheme.onSurface;

    return Drawer(
      child: Column(
        children: [
          // ── Profile header ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [joRideAccent, Color(0xFF2A5298)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white24,
                  child: Image.asset(
                    'assets/logo_icon.png',
                    height: 38,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _drawerUserName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                if (_drawerUserEmail.isNotEmpty)
                  Text(
                    _drawerUserEmail,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),

          // ── Nav items ──────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _navItem(Icons.map_rounded, l.t('map'), 0, onBackground),
                _navItem(Icons.event_note_rounded, l.t('reservations'), 1, onBackground),
                _navItem(Icons.vpn_key_rounded, l.t('your_key'), 2, onBackground),
                _navItem(Icons.wallet_rounded, l.t('wallet'), 3, onBackground),
                _drawerItem(
                  icon: Icons.notifications_none_rounded,
                  label: l.t('notifications'),
                  color: onBackground,
                  onTap: () { Navigator.pop(context); _openNotifications(); },
                ),
                _navItem(Icons.settings_rounded, l.t('settings'), 4, onBackground),

                if (_isAdmin) ...[
                  const Divider(indent: 16, endIndent: 16),
                  _drawerItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: l.t('admin_dashboard'),
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const AdminDashboardScreen()));
                    },
                  ),
                ],

                const Divider(indent: 16, endIndent: 16),
                _drawerItem(
                  icon: Icons.logout,
                  label: l.t('logout'),
                  color: Colors.red,
                  onTap: () { Navigator.pop(context); _logout(); },
                ),
              ],
            ),
          ),

          // ── Version footer ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'joRide v1.1.0',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Nav item that highlights when the corresponding tab is active.
  Widget _navItem(IconData icon, String label, int index, Color defaultColor) {
    final selected = _currentNavIndex == index;
    final color    = selected
        ? Theme.of(context).colorScheme.primary
        : defaultColor;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500)),
      selected: selected,
      selectedTileColor:
          Theme.of(context).colorScheme.primary.withAlpha(30),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pop(context);
        setState(() => _currentNavIndex = index);
      },
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu,
            color: Theme.of(context).colorScheme.primary),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      // Tapping the logo always returns to the map tab (index 0)
      title: GestureDetector(
        onTap: () => setState(() => _currentNavIndex = 0),
        child: Image.asset(
          'assets/logo_icon.png',
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'joRide',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        // بادج الإشعارات
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none,
                  color: Theme.of(context).colorScheme.primary),
              onPressed: _toggleNotifPanel,
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.account_circle_outlined,
              color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
        ),
        const SizedBox(width: 5),
      ],
    );
  }

  /// Returns localised label for a vehicle category chip.
  String _catLabel(BuildContext context, String cat) {
    final l = AppLocalizations.of(context);
    switch (cat) {
      case 'All':      return l.t('cat_all');
      case 'Economy':  return l.t('cat_economy');
      case 'Luxury':   return l.t('cat_luxury');
      case 'SUV':      return l.t('cat_suv');
      case 'Electric': return l.t('cat_electric');
      default:         return cat;
    }
  }

  Widget _buildTopSearchAndFilter() {
    final cs    = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF2A2A3E) : Colors.white;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: ['All', 'Economy', 'Luxury', 'SUV', 'Electric'].map((cat) {
          final isSel = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_catLabel(context, cat)),
              selected: isSel,
              onSelected: (_) => setState(() => selectedCategory = cat),
              selectedColor: joRideAccent,
              labelStyle: TextStyle(
                  color: isSel ? Colors.white : cs.onSurface),
              backgroundColor: chipBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainMapStack() {
    final filtered = _filterCars(_vehicles);

    return Column(
      children: [
        _buildTopSearchAndFilter(),
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 20)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: GoogleMap(
                    initialCameraPosition: _initialPosition,
                    markers: _buildMarkers(filtered),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    onTap: (_) => setState(() => activeCar = null),
                  ),
                ),
              ),
              // Loading spinner overlay
              if (_vehiclesLoading)
                const Positioned(
                  top: 20,
                  right: 30,
                  child:
                      CircularProgressIndicator(strokeWidth: 2),
                ),
              // Error badge — map still visible, small notice at top
              if (_vehiclesError != null && !_vehiclesLoading)
                Positioned(
                  top: 20,
                  left: 30,
                  right: 30,
                  child: GestureDetector(
                    onTap: _loadVehicles,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Backend offline — tap to retry',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                          Icon(Icons.refresh,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildAdBanner(),
        if (activeCar != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildQuickInfoCard(),
          ),
      ],
    );
  }

  Widget _buildAdBanner() {
    return Container(
      height: 50,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [joRideAccent, Color(0xFF2A5298)]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Icon(Icons.campaign, color: Colors.amber, size: 22),
          ),
          Expanded(
            child: PageView.builder(
              controller: _adController,
              onPageChanged: (index) => _currentAdIndex = index,
              itemCount: ads.length,
              itemBuilder: (context, index) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Text(
                      ads[index],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildQuickInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15), blurRadius: 15)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _badge("Color: ${activeCar!['color']}"),
              _badge("Fuel: ${activeCar!['fuel']}%"),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              CarImage(car: activeCar!, height: 60, width: 80),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activeCar!['model'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Plate: ${activeCar!['plate']}",
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _priceColumn("Minute", "${activeCar!['rates']['min']}"),
              _priceColumn("Hour", "${activeCar!['rates']['hour']}"),
              _priceColumn("Day", "${activeCar!['rates']['day']}"),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: joRideAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CarDetailsScreen(car: activeCar!)),
            ),
            child: const Text(
              "Book Now",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _priceColumn(String title, String price) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text("$price JOD",
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: joRideAccent)),
      ],
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: joRideAccent)),
    );
  }

  Set<Marker> _buildMarkers(List<Map<String, dynamic>> cars) {
    return cars.map((c) {
      return Marker(
        markerId: MarkerId(c['id']),
        position: c['pos'],
        onTap: () => setState(() => activeCar = c),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
      );
    }).toSet();
  }

  // ─── Notification Panel ───────────────────────────────────────────────────

  Widget _buildNotifPanel() {
    return Stack(
      children: [
        // Full-screen transparent overlay — tap anywhere outside panel to close
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _notifPanelOpen = false),
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {}, // Absorb taps inside panel (don't close)
              child: Material(
                elevation: 8,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                color: Theme.of(context).colorScheme.surface,
                child: Container(
                  width: 340,
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF131A2D),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await ApiService.markAllNotificationsRead();
                                _loadUnreadCount();
                                if (mounted) {
                                  setState(() {
                                    _notifList = _notifList
                                        .map((n) => AppNotification(
                                              id: n.id,
                                              userId: n.userId,
                                              title: n.title,
                                              body: n.body,
                                              type: n.type,
                                              isRead: true,
                                              createdAt: n.createdAt,
                                            ))
                                        .toList();
                                  });
                                }
                              },
                              child: const Text('Mark all',
                                  style: TextStyle(
                                      color: joRideAccent, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // List
                      if (_notifList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No notifications',
                              style: TextStyle(color: Colors.grey)),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount:
                                _notifList.length > 5 ? 5 : _notifList.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 16),
                            itemBuilder: (ctx, i) {
                              final n = _notifList[i];
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: n.isRead
                                        ? Colors.transparent
                                        : joRideAccent,
                                  ),
                                ),
                                title: Text(n.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: n.isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    )),
                                subtitle: Text(n.body,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                trailing: Text(
                                  _formatNotifTime(n.createdAt),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
  }

  String _formatNotifTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildBottomNav() {
    final l       = AppLocalizations.of(context);
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) => setState(() => _currentNavIndex = index),
      // Theme-aware: dark surface in dark mode, white in light mode
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: isDark
          ? Theme.of(context).colorScheme.primary
          : joRideAccent,
      unselectedItemColor: isDark ? Colors.white60 : Colors.grey,
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.map_rounded), label: l.t('map')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.event_note_rounded),
            label: l.t('reservations')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.vpn_key_rounded), label: l.t('your_key')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.wallet_rounded), label: l.t('wallet')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded), label: l.t('settings')),
      ],
    );
  }
}
