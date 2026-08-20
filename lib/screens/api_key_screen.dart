import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/repository.dart';
import '../widgets/widgets.dart';

/// Search & browse all API keys across users.
class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  late final Repository _repo;
  final _searchCtrl = TextEditingController();
  List<ApiKeyInfo> _keys = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = Repository(context.read<AppState>().api);
    _load('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(String keyword) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final keys = await _repo.searchApiKeys(keyword);
      if (mounted) setState(() => _keys = keys);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Key 检索')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) => _load(v.trim()),
                    decoration: InputDecoration(
                      hintText: '输入 Key 名称搜索',
                      prefixIcon: const Icon(Icons.vpn_key_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  tooltip: '搜索',
                  onPressed: () => _load(_searchCtrl.text.trim()),
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading && _keys.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _keys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_rounded, size: 52, color: scheme.outline),
            const SizedBox(height: 14),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
          ]),
        ),
      );
    }
    if (_keys.isEmpty) {
      return EmptyState(
        message: _searchCtrl.text.isEmpty ? '输入 Key 名称搜索全部 API Key' : '未找到匹配的 Key',
        icon: Icons.vpn_key_off_rounded,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: _keys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final k = _keys[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.vpn_key_rounded, size: 20, color: scheme.onTertiaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.name.isEmpty ? '(未命名)' : k.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14.5)),
                    const SizedBox(height: 4),
                    Text('Key #${k.id} · 归属用户 #${k.userId}',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: scheme.outline),
            ],
          ),
        );
      },
    );
  }
}
