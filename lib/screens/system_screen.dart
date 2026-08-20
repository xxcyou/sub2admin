import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/repository.dart';
import '../widgets/dialogs.dart';

class SystemScreen extends StatefulWidget {
  const SystemScreen({super.key});

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  late final Repository _repo;
  SystemHealth? _health;
  VersionInfo? _version;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = Repository(context.read<AppState>().api);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_repo.systemHealth(), _repo.version(), _repo.checkUpdates()]);
      if (mounted) {
        setState(() {
          _health = results[0] as SystemHealth;
          _version = results[1] as VersionInfo;
          final upd = results[2] as VersionInfo;
          if (upd.hasUpdate || upd.current.isNotEmpty) _version = upd;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统'),
        actions: [
          IconButton(tooltip: '刷新', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading && _health == null) return const Center(child: CircularProgressIndicator());
    if (_error != null && _health == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_rounded, size: 52, color: scheme.outline),
            const SizedBox(height: 14),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('重试')),
          ]),
        ),
      );
    }

    final h = _health!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // Health score
        DetailCard(
          child: Column(
            children: [
              const SizedBox(height: 6),
              _HealthGauge(score: h.healthScore),
              const SizedBox(height: 6),
              Text('系统健康度', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MiniStatus(ok: h.dbOk, label: '数据库', icon: Icons.storage_rounded),
                  _MiniStatus(ok: h.redisOk, label: 'Redis', icon: Icons.memory_rounded),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        const DetailSection(title: '资源占用'),
        const SizedBox(height: 8),
        DetailCard(
          child: Column(
            children: [
              _ResourceBar(
                icon: Icons.speed_rounded,
                label: 'CPU 使用率',
                value: h.cpuUsagePercent,
                display: '${h.cpuUsagePercent.toStringAsFixed(1)}%',
                color: _resourceColor(h.cpuUsagePercent),
              ),
              const Divider(height: 24),
              _ResourceBar(
                icon: Icons.memory_rounded,
                label: '内存使用率',
                value: h.memoryTotalMb > 0 ? (h.memoryUsedMb / h.memoryTotalMb * 100) : 0,
                display: '${h.memoryUsedMb} MB / ${h.memoryTotalMb} MB',
                color: _resourceColor(h.memoryTotalMb > 0 ? (h.memoryUsedMb / h.memoryTotalMb * 100) : 0),
              ),
              const Divider(height: 24),
              DetailRow2(icon: Icons.linear_scale_rounded, label: '协程数', value: '${fmtNum(h.goroutineCount)}'),
              const Divider(height: 1),
              DetailRow2(icon: Icons.queue_rounded, label: '并发队列', value: '${fmtNum(h.concurrencyQueueDepth)}'),
              const Divider(height: 1),
              DetailRow2(icon: Icons.swap_horiz_rounded, label: '账号切换', value: '${fmtNum(h.accountSwitchCount)}'),
            ],
          ),
        ),
        const SizedBox(height: 22),

        if (_version != null) ...[
          const DetailSection(title: '系统信息'),
          const SizedBox(height: 8),
          DetailCard(
            child: Column(
              children: [
                DetailRow2(icon: Icons.info_rounded, label: '当前版本', value: _version!.current),
                if (_version!.hasUpdate && _version!.latest != null) ...[
                  const Divider(height: 1),
                  DetailRow2(
                    icon: Icons.system_update_alt_rounded,
                    label: '最新版本',
                    value: _version!.latest!,
                    valueColor: const Color(0xFF2ECC71),
                  ),
                ],
              ],
            ),
          ),
          if (_version!.hasUpdate) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF39C12).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF39C12).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.new_releases_rounded, color: Color(0xFFF39C12)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('发现新版本 ${_version!.latest}，建议前往 Web 控制台更新。',
                        style: const TextStyle(color: Color(0xFFB68000), fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Color _resourceColor(double v) {
    if (v < 60) return const Color(0xFF2ECC71);
    if (v < 85) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }
}

class _HealthGauge extends StatelessWidget {
  final int score;
  const _HealthGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = score >= 80
        ? const Color(0xFF2ECC71)
        : score >= 50
            ? const Color(0xFFF39C12)
            : const Color(0xFFE74C3C);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 11,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$score', style: TextStyle(color: color, fontSize: 34, fontWeight: FontWeight.w800)),
            Text('/100', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _MiniStatus extends StatelessWidget {
  final bool ok;
  final String label;
  final IconData icon;
  const _MiniStatus({required this.ok, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ok ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 2),
        Text(ok ? '正常' : '异常', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

class _ResourceBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String display;
  final Color color;
  const _ResourceBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.display,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          const Spacer(),
          Text(display, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class DetailRow2 extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const DetailRow2({super.key, required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        SizedBox(width: 80, child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
        const Spacer(),
        Text(value, style: TextStyle(color: valueColor ?? scheme.onSurface, fontSize: 13.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
