;; title: Modular-Certification-Platform
;; version: 1.0.0

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-credential (err u104))
(define-constant err-credential-expired (err u105))
(define-constant err-not-issuer (err u106))
(define-constant err-degree-locked (err u107))
(define-constant err-invalid-params (err u108))

(define-data-var credential-nonce uint u0)
(define-data-var degree-nonce uint u0)
(define-data-var issuer-nonce uint u0)

(define-map issuers
    principal
    {
        name: (string-ascii 64),
        verified: bool,
        issued-count: uint,
        registered-at: uint
    }
)

(define-map credentials
    uint
    {
        holder: principal,
        issuer: principal,
        credential-type: (string-ascii 32),
        metadata-uri: (string-ascii 256),
        issued-at: uint,
        expires-at: (optional uint),
        revoked: bool,
        skill-tags: (list 10 (string-ascii 32))
    }
)

(define-map holder-credentials
    {holder: principal, credential-id: uint}
    bool
)

(define-map degrees
    uint
    {
        holder: principal,
        degree-name: (string-ascii 64),
        credential-ids: (list 50 uint),
        recognized-by: (list 20 principal),
        created-at: uint,
        locked: bool,
        metadata-uri: (string-ascii 256)
    }
)

(define-map holder-degrees
    {holder: principal, degree-id: uint}
    bool
)

(define-map credential-verifications
    {credential-id: uint, verifier: principal}
    {
        verified: bool,
        verified-at: uint,
        notes: (string-ascii 128)
    }
)

(define-map issuer-reputation
    principal
    {
        total-issued: uint,
        total-revoked: uint,
        reputation-score: uint
    }
)

(define-public (register-issuer (name (string-ascii 64)))
    (let ((issuer-id (+ (var-get issuer-nonce) u1)))
        (asserts! (is-none (map-get? issuers tx-sender)) err-already-exists)
        (map-set issuers tx-sender {
            name: name,
            verified: false,
            issued-count: u0,
            registered-at: stacks-block-height
        })
        (map-set issuer-reputation tx-sender {
            total-issued: u0,
            total-revoked: u0,
            reputation-score: u100
        })
        (var-set issuer-nonce issuer-id)
        (ok issuer-id)
    )
)

(define-public (verify-issuer (issuer principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (map-get? issuers issuer)) err-not-found)
        (map-set issuers issuer 
            (merge (unwrap-panic (map-get? issuers issuer)) {verified: true})
        )
        (ok true)
    )
)

(define-public (issue-credential 
    (holder principal)
    (credential-type (string-ascii 32))
    (metadata-uri (string-ascii 256))
    (expires-at (optional uint))
    (skill-tags (list 10 (string-ascii 32)))
)
    (let (
        (credential-id (+ (var-get credential-nonce) u1))
        (issuer-data (unwrap! (map-get? issuers tx-sender) err-not-issuer))
    )
        (map-set credentials credential-id {
            holder: holder,
            issuer: tx-sender,
            credential-type: credential-type,
            metadata-uri: metadata-uri,
            issued-at: stacks-block-height,
            expires-at: expires-at,
            revoked: false,
            skill-tags: skill-tags
        })
        (map-set holder-credentials {holder: holder, credential-id: credential-id} true)
        (map-set issuers tx-sender 
            (merge issuer-data {issued-count: (+ (get issued-count issuer-data) u1)})
        )
        (update-issuer-stats tx-sender u1 u0)
        (var-set credential-nonce credential-id)
        (ok credential-id)
    )
)

(define-public (revoke-credential (credential-id uint))
    (let (
        (credential (unwrap! (map-get? credentials credential-id) err-not-found))
    )
        (asserts! (is-eq tx-sender (get issuer credential)) err-unauthorized)
        (map-set credentials credential-id
            (merge credential {revoked: true})
        )
        (update-issuer-stats tx-sender u0 u1)
        (ok true)
    )
)

(define-public (create-degree 
    (degree-name (string-ascii 64))
    (credential-ids (list 50 uint))
    (metadata-uri (string-ascii 256))
)
    (let (
        (degree-id (+ (var-get degree-nonce) u1))
    )
        (asserts! (> (len credential-ids) u0) err-invalid-params)
        (asserts! (check-credentials-ownership tx-sender credential-ids) err-unauthorized)
        (map-set degrees degree-id {
            holder: tx-sender,
            degree-name: degree-name,
            credential-ids: credential-ids,
            recognized-by: (list),
            created-at: stacks-block-height,
            locked: false,
            metadata-uri: metadata-uri
        })
        (map-set holder-degrees {holder: tx-sender, degree-id: degree-id} true)
        (var-set degree-nonce degree-id)
        (ok degree-id)
    )
)

