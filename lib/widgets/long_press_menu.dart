import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/player_provider.dart';

/// Bottom sheet menu triggered by long-press on the home screen.
///
/// Contains auto-play toggle, playback speed selector, and a
/// link to the settings page.
class LongPressMenu extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onDelete;

  const LongPressMenu({
    super.key,
    required this.onOpenSettings,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Auto-play
              _MenuRow(
                icon: Icons.autorenew,
                label: '自动播放',
                subtitle: '播放完毕后自动切换到下一个视频',
                trailing: Switch(
                  value: settings.autoPlayEnabled,
                  activeTrackColor: Colors.white38,
                  activeThumbColor: Colors.white,
                  onChanged: (v) => settings.setAutoPlayEnabled(v),
                ),
              ),

              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 12),

              // Playback speed
              _MenuRow(
                icon: Icons.speed,
                label: '播放速度',
                subtitle: _speedLabel(settings.playbackSpeed),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [1.0, 1.5, 2.0].map((speed) {
                    final selected = settings.playbackSpeed == speed;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () {
                          settings.setPlaybackSpeed(speed);
                          context.read<PlayerProvider>().setSpeed(speed);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white24
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _speedLabel(speed),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 12),

              // Delete Video
              _MenuRow(
                icon: Icons.delete_outline,
                label: '删除此视频',
                subtitle: '从设备中永久删除该文件',
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF222222),
                      title: const Text('删除视频', style: TextStyle(color: Colors.white)),
                      content: const Text('确定要从设备中永久删除此视频吗？该操作不可撤销。',
                          style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('取消', style: TextStyle(color: Colors.white38)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('确定删除', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    onDelete();
                  }
                },
              ),

              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 12),

              // Settings
              _MenuRow(
                icon: Icons.settings,
                label: '设置',
                subtitle: '管理文件夹和更多选项',
                onTap: onOpenSettings,
              ),
            ],
          ),
        );
      },
    );
  }

  String _speedLabel(double speed) {
    if (speed == 1.0) return '1x';
    if (speed == 1.5) return '1.5x';
    if (speed == 2.0) return '2x';
    return '${speed}x';
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
