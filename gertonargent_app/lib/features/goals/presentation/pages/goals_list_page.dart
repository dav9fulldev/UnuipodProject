import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/goal_model.dart';
import '../../providers/goal_provider.dart';
import 'package:intl/intl.dart';
import 'add_goal_page.dart';

class GoalsListPage extends ConsumerStatefulWidget {
  const GoalsListPage({super.key});

  @override
  ConsumerState<GoalsListPage> createState() => _GoalsListPageState();
}

class _GoalsListPageState extends ConsumerState<GoalsListPage> {
  @override
  void initState() {
    super.initState();
    ref.read(goalProvider.notifier).loadGoals();
  }

  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A86B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mes Objectifs', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF00A86B), Color(0xFF00D084)]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCard(label: 'Objectifs actifs', value: '${goalState.activeGoals.length}', icon: Icons.flag),
                    _StatCard(label: 'Completes', value: '${goalState.completedGoals.length}', icon: Icons.check_circle),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total economise', style: TextStyle(color: Colors.white, fontSize: 14)),
                          Text('${NumberFormat('#,###').format(goalState.totalSavedAmount)} FCFA', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Objectif total', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${NumberFormat('#,###').format(goalState.totalTargetAmount)} FCFA', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: goalState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : goalState.activeGoals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flag_outlined, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Aucun objectif', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            Text('Creez votre premier objectif', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(goalProvider.notifier).loadGoals(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: goalState.activeGoals.length,
                          itemBuilder: (context, index) {
                            final goal = goalState.activeGoals[index];
                            return _GoalCard(goal: goal);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddGoalPage()));
          ref.read(goalProvider.notifier).loadGoals();
        },
        backgroundColor: const Color(0xFF00A86B),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final percentage = goal.progress;
    final daysLeft = goal.daysRemaining ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.statusIcon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (goal.targetDate != null)
                      Text('Echeance: ${DateFormat('dd/MM/yyyy').format(goal.targetDate!)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (goal.targetDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: daysLeft < 30 ? Colors.red.withOpacity(0.1) : const Color(0xFF00A86B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$daysLeft jours', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: daysLeft < 30 ? Colors.red : const Color(0xFF00A86B))),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${NumberFormat('#,###').format(goal.currentAmount)} FCFA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00A86B))),
              Text('${NumberFormat('#,###').format(goal.targetAmount)} FCFA', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(percentage >= 80 ? const Color(0xFF00A86B) : percentage >= 50 ? Colors.orange : Colors.red),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${percentage.toStringAsFixed(1)}% atteint', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Reste: ${NumberFormat('#,###').format(goal.remainingAmount)} FCFA', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
