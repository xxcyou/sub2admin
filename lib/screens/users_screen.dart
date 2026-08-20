import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/repository.dart';
import '../widgets/widgets.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late final Repository _repo;
  List<UserItem> _users = [];
  int _page = 1;
  int? _total;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  bool _hasMore = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repo = Repository(context.read<AppState>().api);
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
      final page = await _repo.users(page: 1);
      if (mounted) {
        setState(() {
          _users = page.items;
          _page = 1;
          _total = page.total;
          _hasMore = page.items.length >= 25;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.users(page: _page + 1);
      if (mounted) {
        setState(() {
          _users.addAll(page.items);
          _page += 1;
          _hasMore = page.items.length >= 25;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _createUser() async {
    final emailCtl = TextEditingController();
    final passCtl = TextEditingController();
    final nameCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建用户'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailCtl,
                  decoration: const InputDecoration(labelText: '邮箱 *', prefixIcon: Icon(Icons.mail_rounded))),
              const SizedBox(height: 12),
              TextField(controller: passCtl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '初始密码 *', prefixIcon: Icon(Icons.lock_rounded))),
              const SizedBox(height: 12),
              TextField(controller: nameCtl,
                  decoration: const InputDecoration(labelText: '用户名 (可选)', prefixIcon: Icon(Icons.badge_rounded))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (emailCtl.text.trim().isEmpty || passCtl.text.isEmpty) {
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.createUser(
        email: emailCtl.text.trim(),
        password: passCtl.text,
        username: nameCtl.text.trim(),
      );
      _toast('创建成功');
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  void _openUser(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserDetailScreen(userId: id)),
    ).then((_) => _load());
  }

  void _userActions(UserItem u) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: Text(u.email, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('#${u.id} · ${u.role}'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.visibility_rounded),
              title: const Text('查看详情'),
              onTap: () {
                Navigator.pop(ctx);
                _openUser(u.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_total != null ? '用户 (${fmtNum(_total)})' : '用户 (${fmtNum(_users.length)})'),
        actions: [
          IconButton(tooltip: '创建用户', onPressed: _createUser, icon: const Icon(Icons.person_add_alt_1_rounded)),
          IconButton(tooltip: '刷新', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: '搜索邮箱或 ID',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  List<UserItem> get _filtered => _query.isEmpty
      ? _users
      : _users.where((u) {
          return u.email.toLowerCase().contains(_query) || u.id.toString().contains(_query);
        }).toList();

  Widget _buildBody(BuildContext context) {
    if (_loading && _users.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _users.isEmpty) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final list = _filtered;
    if (list.isEmpty) {
      return EmptyState(
        message: _query.isEmpty ? '暂无用户，点击右上角创建' : '未找到匹配的用户',
        icon: Icons.people_outline_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: list.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i >= list.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _loadingMore
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : TextButton(onPressed: _loadMore, child: const Text('加载更多')),
              ),
            );
          }
          final u = list[i];
          return _UserCard(
            user: u,
            onTap: () => _openUser(u.id),
            onLongPress: () => _userActions(u),
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserItem user;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _UserCard({required this.user, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sc = statusColor(user.status, context);
    final initial = user.email.isEmpty ? '?' : user.email[0].toUpperCase();
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              child: Text(initial,
                  style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800, fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(user.email,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14.5)),
                    ),
                    const SizedBox(width: 6),
                    StatusChip(text: user.status, color: sc),
                  ]),
                  const SizedBox(height: 4),
                  Text('#${user.id} · 注册 ${user.createdAt == null ? '-' : '${user.createdAt!.year}-${_2(user.createdAt!.month)}-${_2(user.createdAt!.day)}'}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.account_balance_wallet_rounded, size: 15, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text('¥${user.balance.toStringAsFixed(2)}',
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                ]),
                const SizedBox(height: 4),
                Text('并发 ${user.concurrency}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: scheme.outline),
          ],
        ),
      ),
    );
  }

  String _2(int v) => v.toString().padLeft(2, '0');
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 52, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
