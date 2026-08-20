import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/repository.dart';
import '../widgets/dialogs.dart';
import '../widgets/widgets.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  late final Repository _repo;
  List<ChannelItem> _channels = [];
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
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
      final page = await _repo.channels(page: 1);
      if (mounted) {
        setState(() {
          _channels = page.items;
          _page = 1;
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
      final page = await _repo.channels(page: _page + 1);
      if (mounted) {
        setState(() {
          _channels.addAll(page.items);
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

  Future<void> _createChannel() async {
    final nameCtl = TextEditingController();
    final descCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建渠道'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtl,
                decoration: const InputDecoration(labelText: '渠道名称 *', prefixIcon: Icon(Icons.router_rounded))),
            const SizedBox(height: 12),
            TextField(controller: descCtl,
                decoration: const InputDecoration(labelText: '描述 (可选)', prefixIcon: Icon(Icons.description_outlined))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (nameCtl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.createChannel(name: nameCtl.text.trim(), description: descCtl.text.trim());
      _toast('渠道已创建');
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _toggleChannel(ChannelItem c) async {
    final target = c.status == 'active' ? 'disabled' : 'active';
    final ok = await confirmDialog(
      context,
      title: target == 'active' ? '启用渠道' : '禁用渠道',
      message: target == 'active'
          ? '确定启用渠道「${c.name}」吗？'
          : '确定禁用渠道「${c.name}」吗？禁用后该渠道不再接单。',
    );
    if (!ok) return;
    try {
      await _repo.channelToggle(c.id, target);
      _toast(target == 'active' ? '已启用' : '已禁用');
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _deleteChannel(ChannelItem c) async {
    final ok = await confirmDialog(
      context,
      title: '删除渠道',
      message: '确定删除渠道「${c.name}」吗？此操作不可恢复。',
      confirmText: '删除',
      confirmColor: const Color(0xFFE74C3C),
    );
    if (!ok) return;
    try {
      await _repo.deleteChannel(c.id);
      _toast('渠道已删除');
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  void _channelMenu(ChannelItem c) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.router_rounded),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('#${c.id} · ${c.status}'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(c.status == 'active' ? Icons.block_rounded : Icons.check_circle_rounded,
                  color: c.status == 'active' ? const Color(0xFFF39C12) : const Color(0xFF2ECC71)),
              title: Text(c.status == 'active' ? '禁用渠道' : '启用渠道'),
              onTap: () {
                Navigator.pop(ctx);
                _toggleChannel(c);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFE74C3C)),
              title: const Text('删除渠道', style: TextStyle(color: Color(0xFFE74C3C))),
              onTap: () {
                Navigator.pop(ctx);
                _deleteChannel(c);
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
        title: Text('渠道 (${fmtNum(_channels.length)})'),
        actions: [
          IconButton(tooltip: '创建渠道', onPressed: _createChannel, icon: const Icon(Icons.add_circle_outline_rounded)),
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
                hintText: '搜索渠道名称或描述',
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

  List<ChannelItem> get _filtered => _query.isEmpty
      ? _channels
      : _channels.where((c) {
          return c.name.toLowerCase().contains(_query) ||
              c.description.toLowerCase().contains(_query) ||
              c.id.toString().contains(_query);
        }).toList();

  Widget _buildBody(BuildContext context) {
    if (_loading && _channels.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _channels.isEmpty) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final list = _filtered;
    if (list.isEmpty) {
      return EmptyState(
        message: _query.isEmpty ? '暂无渠道，点击右上角创建' : '未找到匹配的渠道',
        icon: Icons.router_outlined,
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
          final c = list[i];
          return _ChannelCard(
            channel: c,
            onTap: () => _channelMenu(c),
          );
        },
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final ChannelItem channel;
  final VoidCallback onTap;
  const _ChannelCard({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sc = statusColor(channel.status, context);
    final disabled = channel.status != 'active';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: disabled ? 0.6 : 1,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.primary.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.router_rounded, size: 22, color: scheme.onPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14.5)),
                      ),
                      const SizedBox(width: 6),
                      StatusChip(text: channel.status, color: sc),
                    ]),
                    if (channel.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(channel.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.more_vert_rounded, size: 20, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
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
