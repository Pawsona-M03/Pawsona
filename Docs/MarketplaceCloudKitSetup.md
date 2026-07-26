# Marketplace CloudKit Setup

The marketplace uses `CKContainer.default().publicCloudDatabase` in the existing
`iCloud.com.nathansudiara.Pawsona` container. Owned puppies, reminders,
vaccination records, notes, and scans remain in SwiftData/private CloudKit.

Do not change the app's team, bundle identifier, entitlements, or container to
set this up. Do not deploy the production schema until the development
environment has been reviewed and tested.

## Security model

Configure record-type permissions in CloudKit Dashboard using the strongest
available record-level roles:

| Record type | World | Authenticated (`_icloud`) | Creator (`_creator`) |
| --- | --- | --- | --- |
| `MarketplaceListing` | Read | Create | Read, write, delete |
| `SellerProfile` | Read | Create | Read, write, delete |
| `SellerContact` | None | Read, create | Read, write, delete |
| `MarketplaceReport` | None | Create only | No app read is required |

Important limitations:

- CloudKit public-database security is record-level, not field-level. It cannot
  make one field private while leaving the rest of a record world-readable.
  This is why `SellerContact` is a separate record type.
- Authenticated read on `SellerContact` means any authenticated iCloud user who
  knows or queries an allowed contact record can read that record. The app
  reveals it only after an explicit Contact Seller action, but client UI is not
  a server-side authorization boundary.
- Creator permissions are enforced by CloudKit. The repository also loads the
  server record and compares its system `creatorUserRecordID` with
  `CKContainer.userRecordID()` before listing updates or deletion. A seller
  identifier supplied by the client is never sufficient authorization.
- Do not grant authenticated read on `MarketplaceReport`. The app only creates
  reports; ordinary users never list or display them. Developers review them in
  CloudKit Dashboard.
- CloudKit roles cannot perform field validation. Sale/adoption invariants,
  phone normalization, and privacy-safe snapshot mapping are validated in the
  app. Dashboard permissions remain the hard record-access boundary.

## Record schema

### `MarketplaceListing`

| Field | CloudKit type | Notes |
| --- | --- | --- |
| `sourceDogID` | String | SHA-256 marketplace identifier; never the raw SwiftData UUID |
| `sellerProfile` | Reference | `SellerProfile`, no delete-self action |
| `name` | String | Public snapshot |
| `breed` | String | Public snapshot |
| `dateOfBirth` | Date/Time | Optional public snapshot |
| `sex` | String | Optional: `male`, `female` |
| `weight` | Double | Optional kilograms |
| `backgroundColor` | String | `ColorType.rawValue` |
| `photo` | Asset | Optional processed primary photo |
| `vaccinationNames` | List of String | Summary names only |
| `vaccinationRecordCount` | Int64 | Summary count only |
| `listingType` | String | `sale`, `adoption` |
| `priceAmount` | Int64 | Required and positive for sale; absent for adoption |
| `currencyCode` | String | `IDR` for MVP |
| `region` | String | Approximate city or region; never an exact address |
| `status` | String | `available`, `reserved`, `sold`, `paused`, `removed` |
| `createdAt` | Date/Time | Client-created snapshot timestamp |
| `updatedAt` | Date/Time | Last explicit listing update |

Never add phone numbers, exact addresses, reminders, notes, full vaccination
documents, Gemini source images, or government identification to this record.

### `SellerProfile`

| Field | CloudKit type | Notes |
| --- | --- | --- |
| `displayName` | String | Required |
| `region` | String | Required approximate region |
| `sellerType` | String | `individual`, `breeder`, `rescue` |
| `joinedAt` | Date/Time | Original profile creation date |
| `profileComplete` | Int64/Boolean | All required profile/contact data supplied |
| `rulesAcceptedAt` | Date/Time | Required marketplace-rules acceptance |

The UI calls this state **Complete Seller Profile**, never verified. Display:

> This seller has provided all required contact and profile information.
> Pawsona has not independently verified their identity.

### `SellerContact`

| Field | CloudKit type | Notes |
| --- | --- | --- |
| `sellerProfile` | Reference | Required `SellerProfile` |
| `whatsAppNumber` | String | Normalized E.164 |
| `preferredMethod` | String | `whatsApp`, `phone` |
| `updatedAt` | Date/Time | Last contact update |

Do not add arbitrary URLs. WhatsApp links are generated locally as
`https://wa.me/<digits>?text=<encoded-message>`.

### `MarketplaceReport`

| Field | CloudKit type | Notes |
| --- | --- | --- |
| `listing` | Reference | Listing loaded from CloudKit at report time |
| `reportedSeller` | Reference | Derived from the stored listing |
| `reason` | String | Supported `MarketplaceReportReason.rawValue` |
| `details` | String | Optional, trimmed and limited to 1,000 characters |
| `createdAt` | Date/Time | Submission date |
| `status` | String | Starts as `submitted` |

## Required indexes

CloudKit queries fail at runtime when a used field is not indexed. In the
development environment, add these indexes before testing:

### `MarketplaceListing`

- Queryable: `status`
- Queryable: `listingType`
- Queryable: `breed`
- Queryable: `sex`
- Queryable: `region`
- Queryable: `priceAmount`
- Queryable: `sellerProfile`
- Queryable: `sourceDogID`
- Queryable: system record name / record ID
- Queryable and sortable: `createdAt`
- Sortable: `priceAmount`
- Sortable: `updatedAt` (recommended for moderation/operations)

### Other record types

- `SellerProfile`: system record name / record ID queryable; `region`,
  `sellerType`, and `profileComplete` queryable if Dashboard operations need
  those filters.
- `SellerContact`: system record name / record ID and `sellerProfile`
  queryable. Do not expose the phone field as a search index.
- `MarketplaceReport`: system record name / record ID queryable; `listing`,
  `reportedSeller`, `reason`, and `status` queryable; `createdAt` sortable.

## Development setup

1. Open CloudKit Dashboard for `iCloud.com.nathansudiara.Pawsona`.
2. Select the **Development** environment and public database.
3. Create the four record types and fields exactly as listed above.
4. Configure indexes and security roles.
5. Run the app with a development-signed build.
6. Verify browsing while signed out of iCloud.
7. Sign in to a test iCloud account and create a seller profile, contact,
   listing, and report.
8. Use a second test account to confirm world-readable listing/profile access,
   authenticated-only contact access, and creator-only listing mutation.
9. Confirm reports are not queryable by ordinary users.
10. Inspect saved listing/profile records to verify no private puppy or contact
    fields crossed the intended boundary.

The repository retries retryable CloudKit errors using
`CKErrorRetryAfterKey`, maps network/conflict/missing/authentication errors to
user-facing states, and uses query cursors for pagination.

## Production deployment

Production deployment is a manual release operation and is intentionally not
performed by this change.

1. Review development records, indexes, and roles with the product/security
   owner.
2. Remove test records that should not be promoted operationally.
3. In CloudKit Dashboard, use **Deploy Schema Changes** from Development to
   Production.
4. Review every proposed record type, field, index, and role before confirming.
5. Verify the production security roles after deployment.
6. Test a release-signed build against production with two non-developer iCloud
   accounts.
7. Confirm public browse, authenticated contact, creator-only mutation, report
   create-only behavior, asset upload/download, rate-limit handling, and
   pagination.
8. Publish the marketplace safety/support contact in App Store metadata and
   release operations documentation. The in-app Report flow is the marketplace
   safety contact surface; do not invent an email address in code.

Do not claim real-iCloud, physical-camera, installed-WhatsApp, or production
verification until those steps have actually been performed on devices and in
the intended CloudKit environment.
