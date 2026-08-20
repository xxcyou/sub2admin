import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/repository.dart';
import '../theme/liquid.dart';
import '../widgets/widgets.dart';

/// 密钥中心 — full API key management: search, cost analytics, daily trend,
/// expandable per-key detail, and actions (status toggle / delete).
class KeyScreen extends StatefulWidget {
  const KeyScreen({super.key});

  @override
  State<KeyScreen> createState() => _KeyScreenState();
}

class _KeyScreenState extends State<KeyScreen> {
  late final Repository _repo;
  final _searchCtrl = TextEditingController();
  List<ApiKeyInfo> _keys = [];
  Map<int, KeyUsageStats> _costs = {};
  List<KeyTrendPoint> _trend = [];
  bool _loading = true;
  bool _searching = false;
  bool _searchMode = false;
  final Set<int> _expanded = {};
  String? _error;

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
      final results = await Future.wait([
        _searchAll(),
        _repo.keyTrend(),
      ]);
      if (mounted) {
        setState(() {
          _keys = results[0] as List<ApiKeyInfo>;
          _trend = results[1] as List<KeyTrendPoint>;
        });
        await _loadCosts(_keys.map((k) => k.id).toList());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<ApiKeyInfo>> _searchAll() async {
    try {
      return await _repo.searchApiKeys('');
    } catch (_) {
      return [];
    }
  }

  Future<void> _doSearch(String kw) async {
    if (kw.trim().isEmpty) {
      setState(() => _searchMode = false);
      await _load();
      return;
    }
    setState(() {
      _searching = true;
      _searchMode = true;
    });
    try {
      final r = await _repo.searchApiKeys(kw.trim());
      if (mounted) {
        setState(() => _keys = r);
        await _loadCosts(r.map((k) => k.id).toList());
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _loadCosts(List<int> ids) async {
    if (ids.isEmpty) return;
    try {
      final c = await _repo.keyUsage(ids);
      if (mounted) setState(() => _costs = c);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('密钥中心')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _doSearch,
                    decoration: InputDecoration(
                      hintText: '搜索密钥名称 / 归属用户',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchMode
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                _doSearch('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _searching ? null : () => _doSearch(_searchCtrl.text),
                  icon: _searching
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _keys.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _keys.isEmpty) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          _CostSummary(costs: _costs, count: _keys.length),
          const SizedBox(height: 14),
          SectionHeader(title: _searchMode ? '搜索结果' : '全部密钥', trailing: '${_keys.length} 个'),
          const SizedBox(height: 10),
          if (_keys.isEmpty)
            const EmptyState(message: '未找到密钥', icon: Icons.vpn_key_off_rounded)
          else
            ...List.generate(_keys.length, (i) {
              final k = _keys[i];
              final cost = _costs[k.id];
              return _KeyCard(
                keyInfo: k,
                cost: cost,
                expanded: _expanded.contains(i),
                onToggle: () => setState(() {
                  if (_expanded.contains(i)) {
                    _expanded.remove(i);
                  } else {
                    _expanded.add(i);
                  }
                }),
                onStatusToggle: () => _toggleStatus(k),
                onDelete: () => _deleteKey(k, i),
                canLoadDetail: !_searchMode,
              );
            }),
          if (_trend.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: '密钥用量 · 每日 Token 走势'),
            const SizedBox(height: 12),
            _KeyTrendChart(points: _trend.take(14).toList()),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleStatus(ApiKeyInfo k) async {
    // In non-search mode, enrich to a ManagedApiKey to get the full record.
    final full = await _enrich(k);
    if (full == null) {
      _toast('无法加载该密钥完整信息');
      return;
    }
    final target = full.isActive ? 'disabled' : 'active';
    final ok = await _confirm(
      full.isActive ? '禁用密钥' : '启用密钥',
      '确定要${full.isActive ? '禁用' : '启用'}密钥「${full.name}」吗？',
    );
    if (ok != true) return;
    try {
      await _repo.toggleApiKeyStatus(full.id, target);
      _toast('已${full.isActive ? '禁用' : '启用'}密钥');
      await _load();
    } catch (e) {
      _toast('操作失败: $e');
    }
  }

  Future<void> _deleteKey(ApiKeyInfo k, int idx) async {
    final ok = await _confirm('删除密钥', '确定永久删除密钥「${k.name}」吗？此操作不可恢复。');
    if (ok != true) return;
    try {
      await _repo.deleteApiKey(k.id);
      _toast('已删除');
      setState(() => _keys.removeAt(idx));
      _expanded.remove(idx);
    } catch (e) {
      _toast('删除失败（该接口可能不可用）: $e');
    }
  }

  Future<ManagedApiKey?> _enrich(ApiKeyInfo k) async {
    try {
      final keys = await _repo.listUserApiKeys(k.userId);
      for (final full in keys) {
        if (full.id == k.id) return full;
      }
    } catch (_) {}
    return null;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool?> _confirm(String title, String msg) => showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(c).colorScheme.error,
                foregroundColor: Theme.of(c).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('确定'),
            ),
          ],
        ),
      );
}

class _CostSummary extends StatelessWidget {
  final Map<int, KeyUsageStats> costs;
  final int count;
  const _CostSummary({required this.costs, required this.count});

  @override
  Widget build(BuildContext context) {
    final today = costs.values.fold<double>(0, (a, c) => a + c.todayActualCost);
    final total = costs.values.fold<double>(0, (a, c) => a + c.totalActualCost);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.vpn_key_rounded,
            label: '密钥数',
            value: '$count',
            color: const Color(0xFF6C4DF6),
            gradient: const [Color(0xFF6C4DF6), Color(0xFF8B5CF6)],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.today_rounded,
            label: '今日成本',
            value: '¥${today.toStringAsFixed(2)}',
            color: const Color(0xFF0D9488),
            gradient: const [Color(0xFF0D9488), Color(0xFF2DD4BF)],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.savings_rounded,
            label: '累计成本',
            value: '¥${total.toStringAsFixed(2)}',
            color: const Color(0xFFEA580C),
            gradient: const [Color(0xFFEA580C), Color(0xFFF97316)],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final List<Color> gradient;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(height: 10),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  final ApiKeyInfo keyInfo;
  final KeyUsageStats? cost;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onStatusToggle;
  final VoidCallback onDelete;
  final bool canLoadDetail;
  const _KeyCard({
    required this.keyInfo,
    required this.cost,
    required this.expanded,
    required this.onToggle,
    required this.onStatusToggle,
    required this.onDelete,
    required this.canLoadDetail,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      borderRadius: BorderRadius.circular(18),
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.vpn_key_rounded, color: scheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(keyInfo.name.isEmpty ? '未命名 Key' : keyInfo.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14.5)),
                      const SizedBox(height: 2),
                      Text('用户 #${keyInfo.userId}',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
                    ],
                  ),
                ),
                if (cost != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('¥${cost!.todayActualCost.toStringAsFixed(4)}',
                          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                      Text('今日', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 9.5)),
                    ],
                  ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more_rounded, color: scheme.outline),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox(height: 0),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  if (cost != null) ...[
                    _kv(scheme, '今日成本', '¥${cost!.todayActualCost.toStringAsFixed(4)}'),
                    _kv(scheme, '累计成本', '¥${cost!.totalActualCost.toStringAsFixed(4)}'),
                  ],
                  _kv(scheme, 'Key ID', '${keyInfo.id}'),
                  _kv(scheme, '归属用户', '#${keyInfo.userId}'),
                  Row(
                    children: [
                      SizedBox(width: 96,
                          child: Text('更多操作', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onStatusToggle,
                        icon: const Icon(Icons.toggle_on_outlined, size: 18),
                        label: const Text('启停'),
                      ),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: scheme.error),
                        label: Text('删除', style: TextStyle(color: scheme.error)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(ColorScheme scheme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 96, child: Text(k, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))),
          Expanded(
            child: Text(v, textAlign: TextAlign.right,
                style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _KeyTrendChart extends StatelessWidget {
  final List<KeyTrendPoint> points;
  const _KeyTrendChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = points.toList()
      ..sort((a, b) => b.tokens.compareTo(a.tokens));
    final maxTokens = top.fold<int>(0, (a, p) => p.tokens > a ? p.tokens : a);
    final unique = <int, KeyTrendPoint>{};
    for (final p in top) {
      unique.putIfAbsent(p.apiKeyId, () => p);
    }
    final rows = unique.values.take(6).toList();
    return GlassCard(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: rows.map((p) {
          final frac = maxTokens == 0 ? 0.0 : (p.tokens / maxTokens).clamp(0.02, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.keyName ?? 'Key ${p.apiKeyId}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurface, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    Text('${fmtCompact(p.tokens)} tk',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 5,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
