(define-trait genetic-data-trait
    (
        ;; Get data details
        (get-data-details (uint) (response {
            owner: principal,
            price: uint,
            access-level: uint,
            metadata-hash: (string-utf8 64)
        } uint))

        ;; Verify access rights
        (verify-access-rights (uint principal) (response bool uint))

        ;; Grant access
        (grant-access (uint principal uint) (response bool uint))
    )
)
