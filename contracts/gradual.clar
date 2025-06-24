;; CredStack - Decentralized Academic Credentials Platform
;; Smart Contract for issuing, managing, and verifying academic credentials

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-not-authorized-issuer (err u105))
(define-constant err-empty-string (err u106))
(define-constant err-invalid-buffer (err u107))

;; Data Variables
(define-data-var next-credential-id uint u1)
(define-data-var next-institution-id uint u1)

;; Data Maps

;; Authorized institutions that can issue credentials
(define-map authorized-institutions
  uint
  {
    name: (string-ascii 100),
    admin: principal,
    is-active: bool,
    verification-key: (buff 64)
  }
)

;; Institution admins mapping
(define-map institution-admins principal uint)

;; Individual credentials
(define-map credentials
  uint
  {
    student: principal,
    institution-id: uint,
    credential-type: (string-ascii 50), ;; "degree", "certificate", "diploma"
    field-of-study: (string-ascii 100),
    grade: (string-ascii 20),
    issue-date: uint,
    expiry-date: (optional uint),
    metadata-hash: (buff 32), ;; IPFS hash or similar
    is-revoked: bool
  }
)

;; Student's credential IDs
(define-map student-credentials
  principal
  (list 50 uint)
)

;; Privacy settings for credentials
(define-map credential-privacy
  uint
  {
    is-public: bool,
    allowed-viewers: (list 20 principal),
    show-grade: bool,
    show-institution: bool
  }
)

;; Skill attestations from peers
(define-map skill-attestations
  {credential-id: uint, attester: principal}
  {
    skill: (string-ascii 50),
    proficiency-level: uint, ;; 1-5 scale
    attestation-date: uint,
    comments: (string-ascii 200)
  }
)

;; Verification requests from employers/verifiers
(define-map verification-requests
  uint
  {
    verifier: principal,
    student: principal,
    credential-id: uint,
    request-date: uint,
    is-approved: (optional bool),
    response-date: (optional uint)
  }
)

(define-data-var next-verification-id uint u1)

;; Helper functions for input validation
(define-private (is-valid-string (str (string-ascii 200)))
  (> (len str) u0)
)

(define-private (is-valid-buffer (buf (buff 64)))
  (> (len buf) u0)
)

(define-private (is-valid-credential-type (cred-type (string-ascii 50)))
  (or 
    (is-eq cred-type "degree")
    (is-eq cred-type "certificate") 
    (is-eq cred-type "diploma")
    (is-eq cred-type "license")
    (is-eq cred-type "certification")
  )
)

;; Public Functions

;; Register a new institution (only contract owner)
(define-public (register-institution (name (string-ascii 100)) (admin principal) (verification-key (buff 64)))
  (let ((institution-id (var-get next-institution-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? institution-admins admin)) err-already-exists)
    (asserts! (is-valid-string name) err-empty-string)
    (asserts! (is-valid-buffer verification-key) err-invalid-buffer)
    
    (map-set authorized-institutions institution-id
      {
        name: name,
        admin: admin,
        is-active: true,
        verification-key: verification-key
      }
    )
    
    (map-set institution-admins admin institution-id)
    (var-set next-institution-id (+ institution-id u1))
    (ok institution-id)
  )
)

;; Issue a new credential (only authorized institution admins)
(define-public (issue-credential 
  (student principal)
  (credential-type (string-ascii 50))
  (field-of-study (string-ascii 100))
  (grade (string-ascii 20))
  (expiry-date (optional uint))
  (metadata-hash (buff 32))
)
  (let (
    (credential-id (var-get next-credential-id))
    (institution-id-result (map-get? institution-admins tx-sender))
  )
    (asserts! (is-some institution-id-result) err-not-authorized-issuer)
    (asserts! (is-valid-credential-type credential-type) err-invalid-input)
    (asserts! (is-valid-string field-of-study) err-empty-string)
    (asserts! (is-valid-string grade) err-empty-string)
    (asserts! (> (len metadata-hash) u0) err-invalid-buffer)
    
    (let ((institution-id (unwrap-panic institution-id-result)))
      (asserts! (get is-active (unwrap-panic (map-get? authorized-institutions institution-id))) err-unauthorized)
      
      ;; Create the credential
      (map-set credentials credential-id
        {
          student: student,
          institution-id: institution-id,
          credential-type: credential-type,
          field-of-study: field-of-study,
          grade: grade,
          issue-date: block-height,
          expiry-date: expiry-date,
          metadata-hash: metadata-hash,
          is-revoked: false
        }
      )
      
      ;; Set default privacy settings (private by default)
      (map-set credential-privacy credential-id
        {
          is-public: false,
          allowed-viewers: (list),
          show-grade: true,
          show-institution: true
        }
      )
      
      ;; Add to student's credential list
      (let ((current-creds (default-to (list) (map-get? student-credentials student))))
        (map-set student-credentials student (unwrap-panic (as-max-len? (append current-creds credential-id) u50)))
      )
      
      (var-set next-credential-id (+ credential-id u1))
      (ok credential-id)
    )
  )
)

;; Update privacy settings for a credential (only credential owner)
(define-public (update-privacy-settings
  (credential-id uint)
  (is-public bool)
  (allowed-viewers (list 20 principal))
  (show-grade bool)
  (show-institution bool)
)
  (let ((credential (map-get? credentials credential-id)))
    (asserts! (is-some credential) err-not-found)
    (asserts! (is-eq tx-sender (get student (unwrap-panic credential))) err-unauthorized)
    
    (map-set credential-privacy credential-id
      {
        is-public: is-public,
        allowed-viewers: allowed-viewers,
        show-grade: show-grade,
        show-institution: show-institution
      }
    )
    (ok true)
  )
)

