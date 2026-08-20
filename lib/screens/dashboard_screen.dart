import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/repository.dart';
import '../widgets/widgets.dart';
import 'system_screen.dart';
import 'api_key_screen.dart';
import 'usage_screen.dart';
import 'user_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Repository _repo;
  DashboardData? _data;
  RealtimeTraffic? _realtime;
  List<ThroughputPoint> _throughput = [];
  LatencyHistogram? _latency;
  String? _error;
  bool _loading = true;
  bool _rtLoading = false;
  Timer? _rtTimer;

  @override
  void initState() {
    super.initState();
    _repo = Repository(context.read<AppState>().api);
    _load();
    _startRealtime();
  }

  @override
  void dispose() {
    _rtTimer?.cancel();
    super.dispose();
  }

  void _startRealtime() {
    _rtTimer = Timer.periodic(const Duration(seconds: 20), (_) => _refreshRealtime());
  }

  Future<void> _refreshRealtime() async {
    if (_rtLoading) return;
    setState(() => _rtLoading = true);
    try {
      final rt = await _repo.realtime();
      if (mounted) setState(() => _realtime = rt);
    } catch (_) {} finally {
      if (mounted) setState(() => _rtLoading = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.dashboard(),
        _repo.realtime(),
        _repo.throughput(),
        _repo.latency(),
      ]);
      if (mounted) {
        setState(() {
          _data = results[0] as DashboardData;
          _realtime = results[1] as RealtimeTraffic;
          _throughput = results[2] as List<ThroughputPoint>;
          _latency = results[3] as LatencyHistogram;
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
        title: const Text('实时总览'),
        actions: [
          IconButton(
            tooltip: '实时用量',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsageScreen())),
            icon: const Icon(Icons.account_balance_wallet_rounded),
          ),
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
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _data == null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final data = _data!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        _RealtimeHero(realtime: _realtime),
        const SizedBox(height: 14),
        _QuickTiles(onUsage: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsageScreen()))),
        const SizedBox(height: 18),
        _KpiRow(stats: data.stats),
        const SizedBox(height: 20),
        if (_throughput.isNotEmpty) ...[
          const SectionHeader(title: '吞吐 · Token/秒'),
          const SizedBox(height: 12),
          _ThroughputChart(points: _throughput),
          const SizedBox(height: 20),
        ],
        if (_latency != null && _latency!.buckets.isNotEmpty) ...[
          const SectionHeader(title: '响应延迟分布'),
          const SizedBox(height: 12),
          _LatencyChart(hist: _latency!),
          const SizedBox(height: 20),
        ],
        const SectionHeader(title: '模型用量排行'),
        const SizedBox(height: 12),
        _RankList(items: data.models.take(6).toList()),
        const SizedBox(height: 22),
        const SectionHeader(title: '分组用量'),
        const SizedBox(height: 12),
        _RankList(items: data.groups.take(6).toList()),
        if (data.userRanking.isNotEmpty) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: '用户消耗 Top'),
          const SizedBox(height: 12),
          _UserRankList(items: data.userRanking),
        ],
      ],
    );
  }
}

class _RealtimeHero extends StatelessWidget {
  final RealtimeTraffic? realtime;
  const _RealtimeHero({this.realtime});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rt = realtime;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: scheme.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text('实时吞吐 · Token/秒',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2EFF8F), shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('LIVE',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, letterSpacing: 1)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rt != null ? fmtCompact(rt.tpsCurrent) : '--',
                  style: const TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w800, height: 1)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('tokens/s',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _subStat('峰值', rt?.tpsPeak, rt != null ? fmtCompact(rt.tpsPeak) : '--'),
              _subStat('平均', rt?.tpsAvg, rt != null ? fmtCompact(rt.tpsAvg) : '--'),
              _subStat('QPS', rt?.qpsCurrent, rt != null ? rt.qpsCurrent.toStringAsFixed(1) : '--'),
              _subStat('窗口', rt?.window, rt?.window ?? '--'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subStat(String label, Object? v, String display) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
        const SizedBox(height: 3),
        Text(display, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  final DashboardSnapshot stats;
  const _KpiRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
              label: '今日请求', value: '${fmtNum(stats.todayRequests)}', icon: Icons.trending_up_rounded,
              color: const Color(0xFF5C6BC0), sub: '总 ${fmtCompact(stats.totalRequests)}'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiTile(
              label: '今日消耗', value: '¥${stats.todayCost.toStringAsFixed(2)}', icon: Icons.paid_rounded,
              color: const Color(0xFF26A69A), sub: '总 ¥${stats.totalCost.toStringAsFixed(2)}'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiTile(
              label: '今日 Token', value: fmtCompact(stats.todayInputTokens + stats.todayOutputTokens),
              icon: Icons.token_rounded, color: const Color(0xFF8E24AA), sub: '总 ${fmtCompact(stats.totalTokens)}'),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String sub;
  const _KpiTile({required this.label, required this.value, required this.icon, required this.color, required this.sub});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurface, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
          const SizedBox(height: 2),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 10)),
        ],
      ),
    );
  }
}

