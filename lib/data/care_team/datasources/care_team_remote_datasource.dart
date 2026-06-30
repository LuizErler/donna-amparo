import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../domain/care_team/care_team_role.dart';
import '../../../domain/care_team/entities/care_invite_result.dart';
import '../../../domain/care_team/entities/care_team_member.dart';

class CareTeamRemoteDataSource {
  SupabaseClient get _client => supabase;

  Future<CareTeamRole?> getCurrentRole(String patientId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _client
        .from('care_teams')
        .select('role')
        .eq('patient_id', patientId)
        .eq('profile_id', userId)
        .not('accepted_at', 'is', null)
        .maybeSingle();

    if (row == null) return null;
    return CareTeamRole.fromCode(row['role'] as String?);
  }

  Future<List<CareTeamMember>> listMembers(String patientId) async {
    final userId = _client.auth.currentUser?.id;

    final rows = await _client
        .from('care_teams')
        .select(
          'role, accepted_at, profile_id, profiles(id, full_name, email)',
        )
        .eq('patient_id', patientId)
        .not('accepted_at', 'is', null)
        .order('created_at', ascending: true);

    return (rows as List<dynamic>).map((raw) {
      final row = raw as Map<String, dynamic>;
      final profile = row['profiles'] as Map<String, dynamic>? ?? {};
      final profileId = row['profile_id'] as String;
      return CareTeamMember(
        profileId: profileId,
        fullName: profile['full_name'] as String? ?? 'Membro',
        email: profile['email'] as String?,
        role: CareTeamRole.fromCode(row['role'] as String?) ??
            CareTeamRole.observer,
        acceptedAt: row['accepted_at'] != null
            ? DateTime.parse(row['accepted_at'] as String)
            : null,
        isCurrentUser: profileId == userId,
      );
    }).toList();
  }

  Future<CareInviteResult> createInvite({
    required String patientId,
    required CareTeamRole role,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Usuario nao autenticado.');
    }

    final row = await _client
        .from('care_invites')
        .insert({
          'patient_id': patientId,
          'role': role.code,
          'invited_by': userId,
        })
        .select('token, role, expires_at')
        .single()
        .catchError((Object error) {
      throw _mapError(error, 'Erro ao criar convite.');
    });

    return CareInviteResult(
      token: row['token'] as String,
      roleCode: row['role'] as String,
      expiresAt: DateTime.parse(row['expires_at'] as String),
    );
  }

  Future<void> acceptInvite(String token) async {
    await _client.rpc('accept_care_invite', params: {
      'p_token': token,
    }).catchError((Object error) {
      throw _mapError(error, 'Erro ao aceitar convite.');
    });
  }

  AppException _mapError(Object error, String fallback) {
    if (error is PostgrestException) {
      final message = error.message;
      if (message.contains('Convite invalido')) {
        return const AppException('Convite invalido ou nao encontrado.');
      }
      if (message.contains('Convite ja utilizado')) {
        return const AppException('Este convite ja foi utilizado.');
      }
      if (message.contains('Convite expirado')) {
        return const AppException('Este convite expirou. Peca um novo convite.');
      }
      if (message.contains('Usuario nao autenticado')) {
        return const AppException('Faca login para aceitar o convite.');
      }
      return AppException(message);
    }
    if (error is AuthException) {
      return AppException(error.message);
    }
    return AppException(fallback);
  }
}
