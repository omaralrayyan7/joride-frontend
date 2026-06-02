import 'package:flutter/material.dart';

import 'models/vehicle_model.dart';
import 'services/api_service.dart';

const Color _accent = Color(0xFF13366B);

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          title: const Text('Admin Dashboard'),
          // Brand-coloured back arrow on white
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.directions_car), text: 'Cars'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.attach_money), text: 'Pricing'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Audit'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _StatsTab(),
            _CarsTab(),
            _UsersTab(),
            _PricingTab(),
            _AuditTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Overview / Statistics ───────────────────────────────────────────────────
class _StatsTab extends StatefulWidget {
  const _StatsTab();
  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await ApiService.getAdminStats();
      if (mounted) setState(() => _stats = s);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _n(String k) => (_stats?[k] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorRetry(message: _error!, onRetry: _load);

    final cards = [
      _StatCard('Total Users', _n('totalUsers'), Icons.people, Colors.indigo),
      _StatCard('Total Cars', _n('totalCars'), Icons.directions_car, Colors.teal),
      _StatCard('Available Cars', _n('availableCars'), Icons.event_available, Colors.green),
      _StatCard('In-Use Cars', _n('inUseCars'), Icons.no_crash, Colors.orange),
      _StatCard('Trips In Progress', _n('tripsInProgress'), Icons.timelapse, Colors.purple),
      _StatCard('Total Trips', _n('totalTrips'), Icons.route, Colors.blueGrey),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live data header — values reflect real backend totals at load time
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live Statistics',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  onPressed: _load,
                ),
              ],
            ),
          ),
          // childAspectRatio lowered from 1.5 → 1.3 to give labels more vertical room
          // (was overflowing by ~6.7 px when stat numbers were large).
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: cards,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 30),
          Text('$value', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// ─── Cars management ───────────────────────────────────────────────────────────
class _CarsTab extends StatefulWidget {
  const _CarsTab();
  @override
  State<_CarsTab> createState() => _CarsTabState();
}

class _CarsTabState extends State<_CarsTab> {
  final _searchCtrl = TextEditingController();
  List<Vehicle> _cars = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.adminGetVehicles(search: _searchCtrl.text);
      if (mounted) setState(() => _cars = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _control(Vehicle v, String command, String label) async {
    try {
      await ApiService.adminVehicleControl(v.id, command);
      _snack('$label sent to ${v.licensePlate}.', Colors.green);
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  /// Toggle vehicle visibility on the user map.
  Future<void> _toggleVisibility(Vehicle v) async {
    try {
      if (v.isVisible) {
        await ApiService.adminHideVehicle(v.id);
        _snack('${v.licensePlate} hidden from map.', Colors.orange);
      } else {
        await ApiService.adminShowVehicle(v.id);
        _snack('${v.licensePlate} restored to map.', Colors.green);
      }
      _load();
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  Future<void> _delete(Vehicle v) async {
    final ok = await _confirm('Delete ${v.licensePlate}?');
    if (!ok) return;
    try {
      await ApiService.adminDeleteVehicle(v.id);
      _snack('Deleted.', Colors.green);
      _load();
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  Future<void> _edit({Vehicle? car}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CarEditDialog(car: car),
    );
    if (saved == true) _load();
  }

  void _snack(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  Future<bool> _confirm(String message) async {
    return (await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Please confirm'),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accent,
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _SearchBar(controller: _searchCtrl, hint: 'Search plate, model, category…', onSearch: _load),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorRetry(message: _error!, onRetry: _load)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _cars.length,
                          itemBuilder: (_, i) => _carTile(_cars[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _carTile(Vehicle v) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    v.imageUrl,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 40),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${v.model} • ${v.licensePlate}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${v.category} · ${v.color} · fuel ${v.fuelLevel}%',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _statusChip(v.status),
                    if (!v.isVisible)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(40),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Text('Hidden',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 6,
              children: [
                _ctrlBtn('Unlock', Icons.lock_open, () => _control(v, 'unlock', 'Unlock')),
                _ctrlBtn('Lock', Icons.lock, () => _control(v, 'lock', 'Lock')),
                _ctrlBtn('Start', Icons.power_settings_new, () => _control(v, 'engine/start', 'Start engine')),
                _ctrlBtn('Kill', Icons.dangerous, () => _control(v, 'engine/kill', 'Kill engine')),
                // Visibility toggle — hide/show on user map
                _ctrlBtn(
                  v.isVisible ? 'Hide' : 'Show',
                  v.isVisible ? Icons.visibility_off : Icons.visibility,
                  () => _toggleVisibility(v),
                  color: v.isVisible ? Colors.orange : Colors.teal,
                ),
                _ctrlBtn('Edit', Icons.edit, () => _edit(car: v)),
                _ctrlBtn('Delete', Icons.delete, () => _delete(v), color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = status == 'Available'
        ? Colors.green
        : status == 'InUse'
            ? Colors.orange
            : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _ctrlBtn(String label, IconData icon, VoidCallback onTap, {Color color = _accent}) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
    );
  }
}

class _CarEditDialog extends StatefulWidget {
  final Vehicle? car;
  const _CarEditDialog({this.car});
  @override
  State<_CarEditDialog> createState() => _CarEditDialogState();
}

class _CarEditDialogState extends State<_CarEditDialog> {
  late final Map<String, TextEditingController> c;
  String _status = 'Available';
  String _category = 'Economy';
  bool _saving = false;

  static const _categories = ['Economy', 'Luxury', 'SUV', 'Electric'];
  static const _statuses = ['Available', 'InUse', 'Maintenance'];

  @override
  void initState() {
    super.initState();
    final v = widget.car;
    _status = (_statuses.contains(v?.status)) ? v!.status : 'Available';
    _category = (_categories.contains(v?.category)) ? v!.category : 'Economy';
    c = {
      'licensePlate': TextEditingController(text: v?.licensePlate ?? ''),
      'model': TextEditingController(text: v?.model ?? ''),
      'color': TextEditingController(text: v?.color ?? ''),
      'latitude': TextEditingController(text: (v?.latitude ?? 31.95).toString()),
      'longitude': TextEditingController(text: (v?.longitude ?? 35.91).toString()),
      'fuelLevel': TextEditingController(text: (v?.fuelLevel ?? 100).toString()),
      'imageUrl': TextEditingController(text: v?.imageUrl ?? ''),
    };
  }

  @override
  void dispose() {
    for (final ctrl in c.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final body = {
      'licensePlate': c['licensePlate']!.text.trim(),
      'model': c['model']!.text.trim(),
      'category': _category,
      'color': c['color']!.text.trim(),
      'status': _status,
      'latitude': double.tryParse(c['latitude']!.text) ?? 0,
      'longitude': double.tryParse(c['longitude']!.text) ?? 0,
      'fuelLevel': int.tryParse(c['fuelLevel']!.text) ?? 100,
      'imageUrl': c['imageUrl']!.text.trim(),
    };
    try {
      if (widget.car == null) {
        await ApiService.adminCreateVehicle(body);
      } else {
        await ApiService.adminUpdateVehicle(widget.car!.id, body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.car == null ? 'Add Car' : 'Edit Car'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('License Plate', c['licensePlate']!),
            _field('Model', c['model']!),
            _dropdown('Category', _category, _categories, (v) => setState(() => _category = v!)),
            _field('Color', c['color']!),
            _dropdown('Status', _status, _statuses, (v) => setState(() => _status = v!)),
            _field('Latitude', c['latitude']!, number: true),
            _field('Longitude', c['longitude']!, number: true),
            _field('Fuel Level (%)', c['fuelLevel']!, number: true),
            _field('Image URL', c['imageUrl']!),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _accent),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool number = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: ctrl,
          keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : null,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      );
}

// ─── Users management ──────────────────────────────────────────────────────────
class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.adminGetUsers(search: _searchCtrl.text);
      if (mounted) setState(() => _users = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  Future<void> _toggleActive(Map<String, dynamic> u) async {
    final id = u['id'].toString();
    final active = (u['isActive'] as bool?) ?? false;
    try {
      if (active) {
        await ApiService.adminDeactivateUser(id);
      } else {
        await ApiService.adminActivateUser(id);
      }
      _load();
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  Future<void> _delete(Map<String, dynamic> u) async {
    final ok = (await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete user'),
            content: Text('Delete ${u['name']} (${u['email']})?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        )) ??
        false;
    if (!ok) return;
    try {
      await ApiService.adminDeleteUser(u['id'].toString());
      _load();
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  Future<void> _edit(Map<String, dynamic> u) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _UserEditDialog(user: u),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchBar(controller: _searchCtrl, hint: 'Search name, email, ID…', onSearch: _load),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorRetry(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _users.length,
                        itemBuilder: (_, i) => _userTile(_users[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _userTile(Map<String, dynamic> u) {
    final active = (u['isActive'] as bool?) ?? false;
    final isAdmin = (u['isAdmin'] as bool?) ?? false;
    final balance = (u['walletBalance'] as num?)?.toDouble() ?? 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin ? Colors.deepPurple : _accent,
          child: Icon(isAdmin ? Icons.shield : Icons.person, color: Colors.white),
        ),
        title: Text('${u['name'] ?? '-'}${isAdmin ? '  (Admin)' : ''}'),
        subtitle: Text(
          '${u['email'] ?? '-'}\nWallet: ${balance.toStringAsFixed(2)} JOD${balance < 0 ? '  ⚠ DEBT' : ''}',
          style: TextStyle(color: balance < 0 ? Colors.red : null),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') _edit(u);
            if (v == 'toggle') _toggleActive(u);
            if (v == 'delete') _delete(u);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'toggle', child: Text(active ? 'Deactivate' : 'Activate')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _UserEditDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  const _UserEditDialog({required this.user});
  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late bool _isAdmin;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user['name']?.toString() ?? '');
    _email = TextEditingController(text: widget.user['email']?.toString() ?? '');
    _phone = TextEditingController(text: widget.user['phone']?.toString() ?? '');
    _isAdmin = (widget.user['isAdmin'] as bool?) ?? false;
    _isActive = (widget.user['isActive'] as bool?) ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.adminUpdateUser(widget.user['id'].toString(), {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'isAdmin': _isAdmin,
        'isActive': _isActive,
        'isLicenseVerified': (widget.user['isLicenseVerified'] as bool?) ?? false,
        'isEmailVerified': (widget.user['isEmailVerified'] as bool?) ?? false,
        'isPhoneVerified': (widget.user['isPhoneVerified'] as bool?) ?? false,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Name', _name),
            _field('Email', _email),
            _field('Phone', _phone),
            SwitchListTile(
              title: const Text('Administrator'),
              value: _isAdmin,
              activeColor: _accent,
              onChanged: (v) => setState(() => _isAdmin = v),
            ),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              activeColor: _accent,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _accent),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );
}

// ─── Pricing management ────────────────────────────────────────────────────────
class _PricingTab extends StatefulWidget {
  const _PricingTab();
  @override
  State<_PricingTab> createState() => _PricingTabState();
}

class _PricingTabState extends State<_PricingTab> {
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getPricing();
      if (mounted) setState(() => _plans = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> p) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PricingEditDialog(plan: p),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorRetry(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _plans.length,
        itemBuilder: (_, i) {
          final p = _plans[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.category, color: _accent),
              title: Text('${p['category']}${(p['isActive'] as bool? ?? true) ? '' : ' (inactive)'}'),
              subtitle: Text(
                  'min: ${p['minuteRate']}  ·  hour: ${p['hourlyRate']}  ·  day: ${p['dailyRate']} JOD'),
              trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(p)),
            ),
          );
        },
      ),
    );
  }
}

class _PricingEditDialog extends StatefulWidget {
  final Map<String, dynamic> plan;
  const _PricingEditDialog({required this.plan});
  @override
  State<_PricingEditDialog> createState() => _PricingEditDialogState();
}

class _PricingEditDialogState extends State<_PricingEditDialog> {
  late final TextEditingController _min;
  late final TextEditingController _hour;
  late final TextEditingController _day;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _min = TextEditingController(text: widget.plan['minuteRate'].toString());
    _hour = TextEditingController(text: widget.plan['hourlyRate'].toString());
    _day = TextEditingController(text: widget.plan['dailyRate'].toString());
    _active = (widget.plan['isActive'] as bool?) ?? true;
  }

  @override
  void dispose() {
    _min.dispose();
    _hour.dispose();
    _day.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.updatePricing(widget.plan['id'].toString(), {
        'category': widget.plan['category'],
        'minuteRate': double.tryParse(_min.text) ?? 0,
        'hourlyRate': double.tryParse(_hour.text) ?? 0,
        'dailyRate': double.tryParse(_day.text) ?? 0,
        'isActive': _active,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pricing — ${widget.plan['category']}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rate('Per minute', _min),
          _rate('Per hour', _hour),
          _rate('Per day', _day),
          SwitchListTile(
            title: const Text('Active'),
            value: _active,
            activeColor: _accent,
            onChanged: (v) => setState(() => _active = v),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _accent),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _rate(String label, TextEditingController ctrl) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '$label (JOD)', border: const OutlineInputBorder()),
        ),
      );
}

// ─── Audit logs ────────────────────────────────────────────────────────────────
class _AuditTab extends StatefulWidget {
  const _AuditTab();
  @override
  State<_AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<_AuditTab> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String? _error;
  String _filter = 'All';

  static const _filters = ['All', 'Vehicle', 'Trip', 'User'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getAuditLogs(
        entityType: _filter == 'All' ? null : _filter,
      );
      if (mounted) setState(() => _logs = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconFor(String action) {
    if (action.contains('Unlock')) return Icons.lock_open;
    if (action.contains('Lock')) return Icons.lock;
    if (action.contains('EngineStarted')) return Icons.power_settings_new;
    if (action.contains('EngineKilled')) return Icons.dangerous;
    if (action.contains('Booked')) return Icons.event_available;
    if (action.contains('Ended')) return Icons.flag;
    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Filter: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filter,
                items: _filters.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _filter = v);
                  _load();
                },
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorRetry(message: _error!, onRetry: _load)
                  : _logs.isEmpty
                      ? const Center(child: Text('No audit entries yet.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _logs.length,
                          itemBuilder: (_, i) {
                            final l = _logs[i];
                            final action = (l['action'] ?? '').toString();
                            final ts = DateTime.tryParse(l['timestamp']?.toString() ?? '')?.toLocal();
                            final role = (l['actorRole'] ?? '').toString();
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(_iconFor(action), color: _accent),
                                title: Text('$action  ·  ${l['entityType']} #${l['entityId']}'),
                                subtitle: Text(
                                    '${l['actor'] ?? ''}\n${l['details'] ?? ''}\n${ts ?? ''}'),
                                isThreeLine: true,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: role == 'Admin'
                                        ? Colors.deepPurple.withOpacity(0.15)
                                        : Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(role,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: role == 'Admin' ? Colors.deepPurple : Colors.blue)),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

// ─── Shared widgets ────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSearch;
  const _SearchBar({required this.controller, required this.hint, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: controller,
        onSubmitted: (_) => onSearch(),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: onSearch),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
