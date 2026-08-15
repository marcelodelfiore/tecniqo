# ADR-0002: Invitation-Only Account Provisioning

- **Status:** accepted
- **Date:** 2026-08-15
- **Decision owners:** Técniqo engineering
- **Related issue/PR:** Phase 1 — Membership provisioning

## Context

The original passwordless sign-in flow created a global User for every unknown email.
Once Organization membership controls product access, open identity registration creates
orphan identities and can conflict with an intentional organization invitation lifecycle.

## Decision drivers

- Keep organization access intentional and administrator-controlled.
- Preserve generic sign-in responses and avoid account enumeration.
- Reuse the existing passwordless, digest-only token security pattern.
- Support invitations for both new and existing global identities.
- Keep Founder provisioning exceptional and outside normal organization roles.

## Considered options

### Open registration with later membership assignment

- Advantages: minimal sign-in friction and no invitation token lifecycle.
- Disadvantages: creates identities without tenant access and weakens onboarding control.
- Risks: users may believe they have access when no organization has provisioned them.

### Invitation-only provisioning

- Advantages: ties identity creation to explicit organization access and assigned roles.
- Disadvantages: requires invitation issuance, delivery, expiry, revocation, and acceptance.
- Risks: delivery failures can block onboarding; invitations therefore remain reissuable.

## Decision

Técniqo will use invitation-only account provisioning for ordinary users. Unknown emails
and legacy users without membership history receive the same generic sign-in response but
no User, token, or email. Founder remains the explicit platform exception.

Invitation tokens store only a SHA-256 digest, expire after seven days, and are single-use.
The emailed GET only confirms the invitation; a CSRF-protected POST atomically creates or
reuses the User, creates or reactivates the Membership, grants the invited fixed roles,
marks the invitation accepted, and establishes the authenticated session.

## Rationale

Invitation-only provisioning aligns identity creation with tenant access while preserving
the existing global User model and passwordless authentication architecture.

## Consequences

### Positive

- Ordinary identities are not created without an organization provisioning event.
- Invited roles and tenant access are established in one transaction.
- Existing Users can join additional Organizations without duplicate identities.

### Negative

- Administrators need an invitation management workflow.
- Email delivery becomes part of initial onboarding.

### Risks and mitigations

- **Token leakage** — store only a digest, expire tokens, use no-store/no-referrer
  confirmation responses, and consume through POST.
- **Account enumeration** — return the same sign-in response for eligible and ineligible emails.
- **Duplicate invitations** — revoke prior active invitations for the same organization/email.
- **Role tampering** — validate roles in Rails and enforce the fixed vocabulary in PostgreSQL.

## Validation

Model and request specs cover normalization, expiry, revocation, single use, database role
constraints, new and existing identities, membership activation, role grants, generic
unknown-email behavior, Founder access, and preservation of passwordless sign-in.

## Revisit conditions

Reconsider this decision when:

- self-service trials or public organization creation become a product requirement;
- a trusted external identity provider owns provisioning;
- invitation delivery reliability requires an alternative onboarding channel.