;; Add skill attestation (any user can attest)
(define-public (add-skill-attestation
  (credential-id uint)
  (skill (string-ascii 50))
  (proficiency-level uint)
  (comments (string-ascii 200))
)
  (let ((credential (map-get? credentials credential-id)))
    (asserts! (is-some credential) err-not-found)
    (asserts! (and (>= proficiency-level u1) (<= proficiency-level u5)) err-invalid-input)
    (asserts! (not (get is-revoked (unwrap-panic credential))) err-unauthorized)
    (asserts! (is-valid-string skill) err-empty-string)
    (asserts! (is-valid-string comments) err-empty-string)
    
    (map-set skill-attestations {credential-id: credential-id, attester: tx-sender}
      {
        skill: skill,
        proficiency-level: proficiency-level,
        attestation-date: block-height,
        comments: comments
      }
    )
    (ok true)
  )
)

;; Request verification of a credential (employers/verifiers)
(define-public (request-verification (student principal) (credential-id uint))
  (let (
    (credential (map-get? credentials credential-id))
    (verification-id (var-get next-verification-id))
  )
    (asserts! (is-some credential) err-not-found)
    (asserts! (is-eq student (get student (unwrap-panic credential))) err-invalid-input)
    
    (map-set verification-requests verification-id
      {
        verifier: tx-sender,
        student: student,
        credential-id: credential-id,
        request-date: block-height,
        is-approved: none,
        response-date: none
      }
    )
    
    (var-set next-verification-id (+ verification-id u1))
    (ok verification-id)
  )
)

;; Approve/deny verification request (only credential owner)
(define-public (respond-to-verification (verification-id uint) (approve bool))
  (let ((request (map-get? verification-requests verification-id)))
    (asserts! (is-some request) err-not-found)
    (asserts! (is-eq tx-sender (get student (unwrap-panic request))) err-unauthorized)
    (asserts! (is-none (get is-approved (unwrap-panic request))) err-already-exists)
    
    (map-set verification-requests verification-id
      (merge (unwrap-panic request)
        {
          is-approved: (some approve),
          response-date: (some block-height)
        }
      )
    )
    (ok true)
  )
)

;; Revoke a credential (only issuing institution)
(define-public (revoke-credential (credential-id uint))
  (let ((credential (map-get? credentials credential-id)))
    (asserts! (is-some credential) err-not-found)
    
    (let ((institution-id (get institution-id (unwrap-panic credential))))
      (asserts! (is-some (map-get? institution-admins tx-sender)) err-not-authorized-issuer)
      (asserts! (is-eq institution-id (unwrap-panic (map-get? institution-admins tx-sender))) err-unauthorized)
      
      (map-set credentials credential-id
        (merge (unwrap-panic credential) {is-revoked: true})
      )
      (ok true)
    )
  )
)

;; Read-only functions

;; Get credential details (respects privacy settings)
(define-read-only (get-credential (credential-id uint) (viewer principal))
  (let (
    (credential (map-get? credentials credential-id))
    (privacy (map-get? credential-privacy credential-id))
  )
    (asserts! (is-some credential) err-not-found)
    (asserts! (is-some privacy) err-not-found)
    
    (let (
      (cred (unwrap-panic credential))
      (priv (unwrap-panic privacy))
      (is-owner (is-eq viewer (get student cred)))
      (is-authorized (or 
        (get is-public priv)
        is-owner
        (is-some (index-of (get allowed-viewers priv) viewer))
      ))
    )
      (asserts! is-authorized err-unauthorized)
      
      (ok (some {
        student: (get student cred),
        institution-id: (if (or is-owner (get show-institution priv)) (some (get institution-id cred)) none),
        credential-type: (get credential-type cred),
        field-of-study: (get field-of-study cred),
        grade: (if (or is-owner (get show-grade priv)) (some (get grade cred)) none),
        issue-date: (get issue-date cred),
        expiry-date: (get expiry-date cred),
        metadata-hash: (if is-owner (some (get metadata-hash cred)) none),
        is-revoked: (get is-revoked cred)
      }))
    )
  )
)

;; Get student's credentials
(define-read-only (get-student-credentials (student principal))
  (ok (map-get? student-credentials student))
)

;; Get institution details
(define-read-only (get-institution (institution-id uint))
  (ok (map-get? authorized-institutions institution-id))
)

;; Get skill attestation
(define-read-only (get-skill-attestation (credential-id uint) (attester principal))
  (ok (map-get? skill-attestations {credential-id: credential-id, attester: attester}))
)

;; Get verification request
(define-read-only (get-verification-request (verification-id uint))
  (ok (map-get? verification-requests verification-id))
)

;; Verify if credential is valid and not revoked
(define-read-only (verify-credential (credential-id uint))
  (let ((credential (map-get? credentials credential-id)))
    (if (is-some credential)
      (let ((cred (unwrap-panic credential)))
        (ok {
          is-valid: (not (get is-revoked cred)),
          issue-date: (get issue-date cred),
          expiry-date: (get expiry-date cred),
          institution-id: (get institution-id cred)
        })
      )
      err-not-found
    )
  )
)