<?php

namespace App\Services\Workflow;

use App\Models\ApprovalAction;
use App\Models\ApprovalRequest;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ApprovalRoutingService
{
    public function approve(ApprovalRequest $request, User $user): ApprovalRequest
    {
        return DB::transaction(function () use ($request, $user) {
            $request->loadMissing('workflow', 'workflow.levels');

            if (! in_array($request->status, ['pending', 'in_progress'], true)) {
                throw ValidationException::withMessages([
                    'approval' => 'Approval request is not in an approvable state.',
                ]);
            }

            $level = $request->workflow->levels()
                ->where('level_order', $request->current_level)
                ->first();

            if (! $level) {
                throw ValidationException::withMessages([
                    'approval' => 'Approval level is missing for this request.',
                ]);
            }

            if (! $this->isApproverAllowed($level->approver_type, $level->approver_identifier, $user)) {
                throw new AuthorizationException('User is not authorized to approve this level.');
            }

            ApprovalAction::create([
                'approval_request_id' => $request->id,
                'approval_level_id' => $level->id,
                'user_id' => $user->id,
                'level_order' => $level->level_order,
                'action' => 'approved',
                'action_date' => now(),
                'comments' => 'Approved via routing service',
            ]);

            $request->approvals_received = (int) $request->approvals_received + 1;

            if ((int) $request->current_level >= (int) $request->total_levels) {
                $request->status = 'approved';
                $request->completed_at = now();
            } else {
                $request->current_level = (int) $request->current_level + 1;
                $request->status = 'in_progress';
            }

            $request->save();

            return $request;
        });
    }

    private function isApproverAllowed(string $type, ?string $identifier, User $user): bool
    {
        if ($type === 'role' && $identifier) {
            return $user->hasRole($identifier);
        }

        if ($type === 'user' || $type === 'specific_user') {
            return (string) $user->id === (string) $identifier;
        }

        return true;
    }
}
