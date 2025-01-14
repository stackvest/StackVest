(define-constant ERR-UNAUTHORIZED u1)
(define-constant ERR-YOU-POOR u2)
(define-fungible-token wrapped-tide)
(define-data-var token-uri (string-utf8 256) u"")
(define-constant contract-creator tx-sender)
(impl-trait 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sip-10-ft-standard.ft-trait)



(define-public (wrap-tide (amount uint) (recipient principal))
    (if
        (is-ok
            (contract-call? .tidetoken transfer (as-contract tx-sender) amount))
        (begin
            (ft-mint? wrapped-tide amount recipient)
        )
        (err ERR-YOU-POOR)))

(define-public (unwrap (amount uint))
    (if 
        (is-ok (ft-burn? wrapped-tide amount tx-sender))
            (let ((unwrapper tx-sender))
                (as-contract (contract-call? .tidetoken transfer (as-contract tx-sender) amount)))
        (err ERR-YOU-POOR)
    ))

;;;;;;;;;;;;;;;;;;;;; SIP 010 ;;;;;;;;;;;;;;;;;;;;;;

(define-public (transfer (amount uint) (from principal) (to principal))
    (begin
        (asserts! (is-eq from tx-sender)
            (err ERR-UNAUTHORIZED))

        (ft-transfer? wrapped-tide amount from to)
    )
)

(define-public (get-name)
    (ok "wrapped-tide"))

(define-public (get-symbol)
    (ok "wtide"))

(define-public (get-decimals)
    (ok u0))

(define-public (get-balance-of (user principal))
    (ok (ft-get-balance wrapped-tide user)))

(define-public (get-total-supply)
    (ok (ft-get-supply wrapped-tide)))

(define-public (set-token-uri (value (string-utf8 256)))
    (if 
        (is-eq tx-sender contract-creator) 
            (ok (var-set token-uri value)) 
        (err ERR-UNAUTHORIZED)))

(define-public (get-token-uri)
    (ok (var-get token-uri)))

;; send-many

(define-public (send-wrappedtide (amount uint) (to principal))
    (let ((transfer-ok (try! (transfer amount tx-sender to))))
    (ok transfer-ok)))

(define-private (send-tide-unwrap (recipient { to: principal, amount: uint }))
    (send-wrappedtide
        (get amount recipient)
        (get to recipient)))

(define-private (check-err  (result (response bool uint))
                            (prior (response bool uint)))
    (match prior ok-value result
                err-value (err err-value)))

(define-public (send-many (recipients (list 200 { to: principal, amount: uint })))
    (fold check-err
        (map send-tide-unwrap recipients)
        (ok true)))