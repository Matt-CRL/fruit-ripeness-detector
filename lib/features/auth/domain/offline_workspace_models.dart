/// Application-level state for the locally generated offline workspace.
///
/// The Drift row is deliberately kept behind the sync repository so callers
/// do not need to depend on generated database types.
final class OfflineWorkspaceState {
  const OfflineWorkspaceState({
    required this.workspaceId,
    required this.installationId,
    required this.generation,
    required this.pendingRelease,
    required this.updatedAt,
  });

  final String workspaceId;
  final String installationId;
  final int generation;
  final bool pendingRelease;
  final DateTime updatedAt;
}

/// Private mapping used to restore a former owner without duplicating its
/// cloud identifiers after a deliberate unlink.
final class DetachedEntityOrigin {
  const DetachedEntityOrigin({
    required this.workspaceId,
    required this.generation,
    required this.entityType,
    required this.guestEntityId,
    required this.originalOwnerId,
    required this.originalEntityId,
    required this.originalRemoteRevision,
    required this.detachedAt,
  });

  final String workspaceId;
  final int generation;
  final String entityType;
  final String guestEntityId;
  final String originalOwnerId;
  final String originalEntityId;
  final int originalRemoteRevision;
  final DateTime detachedAt;
}
