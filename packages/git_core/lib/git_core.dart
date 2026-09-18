/// Pure Git engine for Gitfruffen.
///
/// Exposes immutable domain entities, repository contracts, a libgit2-backed
/// datasource and the mappers between them. No Flutter UI code lives here.
library;

export 'src/data/datasources/fake_git_data_source.dart';
export 'src/data/datasources/git_credentials_data_source.dart';
export 'src/data/datasources/git_data_source.dart';
export 'src/data/datasources/libgit2_git_data_source.dart';
export 'src/data/repositories/git_repository_impl.dart';
export 'src/domain/entities/branch.dart';
export 'src/domain/entities/commit.dart';
export 'src/domain/entities/git_oid.dart';
export 'src/domain/entities/git_repository.dart';
export 'src/domain/entities/git_reset_mode.dart';
export 'src/domain/entities/reflog.dart';
export 'src/domain/entities/remote.dart';
export 'src/domain/entities/signature.dart';
export 'src/domain/entities/stash.dart';
export 'src/domain/entities/worktree.dart';
export 'src/domain/failures/git_failure.dart';
export 'src/domain/repositories/git_repository.dart';
export 'src/domain/repositories/workspace_repository.dart';
export 'src/mappers/git_object_mapper.dart';
