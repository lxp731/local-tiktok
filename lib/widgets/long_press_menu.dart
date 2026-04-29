import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/player_provider.dart';

/// Bottom sheet menu triggered by long-press on the home screen.
///
/// Contains auto-play toggle, screen-off listening toggle (with countdown sub-menu),
/// playback speed selector, delete video, and a link to the settings page.
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
                subtitle: settings.autoPlayEnabled
                    ? '播放完毕自动下一首 · 屏幕常亮'
                    : '播放完毕后自动切换到下一个视频',
                trailing: Switch(
                  value: settings.autoPlayEnabled,
                  activeTrackColor: Colors.white38,
                  activeThumbColor: Colors.white,
                  onChanged: (v) async {
                    if (v) {
                      final error = await settings.setAutoPlayEnabled(v);
                      if (error != null && context.mounted) {
                        _showConflictDialog(context, error);
                      }
                    } else {
                      await settings.setAutoPlayEnabled(v);
                    }
                  },
                ),
              ),

              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 12),

              // Screen-off Listening
              _MenuRow(
                icon: Icons.headset,
                label: '熄屏听剧',
                subtitle: settings.screenOffListeningEnabled
                    ? '熄屏后继续播放 · ${settings.screenOffTimerMinutes}分钟后暂停'
                    : '锁屏后仍可听剧，倒计时自动暂停',
                trailing: Switch(
                  value: settings.screenOffListeningEnabled,
                  activeTrackColor: Colors.white38,
                  activeThumbColor: Colors.white,
                  onChanged: (v) async {
                    if (v) {
                      final error = await settings.setScreenOffListeningEnabled(v);
                      if (error != null && context.mounted) {
                        _showConflictDialog(context, error);
                      }
                    } else {
                      await settings.setScreenOffListeningEnabled(v);
                    }
                  },
                ),
              ),

              // Countdown sub-menu — only when screen-off listening is on
              if (settings.screenOffListeningEnabled) ...[
                const SizedBox(height: 8),
                _CountdownSelector(
                  currentMinutes: settings.screenOffTimerMinutes,
                  onChanged: (minutes) {
                    settings.setScreenOffTimerMinutes(minutes);
                  },
                ),
              ],

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

  void _showConflictDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('功能冲突', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _speedLabel(double speed) {
    if (speed == 1.0) return '1x';
    if (speed == 1.5) return '1.5x';
    if (speed == 2.0) return '2x';
    return '${speed}x';
  }
}

/// A horizontal countdown timer selector shown as a sub-menu.
class _CountdownSelector extends StatelessWidget {
  final int currentMinutes;
  final ValueChanged<int> onChanged;

  const _CountdownSelector({
    required this.currentMinutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Preset options
    final options = [5, 10, 15, 20, 25, 30];

    return Container(
      margin: const EdgeInsets.only(left: 38, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              const Text(
                '倒计时',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '$currentMinutes分钟',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar style indicator
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: currentMinutes / 30.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Preset buttons
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: options.map((min) {
              final selected = currentMinutes == min;
              return GestureDetector(
                onTap: () => onChanged(min),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white24 : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: Colors.white38)
                        : null,
                  ),
                  child: Text(
                    '$min分',
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white54,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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