class _ThroughputChart extends StatelessWidget {
  final List<ThroughputPoint> points;
  const _ThroughputChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = points.take(60).toList();
    final tpsSpots = visible.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.tps)).toList();
    final maxTps = tpsSpots.fold<double>(0, (a, s) => s.y > a ? s.y : a);
    final qpsSpots = visible.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.qps)).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 14, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      height: 210,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxTps == 0 ? 10 : maxTps * 1.1,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxTps == 0 ? 10 : (maxTps / 4),
            getDrawingHorizontalLine: (v) =>
                FlLine(color: scheme.outlineVariant.withValues(alpha: 0.25), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= visible.length) return const SizedBox();
                  if (idx % 10 != 0) return const SizedBox();
                  final t = visible[idx].bucketStart;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${t.hour}:${_2(t.minute)}', style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: tpsSpots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: scheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [scheme.primary.withValues(alpha: 0.28), scheme.primary.withValues(alpha: 0.0)],
                ),
              ),
            ),
            LineChartBarData(
              spots: qpsSpots.isEmpty ? const [] : qpsSpots.map((s) => FlSpot(s.x, s.y * (maxTps == 0 ? 1 : (maxTps / 5)))).toList(),
              isCurved: true,
              curveSmoothness: 0.25,
              color: const Color(0xFFFFB74D),
              barWidth: 2,
              dashArray: [5, 4],
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  String _2(int v) => v.toString().padLeft(2, '0');
}

class _LatencyChart extends StatelessWidget {
  final LatencyHistogram hist;
  const _LatencyChart({required this.hist});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final buckets = hist.buckets;
    final maxCount = buckets.fold<int>(0, (acc, b) => b.count > acc ? b.count : acc);
    final colors = [
      const Color(0xFF2ECC71), const Color(0xFF58D68D), const Color(0xFFF39C12),
      const Color(0xFFF5B041), const Color(0xFFE67E22), const Color(0xFFE74C3C),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      height: 150,
      child: BarChart(
        BarChartData(
          maxY: (maxCount == 0 ? 1 : maxCount) * 1.1,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= buckets.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SizedBox(
                      width: 60,
                      child: Text(buckets[idx].range, textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 8.5, color: scheme.onSurfaceVariant)),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(buckets.length, (i) {
            final b = buckets[i];
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: b.count.toDouble(), width: 18, color: colors[i % colors.length], borderRadius: BorderRadius.circular(5)),
            ]);
          }),
        ),
      ),
    );
  }
}

class _QuickTiles extends StatelessWidget {
  final VoidCallback onUsage;
  const _QuickTiles({required this.onUsage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _quickTile(context, scheme, '实时用量', Icons.account_balance_wallet_rounded, const Color(0xFF26A69A), onUsage),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickTile(context, scheme, '系统健康', Icons.monitor_heart_rounded, const Color(0xFF5C6BC0),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemScreen()))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickTile(context, scheme, 'API Key', Icons.vpn_key_rounded, const Color(0xFFEF6C00),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiKeyScreen()))),
        ),
      ],
    );
  }

  Widget _quickTile(BuildContext context, ColorScheme scheme, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: scheme.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _RankList extends StatelessWidget {
  final List<RankItem> items;
  const _RankList({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (items.isEmpty) return const EmptyState(message: '暂无数据');
    final maxTokens = items.map((e) => e.tokens).reduce((a, b) => a > b ? a : b);
    final medal = [const Color(0xFFF6B93B), Colors.blueGrey, const Color(0xFFB87333)];
    return Column(
      children: List.generate(items.length, (i) {
        final item = items[i];
        final frac = maxTokens == 0 ? 0.0 : (item.tokens / maxTokens).clamp(0.03, 1.0);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26, height: 26, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i < 3 ? medal[i].withValues(alpha: 0.18) : scheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            color: i < 3 ? medal[i] : scheme.onSurfaceVariant, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13.5)),
                  ),
                  Text('${fmtCompact(item.tokens)} tk', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
                  const SizedBox(width: 10),
                  Text('¥${item.cost.toStringAsFixed(2)}',
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: frac, minHeight: 5,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(scheme.primary),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _UserRankList extends StatelessWidget {
  final List<UserRankItem> items;
  const _UserRankList({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final medal = [const Color(0xFFF6B93B), Colors.blueGrey, const Color(0xFFB87333)];
    return Column(
      children: List.generate(items.length, (i) {
        final it = items[i];
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailScreen(userId: it.userId))),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i < 3 ? medal[i].withValues(alpha: 0.18) : scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: TextStyle(
                          color: i < 3 ? medal[i] : scheme.onSurfaceVariant, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.email.isEmpty ? '用户 #${it.userId}' : it.email,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text('${fmtNum(it.requests)} 次 · ${fmtCompact(it.tokens)} tokens',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
                    ],
                  ),
                ),
                Text('¥${it.actualCost.toStringAsFixed(2)}',
                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 13.5)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 18, color: scheme.outline),
              ],
            ),
          ),
        );
      }),
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
