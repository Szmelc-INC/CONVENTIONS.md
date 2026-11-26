# Governance

This project is maintained in the open. Its current maintainer is the owner listed in [`.github/CODEOWNERS`](.github/CODEOWNERS). This document describes how contributors can take part and how changes are accepted.

## Roles

- **Contributor:** proposes changes through an issue, Discussion, or pull request. A contributor may be new to the project and does not need prior approval to open a proposal.
- **Reviewer:** checks a proposal for correctness, security, compatibility, documentation, generated-file consistency, and fit with the project. Reviewer status does not grant merge rights.
- **Maintainer:** sets project direction, resolves competing proposals, reviews outside contributions, manages releases, and merges accepted changes.

One person may hold more than one role. Maintainer status is granted by the current maintainer after a sustained record of careful contributions and an explicit agreement on release and security responsibilities. The maintainer documents any appointment in the decision log.

## Decisions

Small, reversible changes can be proposed directly in a pull request. Changes to the format, compatibility contract, governance, or release policy should start as an RFC in GitHub Discussions or an issue, then move through `CONVENTIONS/EXPERIMENTAL/` when implementation feedback is needed. Record the decision and its reason in [`CONTRIBUTING/DECISIONS.md`](CONTRIBUTING/DECISIONS.md). A maintainer makes the final decision after considering review and community feedback; silence is not approval.

## Reviews and merging

- Every change reaches `main` through a pull request.
- The required `review-gate` status passes maintainer-authored PRs and requires a maintainer approval on the latest commit of every outside PR. A new commit invalidates the earlier approval.
- CI must be green. The maintainer may request changes, approve, or close a proposal with a reason.
- Contributors and automation do not approve or merge outside PRs. See [`CONVENTIONS/GITHUB/PULL-REQUESTS.md`](CONVENTIONS/GITHUB/PULL-REQUESTS.md).
- The maintainer aims to acknowledge issues and pull requests within 48 hours. This is a target, not a guarantee; security reports follow [the security policy](.github/SECURITY.md).

## Becoming a maintainer

Contributors interested in maintaining the project can say so in a Discussion or issue. The current maintainer reviews the contributor's judgment, follow-through, and ability to review and release safely, then records any appointment in the decision log. At least two people should be able to complete a release before the project claims a bus factor above one.

## Conduct

Participation follows [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md). Reports go privately to the maintainer through the contact route in that document. The maintainer may remove content, restrict participation, or ban an account for conduct violations, and will explain the action when doing so is safe and appropriate.
