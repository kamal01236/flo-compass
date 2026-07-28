import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

export 'confirm_dialog.dart';

import 'package:flo_compass/l10n/app_localizations.dart';

import '../../theme/app_theme.dart';
import '../../utils/friendly_error_messages.dart';

class GradientTitle extends StatelessWidget {
  const GradientTitle(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolved = (style ?? Theme.of(context).textTheme.titleLarge)
        ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.accentStart);
    if (kIsWeb) {
      return Text(text, style: resolved);
    }
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
      child: Text(text, style: resolved?.copyWith(color: Colors.white)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.semanticsLabel,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final headline = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              AppTheme.accentGradient.createShader(bounds),
          child: Icon(icon, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            style: TextStyle(color: muted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (semanticsLabel == null)
          headline
        else
          ExcludeSemantics(child: headline),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    );

    if (semanticsLabel == null) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(32), child: column),
      );
    }

    return Semantics(
      container: true,
      label: semanticsLabel,
      explicitChildNodes: true,
      child: Center(
        child: Padding(padding: const EdgeInsets.all(32), child: column),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.kind = FriendlyErrorKind.loadFailure,
    this.technicalDetail,
    this.onRetry,
    this.random,
    this.retryLabel,
    this.secondaryAction,
  });

  final FriendlyErrorKind kind;
  final String? technicalDetail;
  final VoidCallback? onRetry;
  final Random? random;
  final String? retryLabel;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final copy = FriendlyErrorCopy.random(kind, random: random);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final headline = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              AppTheme.accentGradient.createShader(bounds),
          child: const Icon(Icons.error_outline, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          copy.title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          copy.message,
          style: TextStyle(color: muted),
          textAlign: TextAlign.center,
        ),
        if (kDebugMode &&
            technicalDetail != null &&
            technicalDetail!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            technicalDetail!,
            style: TextStyle(color: muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    final l10n = AppLocalizations.of(context);
    final retry = onRetry == null
        ? null
        : FilledButton(
            onPressed: onRetry,
            child: Text(retryLabel ?? l10n.retry),
          );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: headline),
        if (retry != null || secondaryAction != null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [?retry, ?secondaryAction],
          ),
        ],
      ],
    );

    return Semantics(
      container: true,
      label: copy.semanticLabel,
      explicitChildNodes: true,
      child: Center(
        child: Padding(padding: const EdgeInsets.all(32), child: column),
      ),
    );
  }
}

class AiBadge extends StatelessWidget {
  const AiBadge({super.key, required this.enhanced});

  final bool enhanced;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: enhanced ? 'AI enhanced response' : 'Using local search',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: enhanced
              ? AppColors.accentStart.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enhanced ? AppColors.accentStart : Colors.orange,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              enhanced ? Icons.auto_awesome : Icons.search,
              size: 14,
              color: enhanced ? AppColors.accentStart : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              enhanced ? 'AI enhanced' : 'Local search',
              style: TextStyle(
                fontSize: 12,
                color: enhanced ? AppColors.accentStart : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key, required this.child, this.maxWidth = 960});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
