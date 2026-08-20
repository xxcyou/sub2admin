import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/repository.dart';
import '../widgets/dialogs.dart';
import '../widgets/widgets.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late final Repository _repo;
  UserItem? _user;
  bool _loading = true;
  bool _busy = false;
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
      final u = await _repo.userDetail(widget.userId);
      if (mounted) setState(() => _user = u);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _run(Future<void> Function() action, {String ok = '操作成功'}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      if (mounted) _toast(ok);
    } catch (e) {
      if (mounted) _toast(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleStatus() async {
    final u = _user!;
    final target = u.status == 'active' ? 'disabled' : 'active';
    final ok = await confirmDialog(
      context,
      title: '切换状态',
      message: target == 'active' ? '启用该用户？' : '禁用该用户？禁用后其 API Key 将无法调用。',
    );
    if (!ok) return;
    await _run(() async {
      await _repo.updateUser(u.id, {'status': target});
    }, ok: target == 'active' ? '已启用' : '已禁用');
  }

  Future<void> _editUser() async {
    final u = _user!;
    final nameCtl = TextEditingController(text: u.username);
    final concurCtl = TextEditingController(text: u.concurrency.toString());
    final notesCtl = TextEditingController(text: u.notes);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑用户'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtl, decoration: const InputDecoration(labelText: '用户名')),
              const SizedBox(height: 12),
              TextField(
                  controller: concurCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '并发数')),
              const SizedBox(height: 12),
              TextField(controller: notesCtl, decoration: const InputDecoration(labelText: '备注')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    await _run(() async {
      await _repo.updateUser(u.id, {
        'username': nameCtl.text,
        'concurrency': int.tryParse(concurCtl.text) ?? 1,
        'notes': notesCtl.text,
      });
    });
  }

  Future<void> _deleteUser() async {
    final u = _user!;
    final ok = await confirmDialog(
      context,
      title: '删除用户',
      message: '确定要彻底删除用户 ${u.email} 吗？此操作不可恢复，其所有数据将被清除。',
      confirmText: '删除',
      confirmColor: const Color(0xFFE74C3C),
    );
    if (!ok) return;
    await _run(() async {
      await _repo.deleteUser(u.id);
    }, ok: '用户已删除');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('用户详情')),
      body: _buildBody(scheme),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    if (_loading && _user == null) return const Center(child: CircularProgressIndicator());
    if (_error != null && _user == null) {
      return Center(child: Text(_error!, style: TextStyle(color: scheme.onSurfaceVariant)));
    }
    final u = _user!;
    final sc = statusColor(u.status, context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Header card
          DetailCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    u.email.isEmpty ? '?' : u.email[0].toUpperCase(),
                    style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.email,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 4),
                      Row(children: [
                        StatusChip(text: u.status, color: sc),
                        const SizedBox(width: 8),
                        Text(u.role, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Balance
          DetailCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('当前余额', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('¥${u.balance.toStringAsFixed(4)}',
                          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 24)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('冻结', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('¥${u.frozenBalance.toStringAsFixed(2)}',
                          style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 20)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('并发', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${u.concurrency}',
                          style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 20)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const DetailSection(title: '基本信息'),
          const SizedBox(height: 8),
          DetailCard(
            child: Column(
              children: [
                DetailRow(icon: Icons.people_alt_rounded, label: 'ID', value: '#${u.id}'),
                const Divider(height: 1),
                DetailRow(icon: Icons.mail_rounded, label: '邮箱', value: u.email),
                const Divider(height: 1),
                DetailRow(icon: Icons.badge_rounded, label: '用户名', value: u.username.isEmpty ? '-' : u.username),
                const Divider(height: 1),
                DetailRow(icon: Icons.calendar_today_rounded, label: '注册时间',
                    value: fmtDateTime(u.createdAt)),
                const Divider(height: 1),
                DetailRow(icon: Icons.schedule_rounded, label: '最后活跃',
                    value: fmtDateTime(u.lastActive)),
                if (u.notes.isNotEmpty) ...[
                  const Divider(height: 1),
                  DetailRow(icon: Icons.notes_rounded, label: '备注', value: u.notes),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          const DetailSection(title: '管理操作'),
          const SizedBox(height: 10),
          Column(
            children: [
              ActionButton(
                label: u.status == 'active' ? '禁用该用户' : '启用该用户',
                icon: u.status == 'active' ? Icons.block_rounded : Icons.check_circle_rounded,
                onPressed: _toggleStatus,
                loading: _busy,
                color: u.status == 'active' ? const Color(0xFFF39C12) : const Color(0xFF2ECC71),
              ),
              const SizedBox(height: 10),
              ActionButton(
                label: '编辑用户信息',
                icon: Icons.edit_rounded,
                onPressed: _editUser,
                loading: _busy,
              ),
              const SizedBox(height: 10),
              ActionButton(
                label: '删除用户',
                icon: Icons.delete_forever_rounded,
                onPressed: _deleteUser,
                loading: _busy,
                destructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String fmtDateTime(DateTime? d) {
    if (d == null) return '-';
    return '${d.year}-${_2(d.month)}-${_2(d.day)} ${_2(d.hour)}:${_2(d.minute)}';
  }

  String _2(int v) => v.toString().padLeft(2, '0');
}

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const DetailRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(width: 72, child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
          Expanded(
            child: Text(value, textAlign: TextAlign.right,
                style: TextStyle(color: scheme.onSurface, fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
