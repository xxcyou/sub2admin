import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/repository.dart';
import '../widgets/widgets.dart';
import 'api_key_screen.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  late final Repository _repo;
  List<RankItem> _models = [];
  List<RequestLog> _logs = [];
  int _page = 1;
  int? _total;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  bool _loadingLogs = false;
  String? _error;
  final _modelFilter = TextEditingController();

  int _kindIdx = 0;

  @override
  void initState() {
    super.initState();
    _repo = Repository(context.read<AppState>().api);
    _load();
  }

  @override
  void dispose() {
    _modelFilter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_repo.models(), _logsFetch(page: 1)]);
      if (mounted) {
        setState(() {
          _models = results[0] as List<RankItem>;
          _logs = (results[1] as PageData<RequestLog>).items;
          _total = (results[1] as PageData<RequestLog>).total;
          _hasMore = (results[1] as PageData<RequestLog>).items.length >= 30;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<PageData<RequestLog>> _logsFetch({int page = 1}) async {
    final model = _modelFilter.text.trim();
    return _repo.logs(
      page: page,
      pageSize: 30,
      model: model.isEmpty ? null : model,
    );
  }

  Future<void> _refreshLogs() async {
    if (_loadingLogs) return;
    setState(() => _loadingLogs = true);
    try {
      final page = await _logsFetch(page: 1);
      if (mounted) {
        setState(() {
          _logs = page.items;
          _total = page.total;
          _hasMore = page.items.length >= 30;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loadingLogs = false);
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_loadingLogs || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _logsFetch(page: _page + 1);
      if (mounted) {
        setState(() {
          _logs.addAll(page.items);
          _page += 1;
          _hasMore = page.items.length >= 30;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<RequestLog> get _filteredLogs {
    if (_kindIdx == 0) return _logs;
    final wantSuccess = _kindIdx == 1;
    return _logs.where((l) => (l.kind == 'success') == wantSuccess).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志 & 模型'),
        actions: [
          IconButton(
            tooltip: 'API Key 检索',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ApiKeyScreen()),
            ),
            icon: const Icon(Icons.vpn_key_rounded),
          ),
          IconButton(tooltip: '刷新', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _models.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(context, scheme),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme scheme) {
    if (_error != null && _models.isEmpty) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        const SectionHeader(title: '模型用量排行'),
        const SizedBox(height: 12),
        if (_models.isEmpty)
          const EmptyState(message: '暂无模型数据')
        else
          ..._models.take(8).map((m) => _ModelRow(item: m)),
        const SizedBox(height: 24),

        SectionHeader(title: '请求日志', trailing: _total != null ? '共 ${fmtNum(_total)} 条' : null),
        const SizedBox(height: 10),

        // filter bar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _modelFilter,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _refreshLogs(),
                decoration: InputDecoration(
                  hintText: '按模型筛选 (如 deepseek-v4)',
                  prefixIcon: const Icon(Icons.filter_alt_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _refreshLogs,
              icon: _loadingLogs
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('全部')),
            ButtonSegment(value: 1, label: Text('成功')),
            ButtonSegment(value: 2, label: Text('错误')),
          ],
          selected: {_kindIdx},
          onSelectionChanged: (s) => setState(() => _kindIdx = s.first),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        const SizedBox(height: 10),
        if (_filteredLogs.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: EmptyState(message: '暂无匹配的请求记录', icon: Icons.receipt_long_outlined),
          )
        else ...[
          ..._filteredLogs.map((l) => _LogTile(log: l)),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: _loadingMore
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : TextButton(onPressed: _loadMoreLogs, child: const Text('加载更多')),
              ),
            ),
        ],
      ],
    );
  }
}

class _ModelRow extends StatelessWidget {
  final RankItem item;
  const _ModelRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Icon(Icons.smart_toy_rounded, size: 19, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 3),
                Text('${fmtNum(item.requests)} 次 · ${fmtCompact(item.tokens)} tokens',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
              ],
            ),
          ),
          Text('¥${item.cost.toStringAsFixed(2)}',
              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final RequestLog log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sc = statusColor(log.kind, context);
    final time = '${_2(log.createdAt.hour)}:${_2(log.createdAt.minute)}:${_2(log.createdAt.second)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.model.isEmpty ? '-' : log.model, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('用户#${log.userId} · ${log.platform} · $time',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          Text('${(log.durationMs / 1000).toStringAsFixed(2)}s',
              style: TextStyle(
                  color: log.durationMs > 15000 ? const Color(0xFFE74C3C) : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5)),
        ],
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