(define-public (recognize-degree (degree-id uint))
    (let (
        (degree (unwrap! (map-get? degrees degree-id) err-not-found))
        (current-recognizers (get recognized-by degree))
    )
        (asserts! (is-some (map-get? issuers tx-sender)) err-not-issuer)
        (asserts! (< (len current-recognizers) u20) err-invalid-params)
        (map-set degrees degree-id
            (merge degree {
                recognized-by: (unwrap-panic (as-max-len? 
                    (append current-recognizers tx-sender) 
                    u20
                ))
            })
        )
        (ok true)
    )
)

(define-public (lock-degree (degree-id uint))
    (let (
        (degree (unwrap! (map-get? degrees degree-id) err-not-found))
    )
        (asserts! (is-eq tx-sender (get holder degree)) err-unauthorized)
        (asserts! (not (get locked degree)) err-degree-locked)
        (map-set degrees degree-id
            (merge degree {locked: true})
        )
        (ok true)
    )
)

(define-public (verify-credential 
    (credential-id uint)
    (notes (string-ascii 128))
)
    (let (
        (credential (unwrap! (map-get? credentials credential-id) err-not-found))
    )
        (asserts! (is-some (map-get? issuers tx-sender)) err-not-issuer)
        (map-set credential-verifications 
            {credential-id: credential-id, verifier: tx-sender}
            {
                verified: true,
                verified-at: stacks-block-height,
                notes: notes
            }
        )
        (ok true)
    )
)

(define-read-only (get-credential (credential-id uint))
    (ok (map-get? credentials credential-id))
)

(define-read-only (get-degree (degree-id uint))
    (ok (map-get? degrees degree-id))
)

(define-read-only (get-issuer (issuer principal))
    (ok (map-get? issuers issuer))
)

(define-read-only (get-issuer-reputation (issuer principal))
    (ok (map-get? issuer-reputation issuer))
)

(define-read-only (get-verification 
    (credential-id uint)
    (verifier principal)
)
    (ok (map-get? credential-verifications {credential-id: credential-id, verifier: verifier}))
)

(define-read-only (is-credential-valid (credential-id uint))
    (let (
        (credential (unwrap! (map-get? credentials credential-id) err-not-found))
    )
        (ok (and 
            (not (get revoked credential))
            (match (get expires-at credential)
                expiry (< stacks-block-height expiry)
                true
            )
        ))
    )
)

(define-read-only (get-holder-credential-status 
    (holder principal)
    (credential-id uint)
)
    (ok (default-to false (map-get? holder-credentials {holder: holder, credential-id: credential-id})))
)

(define-read-only (get-holder-degree-status 
    (holder principal)
    (degree-id uint)
)
    (ok (default-to false (map-get? holder-degrees {holder: holder, degree-id: degree-id})))
)

(define-private (check-credentials-ownership 
    (holder principal)
    (credential-ids (list 50 uint))
)
    (fold check-single-credential-ownership credential-ids true)
)

(define-private (check-single-credential-ownership 
    (credential-id uint)
    (prev-result bool)
)
    (match (map-get? credentials credential-id)
        credential (and prev-result (is-eq (get holder credential) tx-sender))
        false
    )
)

(define-private (update-issuer-stats 
    (issuer principal)
    (issued-increment uint)
    (revoked-increment uint)
)
    (match (map-get? issuer-reputation issuer)
        rep (begin
            (map-set issuer-reputation issuer {
                total-issued: (+ (get total-issued rep) issued-increment),
                total-revoked: (+ (get total-revoked rep) revoked-increment),
                reputation-score: (calculate-reputation-score 
                    (+ (get total-issued rep) issued-increment)
                    (+ (get total-revoked rep) revoked-increment)
                )
            })
            true
        )
        false
    )
)

(define-private (calculate-reputation-score 
    (total-issued uint)
    (total-revoked uint)
)
    (if (is-eq total-issued u0)
        u100
        (let ((revoke-rate (/ (* total-revoked u100) total-issued)))
            (if (> revoke-rate u50)
                u0
                (- u100 (* revoke-rate u2))
            )
        )
    )
)
