import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/scholarship_provider.dart';

class MatchResultScreen extends ConsumerWidget {
  final String? studentId;

  const MatchResultScreen({super.key, this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final id = studentId ?? authState.token;

    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Eşleşme Sonuçları')),
        body: const Center(child: Text('Oturum açmanız gerekiyor')),
      );
    }

    final matchesAsync = ref.watch(matchResultsProvider(id));
    final scholarshipsAsync = ref.watch(scholarshipListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Eşleşme Sonuçları')),
      body: matchesAsync.when(
        loading: () => const _MatchSkeleton(),
        error: (e, _) => _MatchError(
          message: e.toString(),
          onRetry: () => ref.invalidate(matchResultsProvider(id)),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return const _MatchEmpty();
          }

          final scholarships = scholarshipsAsync.valueOrNull ?? [];

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final rank = index + 1;
              final score = match.score ?? 0;
              final scholarship = scholarships.where(
                (s) => s.id == match.scholarshipId,
              ).firstOrNull;

              return _MatchCard(
                rank: rank,
                score: score,
                title: scholarship?.title ?? 'Burs #${match.scholarshipId?.substring(0, 8) ?? '-'}',
                onTap: match.scholarshipId != null
                    ? () => context.push('/scholarships/${match.scholarshipId}')
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final int rank;
  final double score;
  final String title;
  final VoidCallback? onTap;

  const _MatchCard({
    required this.rank,
    required this.score,
    required this.title,
    this.onTap,
  });

  Color _scoreColor(BuildContext context) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.amber.shade700;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final scorePercent = (score * 100).toInt();
    final color = _scoreColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Center(
                  child: rank <= 3
                      ? Text(
                          ['🥇', '🥈', '🥉'][rank - 1],
                          style: const TextStyle(fontSize: 24),
                        )
                      : Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: score,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        color: color,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '%$scorePercent',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchEmpty extends StatelessWidget {
  const _MatchEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Uygun Burs Bulunamadı',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Profilinize uygun burs bulunamadı. '
              'Profil bilgilerinizi güncelleyerek daha fazla bursa erişebilirsiniz.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MatchError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 72,
              color: theme.colorScheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Bir Hata Oluştu',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Eşleşme sonuçları yüklenirken bir sorun oluştu. '
              'Lütfen tekrar deneyin.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchSkeleton extends StatelessWidget {
  const _MatchSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (_, index) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
        child: Row(
          children: [
            const SizedBox(
              width: 48,
              child: Center(
                child: _ShimmerBox(width: 20, height: 16),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ShimmerBox(width: 180, height: 15),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _ShimmerBox(
                      width: double.infinity,
                      height: 6,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const _ShimmerBox(width: 48, height: 26, borderRadius: 8),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? color;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 4,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
