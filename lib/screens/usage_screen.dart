import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/repository.dart';
import '../widgets/widgets.dart';

/// Full detailed usage records with expandable per-request breakdown.
class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  late final Repository _repo;
  List<UsageRecord> _records = [];
  int _page = 1;
  int? _total;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  final _modelFilter = TextEditingController();
  final _userFilter = TextEditingController();
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _repo = Repository(context.read<AppState>().api);
    _load();
  }

  @override
  void dispose() {
    _modelFilter.dispose();
    _userFilter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _fetch(page: 1);
      if (mounted) {
        setState(() {
          _records = page.items;
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

  Future<PageData<UsageRecord>> _fetch({required int page}) async {
    return _repo.usage(
      page: page,
      pageSize: 25,
      model: _modelFilter.text.trim().isEmpty ? null : _modelFilter.text.trim(),
      userId: int.tryParse(_userFilter.text.trim()),
    );
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetch(page: _page + 1);
      if (mounted) {
        setState(() {
          _records.addAll(page.items);
          _page += 1;
          _hasMore = page.items.length >= 25;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_total != null ? '实时用量 (${fmtNum(_total)})' : '实时用量'),
        actions: [
          IconButton(tooltip: '刷新', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _modelFilter,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _load(),
                    decoration: const InputDecoration(
                      hintText: '模型',
                      prefixIcon: Icon(Icons.smart_toy_rounded, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _userFilter,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _load(),
                    decoration: const InputDecoration(
                      hintText: '用户 ID',
                      prefixIcon: Icon(Icons.people_alt_rounded, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _loading ? null : _load,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search_rounded),
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
    if (_loading && _records.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _records.isEmpty) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    if (_records.isEmpty) {
      return const EmptyState(message: '暂无用量记录', icon: Icons.receipt_long_outlined);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: _records.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i >= _records.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _loadingMore
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : TextButton(onPressed: _loadMore, child: const Text('加载更多')),
              ),
            );
          }
          final rec = _records[i];
          return _UsageCard(
            record: rec,
            expanded: _expanded.contains(i),
            onToggle: () => setState(() {
              if (_expanded.contains(i)) {
                _expanded.remove(i);
              } else {
                _expanded.add(i);
              }
            }),
          );
        },
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final UsageRecord record;
  final bool expanded;
  final VoidCallback onToggle;
  const _UsageCard({required this.record, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalTk = record.totalTokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: expanded ? scheme.primary.withValues(alpha: 0.5) : scheme.outlineVariant.withValues(alpha: 0.4),
          width: expanded ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: record.kindColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(record.model,
                        style: TextStyle(color: record.kindColor, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('¥${record.totalCost.toStringAsFixed(4)}',
                          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.token_rounded, size: 13, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text('${fmtNum(totalTk)} tk',
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, color: scheme.outline, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // subtitle row
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 13, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(_time(record.createdAt),
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
                  const SizedBox(width: 12),
                  if (record.userEmail != null) ...[
                    Icon(Icons.person_rounded, size: 13, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(record.userEmail!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // mini token bars
              Row(
                children: [
                  _MiniBar(label: '输入', value: record.inputTokens, color: const Color(0xFF5C6BC0)),
                  const SizedBox(width: 8),
                  _MiniBar(label: '输出', value: record.outputTokens, color: const Color(0xFF26A69A)),
                  const SizedBox(width: 8),
                  _MiniBar(label: '缓存读', value: record.cacheReadTokens, color: const Color(0xFFF39C12)),
                ],
              ),

              // Expanded detail
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity, height: 0),
                secondChild: _DetailBody(record: record),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _time(DateTime? d) {
    if (d == null) return '-';
    return '${d.month}/${d.day} ${_2(d.hour)}:${_2(d.minute)}:${_2(d.second)}';
  }

  String _2(int v) => v.toString().padLeft(2, '0');
}

class _DetailBody extends StatelessWidget {
  final UsageRecord record;
  const _DetailBody({required this.record});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divider = Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.3));
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          divider,
          const SizedBox(height: 10),
          _section(scheme, 'Token 明细'),
          const SizedBox(height: 4),
          _tokenRow(scheme, '输入', record.inputTokens, record.inputCost, const Color(0xFF5C6BC0)),
          _tokenRow(scheme, '输出', record.outputTokens, record.outputCost, const Color(0xFF26A69A)),
          _tokenRow(scheme, '缓存创建', record.cacheCreationTokens, record.cacheCreationCost, const Color(0xFF8E24AA)),
          _tokenRow(scheme, '缓存读取', record.cacheReadTokens, record.cacheReadCost, const Color(0xFFF39C12)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Spacer(),
              Text('合计 ${fmtNum(record.totalTokens)} tokens',
                  style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(width: 12),
              Text('¥${record.totalCost.toStringAsFixed(4)}',
                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          divider,
          const SizedBox(height: 10),
          _section(scheme, '计费'),
          const SizedBox(height: 4),
          _kv(scheme, '计费模式', record.billingMode),
          _kv(scheme, '倍率', 'x${record.rateMultiplier.toStringAsFixed(2)}'),
          _kv(scheme, '实际成本', '¥${record.actualCost.toStringAsFixed(4)}'),
          const SizedBox(height: 10),
          divider,
          const SizedBox(height: 10),
          _section(scheme, '性能'),
          const SizedBox(height: 4),
          _kv(scheme, '总耗时', '${(record.durationMs / 1000).toStringAsFixed(2)} s'),
          _kv(scheme, '首 token 延迟', '${(record.firstTokenMs / 1000).toStringAsFixed(2)} s (TTFT)'),
          _kv(scheme, '请求类型', record.isStream ? '流式 Stream' : '普通'),
          const SizedBox(height: 10),
          divider,
          const SizedBox(height: 10),
          _section(scheme, '归属信息'),
          const SizedBox(height: 4),
          if (record.userEmail != null) _kv(scheme, '用户', '${record.userEmail} (#${record.userId})'),
          if (record.groupName != null) _kv(scheme, '分组', record.groupName!),
          if (record.accountName != null) _kv(scheme, '渠道账户', record.accountName!),
          _kv(scheme, '模型', record.model),
          if (record.upstreamModel.isNotEmpty && record.upstreamModel != record.model) _kv(scheme, '上游模型', record.upstreamModel),
          _kv(scheme, '入口', record.inboundEndpoint),
          if (record.ipAddress != null) _kv(scheme, 'IP', record.ipAddress!),
          if (record.userAgent != null && record.userAgent!.isNotEmpty) _kv(scheme, 'UA', record.userAgent!, maxLines: 3),
          _kv(scheme, 'Request ID', record.requestId, mono: true),
          const SizedBox(height: 6),
          if (record.apiKey != null) ...[
            divider,
            const SizedBox(height: 10),
            _section(scheme, 'API Key 详情'),
            const SizedBox(height: 4),
            _kv(scheme, '名称', record.apiKey!.name),
            _kv(scheme, 'Key', record.apiKey!.key, mono: true),
            _kv(scheme, '状态', record.apiKey!.status),
            _kv(scheme, '限额', '${fmtNum(record.apiKey!.quota)} / 已用 ${fmtNum(record.apiKey!.quotaUsed)}'),
            if (record.apiKey!.expiresAt != null) _kv(scheme, '过期时间', _dt(record.apiKey!.expiresAt!)),
          ],
        ],
      ),
    );
  }

  Widget _tokenRow(ColorScheme scheme, String label, int tokens, double cost, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5))),
          Text('${fmtNum(tokens)} tk', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text('¥${cost.toStringAsFixed(4)}',
                textAlign: TextAlign.right,
                style: TextStyle(color: scheme.onSurface, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _kv(ColorScheme scheme, String k, String v, {int maxLines = 1, bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(k, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          ),
          Expanded(
            child: Text(v,
                textAlign: TextAlign.right,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: mono ? 'monospace' : null)),
          ),
        ],
      ),
    );
  }

  Widget _section(ColorScheme scheme, String title) {
    return Text(title, style: TextStyle(color: scheme.onSurface, fontSize: 13, fontWeight: FontWeight.w800));
  }

  String _dt(DateTime d) => '${d.year}-${_2(d.month)}-${_2(d.day)} ${_2(d.hour)}:${_2(d.minute)}';
  String _2(int v) => v.toString().padLeft(2, '0');
}


class _MiniBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MiniBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10.5)),
              Text(fmtCompact(value), style: TextStyle(color: scheme.onSurface, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.5,
              minHeight: 4,
              color: color,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
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

extension on UsageRecord {
  Color get kindColor {
    return const Color(0xFF8E24AA);
  }
}
