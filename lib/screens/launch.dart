import 'package:flutter/material.dart';
import '../theme.dart';
import '../ui.dart';
import 'shell.dart';

class LaunchGate extends StatelessWidget {
  const LaunchGate({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AquaBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const FxFHeader(),
                const SizedBox(height: 14),
                Text('启动前提示', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 16),
                const AnimeArtworkCard(
                  asset: 'assets/characters/mascot_idle.webp',
                  height: 390,
                  alignment: Alignment(0, -.15),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    _RiskChip(Icons.sentiment_dissatisfied_rounded, 'FOMO'),
                    _RiskChip(Icons.balance_rounded, '过度杠杆'),
                    _RiskChip(Icons.bolt_rounded, '报复交易'),
                    _RiskChip(Icons.query_stats_rounded, '参数过拟合'),
                    _RiskChip(Icons.water_drop_outlined, '流动性风险'),
                    _RiskChip(Icons.bedtime_outlined, '夜间交易'),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainShell()),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: FxFColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('进入 FxF'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RiskChip extends StatelessWidget {
  const _RiskChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: (MediaQuery.sizeOf(context).width - 53) / 2,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(children: [
            Icon(icon, color: FxFColors.primaryDark),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: FxFColors.ink)),
          ]),
        ),
      );
}
