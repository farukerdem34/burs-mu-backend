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
              final scholarship = scholarships.where(
                (s) => s.id == match.scholarshipId,
              ).firstOrNull;

              return _MatchCard(
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
  final String title;
  final VoidCallback? onTap;

  const _MatchCard({
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        title: Container(
          height: 15,
          width: 180,
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
