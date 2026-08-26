# Source race report

Updated: 2026-08-26

Phase 1 implements and tests the source-neutral adapter contract, candidate
normalization/matching, independent deadlines, progressive partial results,
cross-source deduplication, and bounded overall completion.

| Source | Search | Match | FLAC | Permission | Result |
|---|---|---|---|---|---|
| Monochrome | Existing single-source adapter; migration pending | Existing metadata | Browser path | User authorization required when challenged | DEGRADED |
| Jamendo | Adapter pending client ID configuration | Pending | API documents FLAC | Must require `audiodownload_allowed=true` | NOT CONFIGURED |
| Internet Archive | Adapter pending | Pending | Item-dependent | Public unrestricted files only | NOT IMPLEMENTED |
| Wikimedia Commons | Adapter pending | Pending | File-dependent | Preserve item license/attribution | NOT IMPLEMENTED |
| Open Audio | Architecture reference only | Pending | Source-dependent | Per-source permission | NOT IMPLEMENTED |

No live source is allowed into an acquisition race until its permission and
FLAC-resolution rules have focused tests.
