import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/screen_utils.dart';
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
            padding: EdgeInsets.symmetric(vertical: context.h(8)),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final scholarship = scholarships.where(
                (s) => s.id == match.scholarshipId,
              ).firstOrNull;

              final score = match.score;
              return _MatchCard(
                title: scholarship?.title ?? 'Burs #${match.scholarshipId?.substring(0, 8) ?? '-'}',
                score: score,
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
  final String title;
  final double? score;
  final VoidCallback? onTap;

  const _MatchCard({
    required this.title,
    this.score,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayScore = score != null ? score!.round() : null;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(5)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.school_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (displayScore != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(4)),
                decoration: BoxDecoration(
                  color: _scoreColor(displayScore, theme).withAlpha(25),
                  borderRadius: BorderRadius.circular(context.w(12)),
                ),
                child: Text(
                  '$displayScore',
                  style: TextStyle(
                    color: _scoreColor(displayScore, theme),
                    fontWeight: FontWeight.w700,
                    fontSize: context.f(13),
                  ),
                ),
              ),
            SizedBox(width: context.w(4)),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _scoreColor(int score, ThemeData theme) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.amber.shade700;
    return Colors.orange;
  }
}

class _MatchEmpty extends StatelessWidget {
  const _MatchEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.w(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: context.f(72),
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            SizedBox(height: context.h(16)),
            Text(
              'Uygun Burs Bulunamadı',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.h(8)),
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
        padding: EdgeInsets.all(context.w(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: context.f(72),
              color: theme.colorScheme.error.withValues(alpha: 0.6),
            ),
            SizedBox(height: context.h(16)),
            Text(
              'Bir Hata Oluştu',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.h(8)),
            Text(
              'Eşleşme sonuçları yüklenirken bir sorun oluştu. '
              'Lütfen tekrar deneyin.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: context.h(24)),
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
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
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
      margin: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(5)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        title: Container(
          height: context.h(15),
          width: context.w(180),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
